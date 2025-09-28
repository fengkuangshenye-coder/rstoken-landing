$ErrorActionPreference = "Stop"
$root  = (Get-Location).Path
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$bak   = Join-Path $root ("quickfix-bak-" + $stamp)
New-Item -ItemType Directory -Force -Path $bak | Out-Null

function SaveUtf8NoBom([string]$path,[string]$content){
  $enc = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($path, $content, $enc)
}

# 1) tsconfig.json: 排除备份/临时目录，阻止 TSC 扫描
$tsPath = Join-Path $root "tsconfig.json"
if(Test-Path $tsPath){
  Copy-Item $tsPath (Join-Path $bak "tsconfig.json")
  $ts = Get-Content $tsPath -Raw | ConvertFrom-Json
  if(-not $ts.PSObject.Properties.Name.Contains('exclude') -or $null -eq $ts.exclude){ $ts | Add-Member -NotePropertyName exclude -NotePropertyValue @() }
  $need = @(
    ".next","node_modules",
    "backup-*","backup-*/**/*",
    "patch-backup-*","patch-backup-*/**/*",
    "quickfix-bak-*","quickfix-bak-*/**/*"
  )
  $set = New-Object System.Collections.Generic.HashSet[string]([StringComparer]::OrdinalIgnoreCase)
  foreach($e in $ts.exclude){ if($e){[void]$set.Add($e)} }
  foreach($e in $need){ [void]$set.Add($e) }
  $ts.exclude = @($set)
  SaveUtf8NoBom $tsPath ($ts | ConvertTo-Json -Depth 20)
  Write-Host "[fix] tsconfig.exclude updated"
} else {
  Write-Host "[warn] tsconfig.json not found"
}

# 2) lib/wagmi.ts：用纯 injected 的稳定版本（导出 wagmiConfig & default）
$wagmi = Join-Path $root "lib\wagmi.ts"
if(Test-Path $wagmi){
  Copy-Item $wagmi (Join-Path $bak "wagmi.ts")
  $wagmiNew = @"
import { createConfig, http } from "wagmi";
import { injected } from "wagmi/connectors";
import { bsc, bscTestnet } from "viem/chains";

export const wagmiConfig = createConfig({
  chains: [bsc, bscTestnet],
  connectors: [injected()],
  transports: {
    [bsc.id]: http("https://bsc-dataseed.binance.org"),
    [bscTestnet.id]: http("https://data-seed-prebsc-1-s1.binance.org:8545")
  },
  multiInjectedProviderDiscovery: true,
  ssr: true
});

export default wagmiConfig;
"
  SaveUtf8NoBom $wagmi $wagmiNew
  Write-Host "[fix] lib/wagmi.ts replaced (WalletConnect/targets removed, exports ready)"
} else {
  Write-Host "[skip] lib/wagmi.ts not found"
}

# 3) lib/erc20.ts：强制迁移到 wagmi/actions（无条件覆盖为最小可用版）
$erc = Join-Path $root "lib\erc20.ts"
if(Test-Path $erc){
  Copy-Item $erc (Join-Path $bak "erc20.ts")
  $ercNew = @"
import type { Address } from "viem";
import { readContract, simulateContract, writeContract, waitForTransactionReceipt } from "wagmi/actions";
import { wagmiConfig as config } from "./wagmi";

const ERC20_ABI = [
  { "name":"balanceOf","type":"function","stateMutability":"view","inputs":[{"name":"account","type":"address"}],"outputs":[{"name":"","type":"uint256"}] },
  { "name":"allowance","type":"function","stateMutability":"view","inputs":[{"name":"owner","type":"address"},{"name":"spender","type":"address"}],"outputs":[{"name":"","type":"uint256"}] },
  { "name":"approve","type":"function","stateMutability":"nonpayable","inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"","type":"bool"}] }
] as const;

export async function erc20BalanceOf(token: Address, owner: Address) {
  return readContract(config, { address: token, abi: ERC20_ABI, functionName: "balanceOf", args: [owner] });
}
export async function erc20Allowance(token: Address, owner: Address, spender: Address) {
  return readContract(config, { address: token, abi: ERC20_ABI, functionName: "allowance", args: [owner, spender] });
}
export async function erc20Approve(token: Address, spender: Address, amount: bigint) {
  const { request } = await simulateContract(config, { address: token, abi: ERC20_ABI, functionName: "approve", args: [spender, amount] });
  const hash = await writeContract(config, request);
  return waitForTransactionReceipt(config, { hash });
}
"
  SaveUtf8NoBom $erc $ercNew
  Write-Host "[fix] lib/erc20.ts migrated to wagmi/actions"
} else {
  Write-Host "[skip] lib/erc20.ts not found"
}

# 4) 运行 tsc
Write-Host "`nRunning TypeScript check..."
& pnpm exec tsc -p tsconfig.json --noEmit
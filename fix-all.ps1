$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$root    = (Get-Location).Path
$stamp   = Get-Date -Format yyyyMMdd-HHmmss
$bakRoot = "D:\RStoken_backups\$stamp"
New-Item -ItemType Directory -Force -Path $bakRoot | Out-Null

function Write-FileUtf8NoBom([string]$Path,[string[]]$Lines){
  $enc = New-Object System.Text.UTF8Encoding($false)
  $text = $Lines -join "`r`n"
  [IO.File]::WriteAllText($Path,$text,$enc)
}

Write-Host "== Step 1: 更新 tsconfig.json 的 exclude =="
$tsPath = Join-Path $root 'tsconfig.json'
if (Test-Path $tsPath) {
  $tsJson = Get-Content $tsPath -Raw | ConvertFrom-Json
  if (-not $tsJson.PSObject.Properties.Name.Contains('exclude') -or $null -eq $tsJson.exclude) {
    $tsJson | Add-Member -NotePropertyName exclude -NotePropertyValue @()
  }
  $need = @(
    ".next","node_modules",
    "backup-*","backup-*/**/*",
    "patch-backup-*","patch-backup-*/**/*",
    "quickfix-bak-*","quickfix-bak-*/**/*",
    "fix-bak-*","fix-bak-*/**/*"
  )
  $set = New-Object System.Collections.Generic.HashSet[string]([StringComparer]::OrdinalIgnoreCase)
  foreach($e in $tsJson.exclude){ if($e){ [void]$set.Add($e) } }
  foreach($e in $need){ [void]$set.Add($e) }
  $tsJson.exclude = @($set)
  $enc = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($tsPath, ($tsJson | ConvertTo-Json -Depth 50), $enc)
  Write-Host "   [ok] tsconfig.exclude 已更新"
} else {
  Write-Host "   [warn] 找不到 tsconfig.json"
}

Write-Host "== Step 2: 移动备份目录到 $bakRoot（避免被 tsc 扫描） =="
$rx = '^(backup-|patch-backup-|quickfix-bak-|fix-bak-)'
$dirs = Get-ChildItem $root -Directory | Where-Object { $_.Name -match $rx }
if ($dirs) {
  foreach($d in $dirs){ Move-Item $d.FullName (Join-Path $bakRoot $d.Name) -Force }
  Write-Host ("   [ok] 已移动 {0} 个目录" -f $dirs.Count)
} else { Write-Host "   [ok] 无需移动" }

Write-Host "== Step 3: 写入代币图标 public/tokens =="
$tokensDir = Join-Path $root "public\tokens"
New-Item -ItemType Directory -Force -Path $tokensDir | Out-Null
$usdtSvg = @(
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">',
  '<defs><linearGradient id="g" x1="0" x2="1" y1="0" y2="1">',
  '<stop offset="0" stop-color="#26A17B"/><stop offset="1" stop-color="#239B73"/>',
  '</linearGradient></defs>',
  '<circle cx="128" cy="128" r="128" fill="url(#g)"/>',
  '<path fill="#fff" d="M117 68h22v24c45 2 79 11 79 22s-34 20-79 22v54h-22v-54c-45-2-79-11-79-22s34-20 79-22V68zm0 44v20c-30-2-52-7-52-10s22-8 52-10zm22 20v-20c30 2 52 7 52 10s-22 8-52 10z"/>',
  '</svg>'
)
$bnbSvg = @(
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">',
  '<circle cx="128" cy="128" r="128" fill="#F3BA2F"/>',
  '<path d="M95 79l33-33 33 33-33 33-33-33zm-16 16l33 33-33 33-33-33 33-33zm98 0l33 33-33 33-33-33 33-33zM95 177l33 33 33-33-33-33-33 33z" fill="#000" fill-opacity=".85"/>',
  '</svg>'
)
Write-FileUtf8NoBom (Join-Path $tokensDir 'usdt.svg') $usdtSvg
Write-FileUtf8NoBom (Join-Path $tokensDir 'bnb.svg')  $bnbSvg
Write-Host "   [ok] 已写入 usdt.svg / bnb.svg"

Write-Host "== Step 4: 修复 lib/wagmi.ts（去 WalletConnect/bitgetWallet） =="
$wagmiPath = Join-Path $root 'lib\wagmi.ts'
if (Test-Path $wagmiPath) { Copy-Item $wagmiPath (Join-Path $bakRoot 'wagmi.ts') }
$wagmiLines = @(
  'import { createConfig, http } from "wagmi";',
  'import { injected } from "wagmi/connectors";',
  'import { bsc, bscTestnet } from "viem/chains";',
  '',
  'export const wagmiConfig = createConfig({',
  '  chains: [bsc, bscTestnet],',
  '  multiInjectedProviderDiscovery: true,',
  '  connectors: [',
  '    injected({ target: "metaMask" }),',
  '    injected({ target: "okxWallet" }),',
  '    injected(),',
  '  ],',
  '  transports: {',
  '    [bsc.id]: http("https://bsc-dataseed.binance.org"),',
  '    [bscTestnet.id]: http("https://data-seed-prebsc-1-s1.binance.org:8545"),',
  '  },',
  '  ssr: true,',
  '});',
  '',
  'export default wagmiConfig;'
)
Write-FileUtf8NoBom $wagmiPath $wagmiLines
Write-Host "   [ok] 覆盖 lib/wagmi.ts"

Write-Host "== Step 5: 修复 lib/erc20.ts（改用 wagmi/actions） =="
$ercPath = Join-Path $root 'lib\erc20.ts'
if (Test-Path $ercPath) { Copy-Item $ercPath (Join-Path $bakRoot 'erc20.ts') }
$ercLines = @(
  'import type { Address } from "viem";',
  'import { readContract, simulateContract, writeContract, waitForTransactionReceipt } from "wagmi/actions";',
  'import { wagmiConfig as config } from "./wagmi";',
  '',
  'const ERC20_ABI = [',
  '  { "name":"balanceOf","type":"function","stateMutability":"view","inputs":[{"name":"account","type":"address"}],"outputs":[{"name":"","type":"uint256"}] },',
  '  { "name":"allowance","type":"function","stateMutability":"view","inputs":[{"name":"owner","type":"address"},{"name":"spender","type":"address"}],"outputs":[{"name":"","type":"uint256"}] },',
  '  { "name":"approve","type":"function","stateMutability":"nonpayable","inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"","type":"bool"}] },',
  '] as const;',
  '',
  'export async function erc20BalanceOf(token: Address, owner: Address) {',
  '  return readContract(config, { address: token, abi: ERC20_ABI, functionName: "balanceOf", args: [owner] });',
  '}',
  'export async function erc20Allowance(token: Address, owner: Address, spender: Address) {',
  '  return readContract(config, { address: token, abi: ERC20_ABI, functionName: "allowance", args: [owner, spender] });',
  '}',
  'export async function erc20Approve(token: Address, spender: Address, amount: bigint) {',
  '  const { request } = await simulateContract(config, { address: token, abi: ERC20_ABI, functionName: "approve", args: [spender, amount] });',
  '  const hash = await writeContract(config, request);',
  '  return waitForTransactionReceipt(config, { hash });',
  '}'
)
Write-FileUtf8NoBom $ercPath $ercLines
Write-Host "   [ok] 覆盖 lib/erc20.ts"

Write-Host "== Step 6: 修复 BottomTabs.tsx typedRoutes =="
$btmPath = Join-Path $root 'components\layout\BottomTabs.tsx'
if (Test-Path $btmPath) {
  $btm = Get-Content $btmPath -Raw
  if ($btm -notmatch 'import\s+type\s*\{\s*Route\s*\}\s*from\s*"next"') {
    if ($btm -match '^\s*"use client";?\s*') {
      $btm = $btm -replace '(^\s*"use client";?\s*)', '$1' + "import type { Route } from `"next`";`r`n"
    } else {
      $btm = "import type { Route } from `"next`";`r`n" + $btm
    }
  }
  $btm = $btm -replace 'router\.push\(\s*href\s*\)','router.push(href as Route)'
  Write-FileUtf8NoBom $btmPath ($btm -split "`r`n")
  Write-Host "   [ok] 更新 BottomTabs.tsx"
} else { Write-Host "   [skip] 未发现 BottomTabs.tsx" }

Write-Host "== Step 7: 修复 app/providers.tsx 对 wagmiConfig 的导入 =="
$provPath = Join-Path $root 'app\providers.tsx'
if (Test-Path $provPath) {
  $p = Get-Content $provPath -Raw
  $p = $p -replace 'import\s*\{\s*wagmiConfig\s*\}\s*from\s*"@\/lib\/wagmi";','import wagmiConfig from "@/lib/wagmi";'
  $p = $p -replace "import\s*\{\s*wagmiConfig\s*\}\s*from\s*'@\/lib\/wagmi';",'import wagmiConfig from "@/lib/wagmi";'
  Write-FileUtf8NoBom $provPath ($p -split "`r`n")
  Write-Host "   [ok] providers.tsx 已规范导入"
} else { Write-Host "   [skip] 未发现 app/providers.tsx" }

Write-Host "== Step 8: 若 SwapPanel 用到 tokenIconSrc 则注入实现 =="
$swapPath = Join-Path $root 'features\swap\SwapPanel.tsx'
if (Test-Path $swapPath) {
  $s = Get-Content $swapPath -Raw
  $needInject = ($s -match 'tokenIconSrc\(') -and ($s -notmatch 'tokenIconSrc\s*=\s*\(') -and ($s -notmatch 'function\s+tokenIconSrc')
  if ($needInject) {
    $inject = 'const TOKEN_ICONS: Record<string,string> = { BNB: "/tokens/bnb.svg", USDT: "/tokens/usdt.svg" };' + "`r`n" +
              'const tokenIconSrc = (sym: string) => TOKEN_ICONS[sym] ?? "/tokens/usdt.svg";' + "`r`n"
    if ($s -match '^\s*"use client";?\s*') {
      $s = $s -replace '(^\s*"use client";?\s*)', '$1' + $inject
    } else {
      $s = $inject + $s
    }
    Write-FileUtf8NoBom $swapPath ($s -split "`r`n")
    Write-Host "   [ok] 已注入 tokenIconSrc()"
  } else {
    Write-Host "   [ok] 无需注入（未使用或已存在）"
  }
} else { Write-Host "   [skip] 未发现 features/swap/SwapPanel.tsx" }

Write-Host "== Step 9: 清理缓存并运行 TypeScript 检查 =="
Get-ChildItem $root -Recurse -Filter "*.tsbuildinfo" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force (Join-Path $root ".next\cache") -ErrorAction SilentlyContinue

& pnpm exec tsc -p tsconfig.json --noEmit
if ($LASTEXITCODE -eq 0) {
  Write-Host "[OK] TypeScript 通过"
} else {
  Write-Host "[FAIL] tsc 退出码 $LASTEXITCODE（请把上面的错误贴出来）"
}
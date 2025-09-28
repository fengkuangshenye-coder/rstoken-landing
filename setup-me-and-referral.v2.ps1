param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot
)

function J([string]$p1,[string]$p2){ return (Join-Path -Path $p1 -ChildPath $p2) }
function Ensure-Dir($path){ if(-not (Test-Path $path)){ New-Item -ItemType Directory -Force -Path $path | Out-Null } }

function Ensure-LineInFile([string]$file,[string]$line){
  if(-not (Test-Path $file)){ Set-Content -Path $file -Value $line -Encoding UTF8; return }
  $content = Get-Content -Path $file -Raw
  if($content -notmatch [regex]::Escape($line)){
    Add-Content -Path $file -Value $line
  }
}

# --- 1) 准备目录 ---
$dirLib        = J $ProjectRoot 'src\lib'
$dirReferral   = J $ProjectRoot 'src\features\referral'
$dirPages      = J $ProjectRoot 'src\pages'
$dirAppMe      = J $ProjectRoot 'src\app\me'

$allDirs = @($dirLib,$dirReferral,$dirPages,$dirAppMe)
$allDirs | ForEach-Object { Ensure-Dir $_ }

# --- 2) 写入 src/lib/tokens.ts ---
$tokensTs = @'
export const CHAINS = {
  BSC_MAINNET: 56,
  BSC_TESTNET: 97,
} as const;

export const TOKENS: Record<number, {
  NATIVE: { symbol: string, decimals: number },
  USDT?: { address: `0x${string}`, decimals: number },
  RST?: { address: `0x${string}`, decimals: number },
}> = {
  [CHAINS.BSC_MAINNET]: {
    NATIVE: { symbol: "BNB", decimals: 18 },
    // BSC 主网 USDT
    USDT: { address: "0x55d398326f99059fF775485246999027B3197955", decimals: 18 },
    // 你的 RST 主网地址（部署后填到 .env 再注入）
    RST: { address: (process.env.NEXT_PUBLIC_RSTOKEN_ADDRESS_MAINNET as `0x${string}`) || undefined as any, decimals: 18 },
  },
  [CHAINS.BSC_TESTNET]: {
    NATIVE: { symbol: "tBNB", decimals: 18 },
    // 测试网 USDT（请替换为你的测试网合约地址）
    USDT: { address: "0x0000000000000000000000000000000000000000", decimals: 18 }, // TODO
    RST: { address: (process.env.NEXT_PUBLIC_RSTOKEN_ADDRESS_TESTNET as `0x${string}`) || undefined as any, decimals: 18 },
  },
};
'@
Set-Content -Path (J $dirLib 'tokens.ts') -Value $tokensTs -Encoding UTF8

# --- 3) 写入 src/features/referral/referral.ts ---
$referralTs = @'
export type Address = `0x${string}`;
const LS_KEYS = {
  ME: "ref_me_address",
  REF_OF: "ref_referrer_of",
  CHILDREN: "ref_children_of",
  REWARDS: "ref_rewards_usdt",
  STATS: "ref_stats",
} as const;

export const REF_SPLIT = { L1: 0.15, L2: 0.10, L3: 0.05 } as const;
export const TOTAL_RATE = REF_SPLIT.L1 + REF_SPLIT.L2 + REF_SPLIT.L3; // 0.30

const parse = <T,>(k: string, def: T): T => {
  if (typeof window === "undefined") return def;
  try { return (JSON.parse(localStorage.getItem(k) || "") as T) ?? def; } catch { return def; }
};
const save = (k: string, v: any) => { if (typeof window !== "undefined") localStorage.setItem(k, JSON.stringify(v)); };

const norm = (a?: string | null) => (a || "").toLowerCase() as Address;
const isAddr = (a?: string) => /^0x[a-fA-F0-9]{40}$/.test(a || "");

export function captureReferrerFromURL(my?: Address) {
  if (typeof window === "undefined") return;
  const url = new URL(window.location.href);
  const ref = norm(url.searchParams.get("ref"));
  if (!isAddr(ref)) return;
  if (my && norm(my) === ref) return;

  const refOf = parse<Record<Address, Address>>(LS_KEYS.REF_OF, {} as any);
  const me = norm(my || parse<Address>(LS_KEYS.ME, "" as any));
  if (!me) return;

  if (!refOf[me]) {
    refOf[me] = ref;
    save(LS_KEYS.REF_OF, refOf);
    const children = parse<Record<Address, Address[]>>(LS_KEYS.CHILDREN, {} as any);
    children[ref] = Array.from(new Set([...(children[ref] || []), me]));
    save(LS_KEYS.CHILDREN, children);
  }
}

export function setMeAddress(addr?: Address) {
  if (!addr) return;
  save(LS_KEYS.ME, norm(addr));
}

export function getMyInviteLink(addr?: Address) {
  if (typeof window === "undefined") return "";
  const base = `${location.origin}${location.pathname}`;
  if (!addr) return "";
  return `${base}?ref=${addr}`;
}

export function getUplines(of: Address): { l1?: Address; l2?: Address; l3?: Address } {
  const refOf = parse<Record<Address, Address>>(LS_KEYS.REF_OF, {} as any);
  const l1 = refOf[of];
  const l2 = l1 ? refOf[l1] : undefined;
  const l3 = l2 ? refOf[l2] : undefined;
  return { l1, l2, l3 };
}

export function recordContributionUSDT(buyer: Address, amountUSDT: number) {
  const { l1, l2, l3 } = getUplines(buyer);
  const rewards = parse<Record<Address, number>>(LS_KEYS.REWARDS, {} as any);
  const stats = parse<Record<Address, { l1: number; l2: number; l3: number }>>(LS_KEYS.STATS, {} as any);

  const add = (who?: Address, part?: "l1" | "l2" | "l3", rate?: number) => {
    if (!who || !rate) return;
    rewards[who] = (rewards[who] || 0) + amountUSDT * rate;
    stats[who] = stats[who] || { l1: 0, l2: 0, l3: 0 };
    if (part) stats[who][part] += amountUSDT;
  };

  add(l1, "l1", REF_SPLIT.L1);
  add(l2, "l2", REF_SPLIT.L2);
  add(l3, "l3", REF_SPLIT.L3);

  save(LS_KEYS.REWARDS, rewards);
  save(LS_KEYS.STATS, stats);
}

export function getMyRewards(addr?: Address) {
  const a = norm(addr || parse<Address>(LS_KEYS.ME, "" as any));
  const rewards = parse<Record<Address, number>>(LS_KEYS.REWARDS, {} as any);
  const stats = parse<Record<Address, { l1: number; l2: number; l3: number }>>(LS_KEYS.STATS, {} as any);
  return {
    pendingUSDT: Number((rewards[a] || 0).toFixed(6)),
    stats: stats[a] || { l1: 0, l2: 0, l3: 0 },
  };
}

export function withdrawMyRewards(addr?: Address) {
  const a = norm(addr || parse<Address>(LS_KEYS.ME, "" as any));
  const rewards = parse<Record<Address, number>>(LS_KEYS.REWARDS, {} as any);
  if (rewards[a]) {
    rewards[a] = 0;
    save(LS_KEYS.REWARDS, rewards);
  }
}
'@
Set-Content -Path (J $dirReferral 'referral.ts') -Value $referralTs -Encoding UTF8

# --- 4) 写入 src/features/referral/MePage.tsx ---
$mePageTsx = @'
import * as React from "react";
import { useAccount, useBalance, useChainId } from "wagmi";
import type { Address } from "./referral";
import { TOKENS } from "../../lib/tokens";
import {
  captureReferrerFromURL, getMyInviteLink, setMeAddress,
  getMyRewards, withdrawMyRewards, recordContributionUSDT, TOTAL_RATE
} from "./referral";

function useTokenBalances(address?: Address) {
  const chainId = useChainId();
  const cfg = TOKENS[chainId] || TOKENS[56];

  const bnb = useBalance({ address, chainId, query: { enabled: !!address } });
  const usdt = useBalance({
    address, chainId,
    token: cfg.USDT?.address as Address,
    query: { enabled: !!address && !!cfg.USDT?.address }
  });
  const rst = useBalance({
    address, chainId,
    token: cfg.RST?.address as Address,
    query: { enabled: !!address && !!cfg.RST?.address }
  });

  return {
    nativeSymbol: cfg.NATIVE.symbol,
    bnb, usdt, rst,
  };
}

export default function MePage() {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const [copied, setCopied] = React.useState(false);

  React.useEffect(() => {
    if (!isConnected || !address) return;
    setMeAddress(address);
    captureReferrerFromURL(address);
  }, [isConnected, address]);

  const { nativeSymbol, bnb, usdt, rst } = useTokenBalances(address as Address);
  const inviteLink = isConnected && address ? getMyInviteLink(address) : "";

  const rewards = getMyRewards(address as Address);

  const simulate = React.useCallback(() => {
    if (isConnected && address) {
      recordContributionUSDT(address as Address, 100);
      alert("已模拟：本地址买入 100 USDT，已给上级结算 30% 分润（15/10/5）");
    }
  }, [isConnected, address]);

  const withdraw = React.useCallback(() => {
    if (isConnected && address) {
      withdrawMyRewards(address as Address);
      alert("演示：已把待领取清零（真实环境应在合约里 claim USDT）");
    }
  }, [isConnected, address]);

  return (
    <div className="min-h-screen px-4 py-6 text-white">
      <header className="mb-4">
        <h1 className="text-xl font-semibold">我的</h1>
        <p className="opacity-70 text-sm">网络：{chainId} ｜ 分润总比例：{Math.round(TOTAL_RATE*100)}%</p>
      </header>

      <section className="space-y-3">
        <CardRow label={nativeSymbol} value={bnb.data?.formatted ?? "0"} />
        <CardRow label="USDT" value={usdt.data?.formatted ?? "0"} />
        <CardRow label="RST" value={rst.data?.formatted ?? "0"} />
      </section>

      <section className="mt-8 space-y-4">
        <h2 className="text-lg font-medium">邀请与分润</h2>

        <div className="bg-zinc-900/70 rounded-2xl p-4">
          <div className="text-sm opacity-80 mb-2">
            规则：总 30% USDT（一级 15%、二级 10%、三级 5%）
          </div>
          <div className="flex items-center gap-2">
            <input
              className="flex-1 bg-black/40 rounded-lg px-3 py-2 text-sm outline-none"
              readOnly
              value={inviteLink || "请先连接钱包生成邀请链接"}
            />
            <button
              className="px-3 py-2 text-sm bg-indigo-600 rounded-lg active:scale-95 disabled:opacity-50"
              disabled={!inviteLink}
              onClick={async () => {
                await navigator.clipboard.writeText(inviteLink);
                setCopied(true); setTimeout(()=>setCopied(false), 1500);
              }}
            >复制</button>
          </div>
          {copied && <div className="text-xs mt-2 text-emerald-400">已复制到剪贴板</div>}
        </div>

        <div className="bg-zinc-900/70 rounded-2xl p-4 space-y-2">
          <div className="text-sm">待领取（USDT）：<b>{rewards.pendingUSDT}</b></div>
          <div className="text-xs opacity-70">
            累计业绩：一级 {rewards.stats.l1} USDT ｜ 二级 {rewards.stats.l2} ｜ 三级 {rewards.stats.l3}
          </div>
          <div className="flex gap-2 mt-2">
            <button className="px-3 py-2 text-sm bg-white/10 rounded-lg active:scale-95"
              onClick={simulate}
            >模拟：我买入 100 USDT</button>
            <button className="px-3 py-2 text-sm bg-emerald-600 rounded-lg active:scale-95"
              onClick={withdraw}
            >领取（演示清零）</button>
          </div>
          <div className="text-xs opacity-60 mt-2">
            * 本页分润为前端演示；上线请改为合约/后端账本与领取。
          </div>
        </div>
      </section>
    </div>
  );
}

function CardRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="bg-zinc-900/70 rounded-2xl px-4 py-4 flex items-center justify-between">
      <div className="flex items-center gap-3">
        <span className="inline-block size-3 rounded-full bg-gradient-to-br from-fuchsia-400 to-indigo-400" />
        <span className="font-medium">{label}</span>
      </div>
      <span className="opacity-80">{value}</span>
    </div>
  );
}
'@
Set-Content -Path (J $dirReferral 'MePage.tsx') -Value $mePageTsx -Encoding UTF8

# --- 5) 写入路由入口（Pages 与 App 皆可；你保留其一即可） ---
Set-Content -Path (J $dirPages 'me.tsx') -Value "import MePage from '../features/referral/MePage'; export default MePage;" -Encoding UTF8
Set-Content -Path (J $dirAppMe 'page.tsx') -Value "'use client'; import MePage from '../../features/referral/MePage'; export default function Page(){ return <MePage/> }" -Encoding UTF8

# --- 6) tsconfig 路径别名（可选） ---
$tsconfigPath = J $ProjectRoot 'tsconfig.json'
if (Test-Path $tsconfigPath) {
  try{
    $json = Get-Content $tsconfigPath -Raw | ConvertFrom-Json
    if (-not $json.compilerOptions){ $json | Add-Member -NotePropertyName compilerOptions -NotePropertyValue (@{}) }
    if (-not $json.compilerOptions.baseUrl){ $json.compilerOptions.baseUrl = "src" }
    if (-not $json.compilerOptions.paths){ $json.compilerOptions | Add-Member -NotePropertyName paths -NotePropertyValue (@{}) }
    if (-not $json.compilerOptions.paths."@/*"){ $json.compilerOptions.paths."@/*" = @("*") }
    ($json | ConvertTo-Json -Depth 100) | Set-Content -Path $tsconfigPath -Encoding UTF8
  }catch{
    Write-Host "⚠️ tsconfig.json 含注释/非标准 JSON，已跳过自动修改（无需担心，当前代码使用相对路径也能编译）。"
  }
}

# --- 7) .env.local 注入占位 ---
$envPath = J $ProjectRoot '.env.local'
Ensure-LineInFile -file $envPath -line "NEXT_PUBLIC_RSTOKEN_ADDRESS_MAINNET=0xYourMainnetRSTAddressHere"
Ensure-LineInFile -file $envPath -line "NEXT_PUBLIC_RSTOKEN_ADDRESS_TESTNET=0xYourTestnetRSTAddressHere"

# --- 8) 结果输出 ---
"`n✅ 写入完成："
$allFiles = @(
  J $dirLib 'tokens.ts',
  J $dirReferral 'referral.ts',
  J $dirReferral 'MePage.tsx',
  J $dirPages 'me.tsx',
  J $dirAppMe 'page.tsx',
  $envPath
)
$allFiles | ForEach-Object { " - $_" } | Write-Host
"`n👉 接下来：填好 .env.local 里的 RST 地址，然后运行：pnpm dev  或  npm run dev`n" | Write-Host

$script = @'
param([Parameter(Mandatory=$true)][string]$ProjectRoot)

function J([string]$a,[string]$b){ Join-Path -Path $a -ChildPath $b }
function Ensure-Dir([string]$p){ if(-not(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8([string]$path,[string]$content){ Set-Content -Path $path -Value $content -Encoding UTF8 }
function Ensure-Line([string]$file,[string]$line){
  if(-not(Test-Path $file)){ Set-Content -Path $file -Value $line -Encoding UTF8; return }
  $raw = Get-Content -Path $file -Raw
  if($raw -notmatch [regex]::Escape($line)){ Add-Content -Path $file -Value $line }
}

# --- 0) 目录准备 ---
$dirLib   = J $ProjectRoot 'src\lib'
$dirFeat  = J $ProjectRoot 'src\features\referral'
$dirAppMe = J $ProjectRoot 'app\me'
Ensure-Dir $dirLib; Ensure-Dir $dirFeat; Ensure-Dir $dirAppMe

# --- 1) tokens.ts ---
$tokensTs = @'
export const CHAINS = { BSC_MAINNET: 56, BSC_TESTNET: 97 } as const;
export const TOKENS: Record<number, {
  NATIVE: { symbol: string, decimals: number },
  USDT?: { address: `0x${string}`, decimals: number },
  RST?: { address: `0x${string}`, decimals: number },
}> = {
  [56]: {
    NATIVE: { symbol: "BNB", decimals: 18 },
    USDT: { address: "0x55d398326f99059fF775485246999027B3197955", decimals: 18 },
    RST: { address: (process.env.NEXT_PUBLIC_RSTOKEN_ADDRESS_MAINNET as `0x${string}`) || undefined as any, decimals: 18 },
  },
  [97]: {
    NATIVE: { symbol: "tBNB", decimals: 18 },
    USDT: { address: "0x0000000000000000000000000000000000000000", decimals: 18 }, // TODO: 换成你的测试网 USDT
    RST: { address: (process.env.NEXT_PUBLIC_RSTOKEN_ADDRESS_TESTNET as `0x${string}`) || undefined as any, decimals: 18 },
  },
};
'@
WriteUtf8 (J $dirLib 'tokens.ts') $tokensTs

# --- 2) referral.ts ---
$referralTs = @'
export type Address = `0x${string}`;
const LS_KEYS = { ME:"ref_me_address", REF_OF:"ref_referrer_of", CHILDREN:"ref_children_of", REWARDS:"ref_rewards_usdt", STATS:"ref_stats" } as const;
export const REF_SPLIT = { L1:0.15, L2:0.10, L3:0.05 } as const;
export const TOTAL_RATE = REF_SPLIT.L1 + REF_SPLIT.L2 + REF_SPLIT.L3; // 0.30

const parse = <T,>(k:string,def:T):T => { if(typeof window==="undefined") return def; try{ return (JSON.parse(localStorage.getItem(k)||"") as T) ?? def }catch{ return def } };
const save  = (k:string,v:any)=>{ if(typeof window!=="undefined") localStorage.setItem(k,JSON.stringify(v)) };
const norm  = (a?:string|null)=>(a||"").toLowerCase() as Address;
const isAddr= (a?:string)=>/^0x[a-fA-F0-9]{40}$/.test(a||"");

export function captureReferrerFromURL(my?:Address){
  if(typeof window==="undefined") return;
  const url=new URL(window.location.href);
  const ref=norm(url.searchParams.get("ref"));
  if(!isAddr(ref)) return;
  if(my && norm(my)===ref) return;
  const refOf=parse<Record<Address,Address>>(LS_KEYS.REF_OF,{} as any);
  const me=norm(my || parse<Address>(LS_KEYS.ME,"" as any));
  if(!me) return;
  if(!refOf[me]){
    refOf[me]=ref; save(LS_KEYS.REF_OF,refOf);
    const children=parse<Record<Address,Address[]>>(LS_KEYS.CHILDREN,{} as any);
    children[ref]=Array.from(new Set([...(children[ref]||[]),me])); save(LS_KEYS.CHILDREN,children);
  }
}

export function setMeAddress(addr?:Address){ if(!addr) return; save(LS_KEYS.ME,norm(addr)); }

export function getMyInviteLink(addr?:Address){
  if(typeof window==="undefined") return "";
  const base=`${location.origin}${location.pathname}`;
  if(!addr) return "";
  return `${base}?ref=${addr}`;
}

export function getUplines(of:Address){
  const refOf=parse<Record<Address,Address>>(LS_KEYS.REF_OF,{} as any);
  const l1=refOf[of]; const l2=l1?refOf[l1]:undefined; const l3=l2?refOf[l2]:undefined;
  return { l1,l2,l3 };
}

export function recordContributionUSDT(buyer:Address,amountUSDT:number){
  const {l1,l2,l3}=getUplines(buyer);
  const rewards=parse<Record<Address,number>>(LS_KEYS.REWARDS,{} as any);
  const stats=parse<Record<Address,{l1:number;l2:number;l3:number;}>>(LS_KEYS.STATS,{} as any);
  const add=(who?:Address,part?:"l1"|"l2"|"l3",rate?:number)=>{
    if(!who||!rate) return;
    rewards[who]=(rewards[who]||0)+amountUSDT*rate;
    stats[who]=stats[who]||{l1:0,l2:0,l3:0};
    if(part) stats[who][part]+=amountUSDT;
  };
  add(l1,"l1",REF_SPLIT.L1); add(l2,"l2",REF_SPLIT.L2); add(l3,"l3",REF_SPLIT.L3);
  save(LS_KEYS.REWARDS,rewards); save(LS_KEYS.STATS,stats);
}

export function getMyRewards(addr?:Address){
  const a=norm(addr || parse<Address>(LS_KEYS.ME,"" as any));
  const rewards=parse<Record<Address,number>>(LS_KEYS.REWARDS,{} as any);
  const stats=parse<Record<Address,{l1:number;l2:number;l3:number;}>>(LS_KEYS.STATS,{} as any);
  return { pendingUSDT:Number((rewards[a]||0).toFixed(6)), stats:stats[a]||{l1:0,l2:0,l3:0} };
}

export function withdrawMyRewards(addr?:Address){
  const a=norm(addr || parse<Address>(LS_KEYS.ME,"" as any));
  const rewards=parse<Record<Address,number>>(LS_KEYS.REWARDS,{} as any);
  if(rewards[a]){ rewards[a]=0; save(LS_KEYS.REWARDS,rewards); }
}
'@
WriteUtf8 (J $dirFeat 'referral.ts') $referralTs

# --- 3) MePage.tsx（兼容旧版 Tailwind 样式） ---
$mePageTsx = @'
"use client";

import * as React from "react";
import { useAccount, useBalance, useChainId } from "wagmi";
import type { Address } from "./referral";
import { TOKENS } from "../../lib/tokens";
import { captureReferrerFromURL, getMyInviteLink, setMeAddress, getMyRewards, withdrawMyRewards, recordContributionUSDT, TOTAL_RATE } from "./referral";

function useTokenBalances(address?: Address) {
  const chainId = useChainId();
  const cfg = TOKENS[chainId] || TOKENS[56];
  const bnb = useBalance({ address, chainId, query: { enabled: !!address } });
  const usdt = useBalance({ address, chainId, token: cfg.USDT?.address as Address, query: { enabled: !!address && !!cfg.USDT?.address } });
  const rst = useBalance({ address, chainId, token: cfg.RST?.address as Address, query: { enabled: !!address && !!cfg.RST?.address } });
  return { nativeSymbol: cfg.NATIVE.symbol, bnb, usdt, rst };
}

export default function MePage() {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const [copied, setCopied] = React.useState(false);

  React.useEffect(() => {
    if (!isConnected || !address) return;
    setMeAddress(address as Address);
    captureReferrerFromURL(address as Address);
  }, [isConnected, address]);

  const { nativeSymbol, bnb, usdt, rst } = useTokenBalances(address as Address);
  const inviteLink = isConnected && address ? getMyInviteLink(address as Address) : "";
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
    <div className="min-h-screen bg-[#0b0d12] text-white px-4 py-6">
      <div className="text-xs mb-3 inline-block px-2 py-1 rounded border border-emerald-600" style={{backgroundColor:"rgba(5,150,105,.15)"}}>Me v2 ✅</div>

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

        <div className="rounded-2xl p-4" style={{background:"#12151b"}}>
          <div className="text-sm opacity-80 mb-2">规则：总 30% USDT（一级 15%、二级 10%、三级 5%）</div>
          <div className="flex items-center gap-2">
            <input className="flex-1 rounded-lg px-3 py-2 text-sm outline-none border border-white/10" style={{background:"rgba(0,0,0,.35)"}} readOnly value={inviteLink || "请先连接钱包生成邀请链接"} />
            <button className="px-3 py-2 text-sm rounded-lg active:scale-95 disabled:opacity-50" style={{background:"#4f46e5"}} disabled={!inviteLink}
              onClick={async () => { if (!inviteLink) return; await navigator.clipboard.writeText(inviteLink); setCopied(true); setTimeout(()=>setCopied(false),1500); }}>
              复制
            </button>
          </div>
          {copied && <div className="text-xs mt-2 text-emerald-400">已复制到剪贴板</div>}
        </div>

        <div className="rounded-2xl p-4 space-y-2" style={{background:"#12151b"}}>
          <div className="text-sm">待领取（USDT）：<b>{rewards.pendingUSDT}</b></div>
          <div className="text-xs opacity-70">累计业绩：一级 {rewards.stats.l1} ｜ 二级 {rewards.stats.l2} ｜ 三级 {rewards.stats.l3}</div>
          <div className="flex gap-2 mt-2">
            <button className="px-3 py-2 text-sm rounded-lg active:scale-95" style={{background:"rgba(255,255,255,.08)"}} onClick={simulate}>模拟：我买入 100 USDT</button>
            <button className="px-3 py-2 text-sm rounded-lg active:scale-95" style={{background:"#059669"}} onClick={withdraw}>领取（演示清零）</button>
          </div>
          <div className="text-xs opacity-60 mt-2">* 本页分润为前端演示；上线请改为合约/后端账本与领取。</div>
        </div>
      </section>
    </div>
  );
}

function CardRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl px-4 py-4 flex items-center justify-between" style={{background:"#12151b"}}>
      <div className="flex items-center gap-3">
        <span className="inline-block w-3 h-3 rounded-full" style={{background:"linear-gradient(135deg,#f0abfc,#818cf8)"}} />
        <span className="font-medium">{label}</span>
      </div>
      <span className="opacity-80">{value}</span>
    </div>
  );
}
'@
WriteUtf8 (J $dirFeat 'MePage.tsx') $mePageTsx

# --- 4) App Router 路由 ---
$appMe = @'
"use client";
import MePage from "../../src/features/referral/MePage";
export default function Page(){ return <MePage/> }
'@
WriteUtf8 (J $dirAppMe 'page.tsx') $appMe

# --- 5) 删除会冲突的 Pages 路由 ---
$toRemove = @(
  J $ProjectRoot 'pages\me.tsx',
  J $ProjectRoot 'pages\me\index.tsx',
  J $ProjectRoot 'src\pages\me.tsx',
  J $ProjectRoot 'src\pages\me\index.tsx'
)
foreach($p in $toRemove){ if(Test-Path $p){ Remove-Item -Force $p } }

# --- 6) Tailwind content：备份后写入通用配置 ---
$tw = J $ProjectRoot 'tailwind.config.js'
if (Test-Path $tw) { Copy-Item $tw ($tw + '.bak') -Force }
$twContent = @'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx}",
    "./pages/**/*.{js,ts,jsx,tsx}",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: { extend: {} },
  plugins: [],
};
'@
WriteUtf8 $tw $twContent

# --- 7) 环境变量 ---
$envPath = J $ProjectRoot '.env.local'
Ensure-Line $envPath "NEXT_PUBLIC_RSTOKEN_ADDRESS_MAINNET=0xYourMainnetRSTAddressHere"
Ensure-Line $envPath "NEXT_PUBLIC_RSTOKEN_ADDRESS_TESTNET=0xYourTestnetRSTAddressHere"

# --- 8) 清理 .next 缓存 ---
$nextDir = J $ProjectRoot '.next'
if (Test-Path $nextDir) { Remove-Item -Recurse -Force $nextDir }

"Done"
'@
Set-Content -Path 'D:\RStoken5.1.2\integrate-me-page.ps1' -Value $script -Encoding UTF8

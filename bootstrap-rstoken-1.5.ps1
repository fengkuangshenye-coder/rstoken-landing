# =========================
# RStoken v1.5 Project Bootstrap (Windows PowerShell)
# Target path: D:\RStoken5.1.2
# =========================

$ErrorActionPreference = "Stop"

$Root = "D:\RStoken5.1.2"

function Write-TextFile {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$Content
  )
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $Content | Out-File -FilePath $Path -Encoding utf8 -Force
  Write-Host "✔ wrote $Path"
}

# 1) Ensure root
if (-not (Test-Path $Root)) { New-Item -ItemType Directory -Path $Root -Force | Out-Null }

# 2) package.json
Write-TextFile -Path "$Root\package.json" -Content @'
{
  "name": "rstoken-dapp-1.5",
  "version": "1.5.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "typecheck": "tsc --noEmit",
    "lint": "next lint",
    "format": "prettier -w .",
    "test": "vitest run",
    "test:ui": "vitest"
  },
  "dependencies": {
    "next": "^14.2.5",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "@tanstack/react-query": "^5.51.0",
    "viem": "^2.13.7",
    "wagmi": "^2.12.10"
  },
  "devDependencies": {
    "@testing-library/jest-dom": "^6.4.8",
    "@testing-library/react": "^14.3.1",
    "@types/node": "^20.11.30",
    "@types/react": "^18.2.66",
    "@types/react-dom": "^18.2.22",
    "autoprefixer": "^10.4.18",
    "eslint": "^8.57.0",
    "eslint-config-next": "^14.2.5",
    "jsdom": "^24.0.0",
    "postcss": "^8.4.38",
    "prettier": "^3.3.3",
    "tailwindcss": "^3.4.10",
    "typescript": "^5.4.5",
    "vitest": "^1.6.0"
  }
}
'@

# 3) next.config.mjs
Write-TextFile -Path "$Root\next.config.mjs" -Content @'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  experimental: { typedRoutes: true }
};
export default nextConfig;
'@

# 4) tsconfig.json
Write-TextFile -Path "$Root\tsconfig.json" -Content @'
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "jsx": "preserve",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "resolveJsonModule": true,
    "allowJs": false,
    "noEmit": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true,
    "baseUrl": ".",
    "paths": { "@/*": ["./*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}
'@

# 5) next-env.d.ts
Write-TextFile -Path "$Root\next-env.d.ts" -Content @'
/// <reference types="next" />
/// <reference types="next/image-types/global" />
/// <reference types="next/navigation-types/compat/navigation" />
'@

# 6) Tailwind / PostCSS
Write-TextFile -Path "$Root\postcss.config.mjs" -Content @'
export default {
  plugins: { tailwindcss: {}, autoprefixer: {} }
}
'@

Write-TextFile -Path "$Root\tailwind.config.ts" -Content @'
import type { Config } from "tailwindcss"

export default {
  content: [
    "./app/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
    "./features/**/*.{js,ts,jsx,tsx}"
  ],
  theme: { container: { center: true, padding: "1rem" }, extend: {} },
  plugins: []
} satisfies Config
'@

Write-TextFile -Path "$Root\app\globals.css" -Content @'
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Minimal global to avoid conflict with GlobalStyles component */
:root{ --rs-border: rgba(255,255,255,0.12); }
body{ min-height: 100dvh; }
'@

# 7) ESLint / Prettier / Editorconfig
Write-TextFile -Path "$Root\.eslintrc.cjs" -Content @'
module.exports = {
  root: true,
  extends: ["next", "next/core-web-vitals"],
  rules: {
    "react-hooks/rules-of-hooks": "error",
    "react-hooks/exhaustive-deps": "warn"
  }
}
'@

Write-TextFile -Path "$Root\.prettierrc" -Content @'
{ "singleQuote": true, "semi": true, "trailingComma": "none", "printWidth": 100 }
'@

Write-TextFile -Path "$Root\.editorconfig" -Content @'
root = true
[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 2
insert_final_newline = true
trim_trailing_whitespace = true
'@

# 8) Vitest
Write-TextFile -Path "$Root\vitest.config.ts" -Content @'
import { defineConfig } from "vitest/config";
import path from "node:path";

export default defineConfig({
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: "./tests/setup.ts"
  },
  resolve: {
    alias: { "@": path.resolve(__dirname, "./") }
  }
});
'@

Write-TextFile -Path "$Root\tests\setup.ts" -Content @'
import "@testing-library/jest-dom";
'@

Write-TextFile -Path "$Root\tests\utils.test.ts" -Content @'
import { describe, it, expect } from "vitest";
import { calcMinReceived } from "@/lib/math";

describe("calcMinReceived", () => {
  it("works with zero bps", () => { expect(calcMinReceived(100, 0)).toBe(100); });
  it("works with 50 bps", () => { expect(calcMinReceived(100, 50)).toBe(99.5); });
});
'@

# 9) Env / Node
Write-TextFile -Path "$Root\.nvmrc" -Content @'
v18.20.3
'@

Write-TextFile -Path "$Root\.env.example" -Content @'
# Chain
NEXT_PUBLIC_DEFAULT_CHAIN_ID=56
NEXT_PUBLIC_RPC_URL_BSC=https://bsc-dataseed.binance.org
NEXT_PUBLIC_RPC_URL_BSC_TESTNET=https://data-seed-prebsc-1-s1.binance.org:8545

# RSToken addresses (replace after deploy)
NEXT_PUBLIC_RSTOKEN_ADDRESS_MAINNET=0x0000000000000000000000000000000000000000
NEXT_PUBLIC_RSTOKEN_ADDRESS_TESTNET=0x0000000000000000000000000000000000000000

# Quote API (demo or aggregator proxy)
NEXT_PUBLIC_QUOTE_API=/api/quote

# WalletConnect (optional)
NEXT_PUBLIC_WC_PROJECT_ID=
'@

# 10) README
Write-TextFile -Path "$Root\README.md" -Content @'
# RStoken v1.5 DApp

- Next.js (App Router) + TypeScript
- 首页：Hero + 预言机演示 + Tokenomics
- 闪兑页：SwapPanel + 路线图（右列 sticky）
- 资产页：本地余额示意

## 开发
pnpm i
Copy-Item .env.example .env.local
pnpm dev

## 构建
pnpm build && pnpm start

## 质量
pnpm typecheck && pnpm lint && pnpm test
'@

# 11) App shell / Providers
Write-TextFile -Path "$Root\app\layout.tsx" -Content @'
import React from "react";
import Providers from "@/app/providers";
import TopNav from "@/components/layout/TopNav";
import BottomTabs from "@/components/layout/BottomTabs";
import Starfield from "@/components/layout/Starfield";
import GlobalStyles from "@/components/layout/GlobalStyles";
import "./globals.css";

export const metadata = {
  title: "RStoken v1.5",
  description: "Life-Linked Crypto DApp"
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-CN">
      <body style={{ background: "#0A0B0E", color: "#fff" }}>
        <Providers>
          <Starfield />
          <GlobalStyles />
          <TopNav />
          <main className="pb-24">{children}</main>
          <BottomTabs />
        </Providers>
      </body>
    </html>
  );
}
'@

Write-TextFile -Path "$Root\app\page.tsx" -Content @'
"use client";
import React from "react";
import OraclePreview from "@/features/oracle/OraclePreview";
import TokenomicsCard from "@/features/tokenomics/TokenomicsCard";
import { Card, CardContent } from "@/components/ui/Card";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";

export default function HomePage(){
  return (
    <section className="container mx-auto px-4 pt-24 md:pt-28">
      <div className="grid items-start gap-10 md:grid-cols-2">
        <div>
          <Badge className="mb-4">跨时代 · 科技美学</Badge>
          <h1 className="text-4xl md:text-6xl font-bold">全球人口<span className="title-gradient"> 同步变化 </span>的智能代币</h1>
          <p className="mt-4 muted text-base md:text-lg">RStoken（人生币）是一种智能代币，它的发行和销毁直接根据全球人口变化来调整：每当全球出生一名新生儿，RStoken 增发一枚；每当全球有一名生命消逝，RStoken 销毁一枚。</p>
          <div className="mt-6 flex flex-wrap items-center gap-3">
            <Button size="lg" onClick={()=>location.assign("/swap")}>立即参与</Button>
            <Button variant="outline" size="lg">查看白皮书</Button>
          </div>
          <div className="mt-6 flex flex-wrap gap-6 dim">
            <div>🌐 2025 年全球人口约 <span style={{color:"#fff"}}>80 亿</span></div>
            <div>✅ 合约可审计</div>
            <div>🪙 公平与可持续激励</div>
          </div>
        </div>
        <OraclePreview />
      </div>

      <div className="mt-16 grid gap-6 md:grid-cols-3">
        {[{i:"🪙",t:"自动化供给",d:"基于出生/死亡数据自动增发与销毁，代币与社会基本面同频。"},
          {i:"✅",t:"公平透明",d:"数据来源与合约逻辑公开透明，可持续审计与追溯。"},
          {i:"🌐",t:"全球可及",d:"无论身处何地，均可参与购买与持有，感受宏观变化。"}].map(x=> (
          <Card key={x.t}><CardContent>
            <div className="mb-3 inline-flex rounded-xl border px-3 py-2"
                 style={{borderColor:"var(--rs-border)",background:"rgba(255,255,255,0.05)",color:"#67e8f9"}}>{x.i}</div>
            <div className="text-lg font-semibold">{x.t}</div>
            <div className="mt-2 text-sm muted">{x.d}</div>
          </CardContent></Card>
        ))}
      </div>

      <div className="mt-16"><TokenomicsCard /></div>
    </section>
  );
}
'@

Write-TextFile -Path "$Root\app\swap\page.tsx" -Content @'
"use client";
import React from "react";
import SwapPanel from "@/features/swap/SwapPanel";
import RoadmapCard from "@/features/roadmap/RoadmapCard";
import { Card, CardContent } from "@/components/ui/Card";

export default function SwapPage(){
  return (
    <section className="container mx-auto px-4 pt-24">
      <h2 className="title-gradient text-2xl font-bold mb-4">一键闪兑 · 同源视觉</h2>
      <div className="grid gap-6 md:grid-cols-2 items-start">
        <SwapPanel />
        <div className="flex flex-col gap-4 md:sticky md:top-24">
          <RoadmapCard />
          <Card className="glass">
            <CardContent>
              <div className="font-semibold mb-2">接入说明</div>
              <ul className="list-disc list-inside text-sm muted">
                <li>报价：将 <code>mockQuote</code> 替换为 1inch / 0x / OpenOcean / 自营路由。</li>
                <li>批准：ERC-20 先 <code>approve</code>，再进行 <code>swap</code>。</li>
                <li>RST 地址：部署后替换占位地址与 <code>decimals</code>。</li>
                <li>链：默认 BSC，可切换 Testnet 调试。</li>
              </ul>
            </CardContent>
          </Card>
        </div>
      </div>
    </section>
  );
}
'@

Write-TextFile -Path "$Root\app\portfolio\page.tsx" -Content @'
"use client";
import React from "react";
import PortfolioCard from "@/features/portfolio/PortfolioCard";

export default function PortfolioPage(){
  return (
    <section className="container mx-auto px-4 pt-24">
      <h2 className="title-gradient text-2xl font-bold mb-4">资产</h2>
      <PortfolioCard />
    </section>
  );
}
'@

# 12) Providers & API (BSC)
Write-TextFile -Path "$Root\app\providers.tsx" -Content @'
"use client";
import React, { useRef } from "react";
import { WagmiProvider } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { wagmiConfig } from "@/lib/wagmi";

export default function Providers({ children }: { children: React.ReactNode }) {
  const qc = useRef(new QueryClient()).current;
  return (
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={qc}>{children}</QueryClientProvider>
    </WagmiProvider>
  );
}
'@

Write-TextFile -Path "$Root\app\api\quote\route.ts" -Content @'
import { NextRequest } from "next/server";

const RATE_USD_PER_BNB = 500;
const RATE_RST_PER_USD = 1;

function toUsd(amount: number, symbol: string){
  if (symbol === "BNB") return amount * RATE_USD_PER_BNB;
  if (symbol === "USDT") return amount;
  if (symbol === "RST") return amount / RATE_RST_PER_USD;
  return 0;
}
function fromUsd(usd: number, symbol: string){
  if (symbol === "BNB") return usd / RATE_USD_PER_BNB;
  if (symbol === "USDT") return usd;
  if (symbol === "RST") return usd * RATE_RST_PER_USD;
  return 0;
}

export async function GET(req: NextRequest){
  const { searchParams } = new URL(req.url);
  const from = (searchParams.get("from")||"").toUpperCase();
  const to = (searchParams.get("to")||"").toUpperCase();
  const amount = Number(searchParams.get("amount")||"0");
  const slippageBps = Number(searchParams.get("slippageBps")||"50");

  if (!from || !to || !Number.isFinite(amount) || amount<=0) {
    return new Response(JSON.stringify({ error: "bad_params" }), { status: 400 });
  }
  const usd = toUsd(amount, from);
  const out = fromUsd(usd, to);
  const minOut = out * (1 - slippageBps/10000);

  return Response.json({ from, to, amountIn: amount, amountOut: out, minOut, priceImpact: 0 });
}
'@

# 13) Components: layout
Write-TextFile -Path "$Root\components\layout\GlobalStyles.tsx" -Content @'
"use client";
import React from "react";
export default function GlobalStyles(){
  return (
    <style>{String.raw`
      :root{
        --rs-bg:#0A0B0E; --rs-fg:white; --rs-muted:rgba(255,255,255,.70); --rs-dim:rgba(255,255,255,.55);
        --rs-border:rgba(255,255,255,.12); --rs-card:rgba(255,255,255,.03);
        --rs-accent-start:#f472b6; --rs-accent-mid:#a78bfa; --rs-accent-end:#22d3ee;
        --rs-green:#22c55e; --rs-amber:#f59e0b; --rs-radius:20px; --rs-shadow:0 24px 96px rgba(99,102,241,.25);
      }
      html,body{background:var(--rs-bg);color:var(--rs-fg);} a{text-decoration:none;color:inherit} .container{max-width:80rem}
      .glass{background:linear-gradient(135deg,rgba(255,255,255,.04),rgba(255,255,255,.02))}
      .card{border:1px solid var(--rs-border);background:var(--rs-card);border-radius:var(--rs-radius);box-shadow:var(--rs-shadow)}
      .title-gradient{background:linear-gradient(90deg,var(--rs-accent-end),var(--rs-accent-mid),var(--rs-accent-start));-webkit-background-clip:text;background-clip:text;color:transparent}
      .muted{color:var(--rs-muted)} .dim{color:var(--rs-dim)}
      .fade-in{ opacity:0; transform:translateY(10px); animation:fadein .6s ease forwards; }
      @keyframes fadein{to{opacity:1; transform:none}}
      @keyframes twinkle{0%,100%{opacity:.8}50%{opacity:.3}}
      button { cursor: pointer; }
    `}</style>
  );
}
'@

Write-TextFile -Path "$Root\components\layout\TopNav.tsx" -Content @'
"use client";
import React from "react";
import ScrollProgress from "@/components/layout/ScrollProgress";
import ConnectButtons from "@/components/wallet/ConnectButtons";

export default function TopNav(){
  return (
    <div className="fixed inset-x-0 top-0 z-40">
      <ScrollProgress />
      <div className="container mx-auto flex h-16 items-center justify-between px-4 backdrop-blur" style={{background:"rgba(0,0,0,.35)"}}>
        <div className="flex items-center gap-2">
          <div className="grid h-8 w-8 place-items-center rounded-xl" style={{background:"linear-gradient(135deg,#f472b6,#22d3ee)",color:"#0b0d10",fontWeight:700}}>RS</div>
          <div className="leading-tight">
            <div className="text-sm" style={{color:"rgba(255,255,255,.75)"}}>RStoken v1.5</div>
            <div className="text-xs dim">Life-Linked Crypto</div>
          </div>
        </div>
        <div className="hidden md:flex items-center gap-3">
          <ConnectButtons />
        </div>
      </div>
    </div>
  );
}
'@

Write-TextFile -Path "$Root\components\layout\BottomTabs.tsx" -Content @'
"use client";
import React from "react";
import { usePathname, useRouter } from "next/navigation";

export default function BottomTabs(){
  const pathname = usePathname();
  const router = useRouter();
  const Tab = (href:string, label:string)=> (
    <button onClick={()=>router.push(href)} className={`flex-1 py-3 text-sm ${pathname===href?"title-gradient":"dim"}`}>{label}</button>
  );
  return (
    <div className="fixed inset-x-0 bottom-0 z-40 border-t" style={{borderColor:"var(--rs-border)", background:"rgba(0,0,0,0.4)"}}>
      <div className="container mx-auto px-4 flex gap-2">
        {Tab("/","首页")}
        {Tab("/swap","闪兑")}
        {Tab("/portfolio","资产")}
      </div>
    </div>
  );
}
'@

Write-TextFile -Path "$Root\components\layout\ScrollProgress.tsx" -Content @'
"use client";
import React from "react";
import useScrollProgress from "@/hooks/useScrollProgress";
export default function ScrollProgress(){
  const p = useScrollProgress();
  return <div style={{width:`${(p*100).toFixed(2)}%`}} className="h-0.5 bg-gradient-to-r from-cyan-400 via-violet-400 to-rose-400"/>;
}
'@

Write-TextFile -Path "$Root\components\layout\Starfield.tsx" -Content @'
"use client";
import React from "react";
export default function Starfield(){
  return (
    <div aria-hidden className="pointer-events-none fixed inset-0 -z-10">
      <div className="absolute inset-0" style={{background:
        "radial-gradient(60% 40% at 50% 0%, rgba(37,99,235,0.25) 0%, rgba(0,0,0,0) 60%),"+
        "radial-gradient(50% 50% at 50% 100%, rgba(14,165,233,0.18) 0%, rgba(0,0,0,0) 60%)"}} />
      <div className="absolute inset-0" style={{mixBlendMode:"screen", opacity:.7, background:
        "radial-gradient(1200px 400px at 20% 10%, rgba(236,72,153,0.08), transparent),"+
        "radial-gradient(1000px 500px at 80% 20%, rgba(59,130,246,0.08), transparent),"+
        "radial-gradient(800px 600px at 50% 90%, rgba(34,197,94,0.06), transparent)"}} />
      <div className="absolute inset-0" style={{animation:"twinkle 6s linear infinite", background:
        "radial-gradient(1px 1px at 20% 30%, rgba(255,255,255,0.7), transparent),"+
        "radial-gradient(1px 1px at 70% 40%, rgba(255,255,255,0.5), transparent),"+
        "radial-gradient(1px 1px at 40% 80%, rgba(255,255,255,0.6), transparent),"+
        "radial-gradient(1px 1px at 85% 70%, rgba(255,255,255,0.5), transparent)"}} />
    </div>
  );
}
'@

# 14) Components: UI
Write-TextFile -Path "$Root\components\ui\Button.tsx" -Content @'
"use client";
import React from "react";
export function Button(
  {children, className="", variant="primary", size="md", ...props}:
  {children:React.ReactNode,className?:string,variant?:"primary"|"outline"|"ghost",size?:"sm"|"md"|"lg"} & React.ButtonHTMLAttributes<HTMLButtonElement>
){
  const sz={sm:"h-8 px-3 text-sm", md:"h-10 px-4 text-sm", lg:"h-11 px-5 text-base"};
  const base="inline-flex items-center justify-center rounded-2xl font-medium focus:outline-none focus:ring-2 focus:ring-cyan-400/40 transition";
  const st={primary:"bg-gradient-to-r from-rose-400 via-violet-400 to-cyan-400 text-black hover:opacity-90",outline:"border border-white/20 bg-white/5 text-white hover:bg-white/10",ghost:"text-white/80 hover:bg-white/5"};
  return <button className={`${base} ${sz[size]} ${st[variant]} ${className}`} {...props}>{children}</button>;
}
'@

Write-TextFile -Path "$Root\components\ui\Card.tsx" -Content @'
"use client";
import React from "react";
export function Card({children, className=""}:{children:React.ReactNode,className?:string}){return <div className={`card ${className}`}>{children}</div>}
export function CardContent({children, className=""}:{children:React.ReactNode,className?:string}){return <div className={`p-6 ${className}`}>{children}</div>}
'@

Write-TextFile -Path "$Root\components\ui\Input.tsx" -Content @'
"use client";
import React from "react";
export function Input(props: React.InputHTMLAttributes<HTMLInputElement>){
  return <input {...props} className={`w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm text-white placeholder:dim focus:outline-none focus:ring-2 focus:ring-cyan-400/40 ${props.className||""}`} />
}
'@

Write-TextFile -Path "$Root\components\ui\Badge.tsx" -Content @'
"use client";
import React from "react";
export function Badge({children, className=""}:{children:React.ReactNode,className?:string}){
  return <div className={`inline-flex items-center rounded-lg px-2.5 py-1 text-xs border border-white/10 bg-white/10 ${className}`}>{children}</div>;
}
'@

# 15) Wallet components & Chain guard
Write-TextFile -Path "$Root\components\wallet\ConnectButtons.tsx" -Content @'
"use client";
import React from "react";
import { useAccount, useConnect, useDisconnect, useChainId, useSwitchChain } from "wagmi";
import { bsc, bscTestnet } from "viem/chains";

export default function ConnectButtons(){
  const { address, isConnected } = useAccount();
  const { connect, connectors, status: cStatus } = useConnect();
  const { disconnect } = useDisconnect();
  const chainId = useChainId();
  const { switchChain } = useSwitchChain();

  const short=(a?:string)=> a? `${a.slice(0,6)}…${a.slice(-4)}`:"";

  if (isConnected) {
    return (
      <div className="flex items-center gap-2">
        <span className="text-xs text-white/70">{short(address)}</span>
        <select
          className="rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm"
          value={chainId}
          onChange={(e)=> switchChain({ chainId: Number(e.target.value) })}
        >
          {[bsc, bscTestnet].map(c => (<option key={c.id} value={c.id}>{c.name}</option>))}
        </select>
        <button className="rounded-xl border px-3 py-2 text-sm hover:bg-white/10" onClick={()=>disconnect()}>断开</button>
      </div>
    );
  }

  const injected = connectors.find(c=>c.id==="injected");
  const wc = connectors.find(c=>c.id==="walletConnect");

  return (
    <div className="flex items-center gap-2">
      {injected && <button disabled={cStatus==="pending"} className="rounded-xl border px-3 py-2 text-sm hover:bg-white/10" onClick={()=>connect({ connector: injected })}>🦊 连接钱包</button>}
      {wc && <button disabled={cStatus==="pending"} className="rounded-xl border px-3 py-2 text-sm hover:bg-white/10" onClick={()=>connect({ connector: wc })}>👜 WalletConnect</button>}
    </div>
  );
}
'@

Write-TextFile -Path "$Root\components\wallet\ChainGuard.tsx" -Content @'
"use client";
import React from "react";
import { useAccount, useChainId, useSwitchChain } from "wagmi";
import { bsc } from "viem/chains";

export default function ChainGuard({ children }: { children: React.ReactNode }){
  const { isConnected } = useAccount();
  const chainId = useChainId();
  const { switchChain } = useSwitchChain();

  if (!isConnected) return <>{children}</>;
  if (chainId !== bsc.id) {
    return (
      <div className="rounded-xl border p-3 text-sm" style={{borderColor:"var(--rs-border)", background:"rgba(255,255,255,.04)"}}>
        当前网络不是 BSC 主网。
        <button className="ml-2 underline" onClick={()=>switchChain({ chainId: bsc.id })}>一键切换</button>
      </div>
    );
  }
  return <>{children}</>;
}
'@

# 16) Hooks
Write-TextFile -Path "$Root\hooks\useLocalStorage.ts" -Content @'
"use client";
import { useEffect, useState } from "react";
export default function useLocalStorage<T>(key:string, init:T){
  const [v,setV]=useState<T>(()=>{try{const s=localStorage.getItem(key);return s?JSON.parse(s):init}catch{return init}});
  useEffect(()=>{try{localStorage.setItem(key,JSON.stringify(v))}catch{}},[key,v]);
  return [v,setV] as const;
}
'@

Write-TextFile -Path "$Root\hooks\useScrollProgress.ts" -Content @'
"use client";
import { useEffect, useState } from "react";
export default function useScrollProgress(){
  const [p,setP]=useState(0);
  useEffect(()=>{
    const onScroll=()=>{const h=document.documentElement;const sc=h.scrollTop;const height=h.scrollHeight-h.clientHeight;setP(height>0?sc/height:0)};
    onScroll(); window.addEventListener("scroll", onScroll, {passive:true});
    return ()=>window.removeEventListener("scroll", onScroll);
  },[]); return p;
}
'@

Write-TextFile -Path "$Root\hooks\useBalances.ts" -Content @'
"use client";
import useLocalStorage from "@/hooks/useLocalStorage";
export default function useBalances(addr?:string){
  const [map,setMap]=useLocalStorage<Record<string,number>>("rst_balances",{BNB:1.2345,USDT:1200,RST:5000});
  const get=(sym:string)=> map[sym]||0; const set=(sym:string,val:number)=> setMap({...map,[sym]:val});
  return {get,set};
}
'@

# 17) Lib
Write-TextFile -Path "$Root\lib\format.ts" -Content @'
export const fmt=(n:number)=> Number.isFinite(n)? (n>=1? n.toFixed(6).replace(/0+$/,"").replace(/\.$/,"") : n.toPrecision(6)) : "0";
'@

Write-TextFile -Path "$Root\lib\math.ts" -Content @'
export const calcMinReceived=(out:number, bps:number)=> out * (1 - (bps||0)/10000);
export const safe=(n:number)=> Number.isFinite(n)? n : 0;
'@

Write-TextFile -Path "$Root\lib\tokens.ts" -Content @'
export type Token={symbol:string; name:string; address?:string; decimals:number};
export const TOKENS:Token[]=[
  {symbol:"BNB", name:"BNB", decimals:18},
  {symbol:"USDT", name:"Tether USD", address:"0x55d398326f99059fF775485246999027B3197955", decimals:18},
  {symbol:"RST", name:"RStoken", address:"0x0000000000000000000000000000000000000000", decimals:18}
];
export const RATE_USD_PER_BNB=500;
export const RATE_RST_PER_USD=1;
export function mockQuote(amountIn:number, from:Token, to:Token){
  if (!amountIn || amountIn<=0) return 0; let usd=0;
  if(from.symbol==="BNB") usd=amountIn*RATE_USD_PER_BNB; else if(from.symbol==="USDT") usd=amountIn; else usd=amountIn/RATE_RST_PER_USD;
  if(to.symbol==="BNB") return usd/RATE_USD_PER_BNB; if(to.symbol==="USDT") return usd; return usd*RATE_RST_PER_USD;
}
'@

Write-TextFile -Path "$Root\lib\wagmi.ts" -Content @'
"use client";
import { createConfig, http } from "wagmi";
import { bsc, bscTestnet } from "viem/chains";
import { injected } from "wagmi/connectors";
import { walletConnect } from "wagmi/connectors";

const transports = {
  [bsc.id]: http(process.env.NEXT_PUBLIC_RPC_URL_BSC),
  [bscTestnet.id]: http(process.env.NEXT_PUBLIC_RPC_URL_BSC_TESTNET)
};

const connectors = [injected()];
if (process.env.NEXT_PUBLIC_WC_PROJECT_ID) {
  connectors.push(walletConnect({ projectId: process.env.NEXT_PUBLIC_WC_PROJECT_ID! }));
}

export const wagmiConfig = createConfig({
  chains: [bsc, bscTestnet],
  connectors,
  transports,
  ssr: true
});
'@

Write-TextFile -Path "$Root\lib\erc20.ts" -Content @'
"use client";
import { getContract, readContract } from "@wagmi/core";
import { wagmiConfig } from "@/lib/wagmi";
import abi from "@/contracts/rstoken.json";
import { RSTOKEN } from "@/contracts/addresses";

export function erc20Address(chainId: number){ return RSTOKEN[chainId]; }
export function erc20Contract(chainId: number){
  const address = erc20Address(chainId);
  if (!address) throw new Error("RST address not set for this chain");
  return getContract({ address, abi, config: wagmiConfig });
}
export async function readSymbol(chainId: number){
  const address = erc20Address(chainId)!;
  return readContract(wagmiConfig, { address, abi, functionName: "symbol" });
}
'@

# 18) Features
Write-TextFile -Path "$Root\features\oracle\OraclePreview.tsx" -Content @'
"use client";
import React, { useEffect, useRef, useState } from "react";
import { Card, CardContent } from "@/components/ui/Card";
import { Badge } from "@/components/ui/Badge";

export default function OraclePreview(){
  const [play,setPlay]=useState(true); const cache=useRef(true);
  const [births,setB]=useState(16); const [deaths,setD]=useState(6); const net=births-deaths;
  useEffect(()=>{const onVis=()=>{if(document.hidden){cache.current=play;setPlay(false)}else setPlay(cache.current)};document.addEventListener("visibilitychange",onVis);return()=>document.removeEventListener("visibilitychange",onVis)},[play]);
  useEffect(()=>{ if(!play) return; const id=setInterval(()=>{setB(b=>b+Math.floor(Math.random()*3)); setD(d=>d+Math.floor(Math.random()*2));},2000); return()=>clearInterval(id)},[play]);
  const Box=({title,value,gradient}:{title:string,value:number,gradient:string})=> (
    <div className="rounded-2xl p-4" style={{background:gradient,border:"1px solid rgba(255,255,255,0.08)"}}>
      <div className="text-xs" style={{color:"#b3c0d1"}}>{title}</div>
      <div className="mt-2 text-3xl font-semibold" style={{color:"#a5f3fc"}}>{value}</div>
    </div>
  );
  return (
    <div className="relative">
      <Card className="glass">
        <CardContent>
          <div className="mb-4 flex items-center justify-between">
            <Badge>预言机 · 演示</Badge>
            <div className="text-xs" style={{color:"#8aa0b2"}}>非实时 | 仅用于展示交互</div>
          </div>
          <div className="grid gap-3 md:grid-cols-2">
            <Box title="出生（↑增发）" value={births} gradient="linear-gradient(135deg, rgba(59,130,246,.12), rgba(14,165,233,.08))"/>
            <Box title="死亡（↓销毁）" value={deaths} gradient="linear-gradient(135deg, rgba(244,114,182,.14), rgba(99,102,241,.08))"/>
          </div>
          <div className="mt-4 rounded-2xl border px-4 py-3 flex items-center justify-between" style={{borderColor:"var(--rs-border)", background:"rgba(255,255,255,.04)"}}>
            <div className="text-sm dim">净变化（供给 Δ）</div>
            <div className="text-xl font-semibold" style={{background:"linear-gradient(90deg,#86efac,#a7f3d0)",WebkitBackgroundClip:"text",backgroundClip:"text",color:"transparent"}}>{net>0?`+${net}`:net} RST</div>
          </div>
          <div className="mt-4 flex gap-2">
            <button className="rounded-xl border px-3 py-2 text-sm" style={{borderColor:"var(--rs-border)",background:"rgba(255,255,255,.08)"}} onClick={()=>setPlay(p=>!p)}>{play?"暂停":"继续"}演示</button>
            <button className="rounded-xl px-3 py-2 text-sm" style={{background:"rgba(255,255,255,.06)"}} onClick={()=>{setB(16);setD(6)}}>重置</button>
          </div>
        </CardContent>
      </Card>
      <div className="absolute -inset-6 -z-0 rounded-[32px]" style={{background:"radial-gradient(40% 60% at 20% 10%, rgba(34,211,238,.28), transparent), radial-gradient(40% 60% at 80% 20%, rgba(244,114,182,.28), transparent)", filter:"blur(20px)"}} />
    </div>
  );
}
'@

Write-TextFile -Path "$Root\features\tokenomics\TokenomicsCard.tsx" -Content @'
"use client";
import React from "react";
import { Card, CardContent } from "@/components/ui/Card";
import data from "@/data/tokenomics.json" assert { type: "json" };

type Item={label:string,value:number,color:string};
export default function TokenomicsCard(){
  const items=data as Item[]; const total=items.reduce((s,d)=>s+d.value,0);
  const r=80, stroke=28; const C=2*Math.PI*r; let acc=0;
  const arcs=items.map(d=>{const len=C*(d.value/total); const dasharray=`${len} ${C-len}`; const dashoffset=-(C*(acc/total)); acc+=d.value; return {...d,dasharray,dashoffset}});
  const Legend=({c,name,v}:{c:string,name:string,v:number})=> (
    <div className="flex items-center justify-between rounded-2xl border px-3 py-3" style={{borderColor:"var(--rs-border)", background:"rgba(255,255,255,.04)"}}>
      <div className="flex items-center gap-3"><span style={{display:"inline-block",width:12,height:12,borderRadius:9999,background:c}}/> <span className="text-sm">{name}</span></div>
      <div className="text-sm" style={{color:"#9ca3af"}}>{v}%</div>
    </div>
  );
  return (
    <div>
      <h2 className="title-gradient text-2xl font-bold mb-3">代币分配</h2>
      <p className="muted text-sm mb-5">初始分配：社区 50%，团队与顾问 20%，项目基金 10%，市场 10%，合作伙伴/投资者 10%。</p>
      <div className="grid gap-6 md:grid-cols-2 items-center">
        <Card className="glass"><CardContent>
          <div className="rounded-3xl p-4" style={{background:"rgba(255,255,255,.03)", border:"1px solid var(--rs-border)"}}>
            <svg viewBox="0 0 200 200" width="100%" height="100%" style={{maxWidth:420,display:"block",margin:"0 auto"}}>
              <circle cx={100} cy={100} r={80} fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth={28} />
              <g transform={`rotate(-90 100 100)`}>
                {arcs.map(a=> <circle key={a.label} cx={100} cy={100} r={80} fill="none" stroke={a.color} strokeWidth={28} strokeDasharray={a.dasharray} strokeDashoffset={a.dashoffset} strokeLinecap="butt"/>) }
              </g>
              <text x={100} y={96} textAnchor="middle" fontSize={12} fill="#94a3b8">RSTOKEN</text>
              <text x={100} y={114} textAnchor="middle" fontSize={16} fill="#e2e8f0" fontWeight={600}>Tokenomics</text>
            </svg>
          </div>
        </CardContent></Card>
        <div className="grid gap-3">{items.map(d=> <Legend key={d.label} c={d.color} name={d.label} v={d.value}/>)}</div>
      </div>
    </div>
  );
}
'@

Write-TextFile -Path "$Root\features\roadmap\RoadmapCard.tsx" -Content @'
"use client";
import React from "react";
import { Card, CardContent } from "@/components/ui/Card";
export default function RoadmapCard(){
  const items=[
    { title:"初始阶段（1–3个月）", color:"#22d3ee", bullets:["完成智能合约与预言机系统","启动 ICO 并进行全球宣传","对接去中心化交易所，确保上架流通"]},
    { title:"发展阶段（6–12个月）", color:"#a78bfa", bullets:["完成全球人口数据的实时同步与合约优化","在 DeFi、钱包、支付平台扩大应用场景"]},
    { title:"成熟阶段（1–2年）", color:"#22c55e", bullets:["供应/销毁机制稳定运行","完成 DAO 治理，让社区参与投票","打造全球用户基础与商业生态"]},
  ];
  return (
    <Card className="glass"><CardContent>
      <div className="font-semibold mb-2">路线图 · RStoken 1.5</div>
      <div className="space-y-4">
        {items.map(it=> (
          <div key={it.title} className="relative pl-4">
            <span className="absolute left-0 top-2 h-2 w-2 rounded-full" style={{background:it.color}}/>
            <div className="text-sm" style={{color:"#e5e7eb"}}>{it.title}</div>
            <ul className="list-disc list-inside text-xs muted mt-1">{it.bullets.map(b=> <li key={b}>{b}</li>)}</ul>
          </div>
        ))}
      </div>
    </CardContent></Card>
  );
}
'@

Write-TextFile -Path "$Root\features\swap\SwapPanel.tsx" -Content @'
"use client";
import React, { useMemo, useState } from "react";
import { Card, CardContent } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { TOKENS, mockQuote } from "@/lib/tokens";
import useLocalStorage from "@/hooks/useLocalStorage";
import useBalances from "@/hooks/useBalances";
import { fmt } from "@/lib/format";
import { calcMinReceived, safe } from "@/lib/math";

const sanitize=(s:string)=>{const c=s.replace(/[^\d.]/g,"").replace(/^0+(?=\d)/,"").replace(/(\..*)\./g,"$1"); const [a,b=""]=c.split("."); return b.length?`${a}.${b.slice(0,18)}`:a;};

export default function SwapPanel(){
  const [addr]=useLocalStorage<string>("rst_wallet","");
  const {get:setGet,set:setSet}=useBalances(addr);
  const bal=(sym:string)=> setGet(sym);

  const [fromToken,setFromToken]=useState(TOKENS[0]);
  const [toToken,setToToken]=useState(TOKENS[2]);
  const [amountIn,setAmountIn]=useState("");
  const [slippageBps,setSlippageBps]=useState(50);

  const amountNum=parseFloat(amountIn)||0; const out=safe(useMemo(()=> mockQuote(amountNum, fromToken, toToken),[amountNum,fromToken,toToken]));
  const minOut=safe(useMemo(()=> calcMinReceived(out, slippageBps),[out,slippageBps]));

  const samePair=fromToken.symbol===toToken.symbol;
  const canApprove=!!fromToken.address && amountNum>0;
  const canSwap=addr && amountNum>0 && out>0 && !samePair && amountNum<=bal(fromToken.symbol);

  const quick=(p:number)=>{const b=bal(fromToken.symbol); setAmountIn(String(b*(p/100)))};
  const approve=()=> alert("批准（占位）：真实实现请调用合约 approve。");
  const swap=()=>{const inAfter=bal(fromToken.symbol)-amountNum; const outAfter=bal(toToken.symbol)+minOut; setSet(fromToken.symbol,Math.max(0,inAfter)); setSet(toToken.symbol,outAfter); setAmountIn(""); alert(`模拟成交：收到 ${fmt(minOut)} ${toToken.symbol}`)};

  const TokenRow=({ label, value, onChange, token, onPick, balance }:{label:string,value:string,onChange:(v:string)=>void,token:any,onPick:(t:any)=>void,balance:number})=>{
    const [open,setOpen]=useState(false);
    return (
      <div className="rounded-2xl border p-3" style={{borderColor:"var(--rs-border)",background:"rgba(255,255,255,.03)"}}>
        <div className="mb-2 flex items-center justify-between">
          <span className="text-xs dim">{label}</span>
          <div className="flex items-center gap-2 text-xs dim">余额：{fmt(balance)}</div>
          <div className="relative">
            <button className="rounded-xl border px-2 py-1 text-sm" style={{borderColor:"var(--rs-border)",background:"rgba(255,255,255,.08)"}} onClick={()=>setOpen(v=>!v)}>{token.symbol} ▾</button>
            {open && (
              <div className="absolute right-0 z-10 mt-2 w-44 overflow-hidden rounded-xl border" style={{borderColor:"var(--rs-border)",background:"#141518"}}>
                {TOKENS.map(t=> (
                  <button key={t.symbol} className="w-full px-2 py-1 text-left text-sm" style={{background:"transparent",color:"#fff"}} onClick={()=>{onPick(t);setOpen(false)}}>
                    {t.symbol} <span className="dim text-xs">— {t.name}</span>
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>
        <Input type="text" inputMode="decimal" placeholder="0.0" value={value} onChange={e=>onChange(sanitize(e.currentTarget.value))} />
      </div>
    );
  };

  const Quick=({on}:{on:(p:number)=>void})=> (
    <div className="mt-2 flex gap-2">{[[25,"25%"],[50,"50%"],[100,"MAX"]].map(([p,lab])=> <button key={lab as string} className="text-white/80 hover:bg-white/5 h-8 px-3 text-sm rounded-2xl" onClick={()=>on(p as number)}>{lab as string}</button>)}</div>
  );

  return (
    <Card><CardContent>
      <div className="mb-4 flex items-center justify-between">
        <div>
          <div className="font-semibold">闪兑 · Swap</div>
          <div className="text-xs dim">演示报价 · 真实版可接入 1inch / 0x / OpenOcean / 自营路由</div>
        </div>
      </div>
      <TokenRow label="支付" value={amountIn} onChange={setAmountIn} token={fromToken} onPick={setFromToken} balance={bal(fromToken.symbol)} />
      <Quick on={quick} />
      <div className="my-2 flex items-center justify-center dim">↓</div>
      <TokenRow label="获得（预估）" value={out?fmt(out):""} onChange={()=>{}} token={toToken} onPick={setToToken} balance={bal(toToken.symbol)} />

      <div className="mt-4 grid gap-3 md:grid-cols-2">
        <div className="rounded-xl border p-3" style={{borderColor:"var(--rs-border)",background:"rgba(255,255,255,.03)"}}>
          <div className="text-xs dim mb-1">滑点（bps）</div>
          <Input type="number" value={slippageBps} onChange={e=>setSlippageBps(Math.max(0,Number(e.currentTarget.value)||0))} />
          <div className="text-xs dim mt-1">最小到手：{fmt(minOut)} {toToken.symbol}</div>
        </div>
        <div className="rounded-xl border p-3" style={{borderColor:"var(--rs-border)",background:"rgba(255,255,255,.03)"}}>
          <div className="text-xs dim mb-1">路由与费用（演示）</div>
          <div className="text-xs">Aggregator → Router · 价格影响 ≈ 0.00%</div>
        </div>
      </div>

      <div className="mt-5 grid grid-cols-2 gap-3">
        <Button variant="outline" disabled={!canApprove} onClick={approve}>批准 / Approve</Button>
        <Button disabled={!canSwap} onClick={swap}>立即闪兑</Button>
      </div>
      {!addr && <div className="mt-2 text-xs" style={{color:"#fca5a5"}}>请先连接钱包再进行闪兑。</div>}
      {amountNum>bal(fromToken.symbol) && <div className="mt-2 text-xs" style={{color:"#fca5a5"}}>余额不足。</div>}
      {samePair && <div className="mt-2 text-xs" style={{color:"#fca5a5"}}>请选择不同的代币进行兑换。</div>}
    </CardContent></Card>
  );
}
'@

Write-TextFile -Path "$Root\features\portfolio\PortfolioCard.tsx" -Content @'
"use client";
import React from "react";
import { Card, CardContent } from "@/components/ui/Card";
import useBalances from "@/hooks/useBalances";
import useLocalStorage from "@/hooks/useLocalStorage";
import { fmt } from "@/lib/format";

export default function PortfolioCard(){
  const [addr]=useLocalStorage<string>("rst_wallet","");
  const {get}=useBalances(addr);
  const rows=["BNB","USDT","RST"];
  return (
    <Card><CardContent>
      {addr? <div className="dim text-sm mb-4">地址：{addr}</div> : <div className="dim text-sm mb-4">未连接钱包</div>}
      <div className="grid gap-3">
        {rows.map(s=> (
          <div key={s} className="flex items-center justify-between rounded-xl border px-3 py-2" style={{borderColor:"var(--rs-border)", background:"rgba(255,255,255,0.03)"}}>
            <div className="flex items-center gap-2"><div className="h-6 w-6 rounded-full" style={{background:"linear-gradient(135deg,#f472b6,#22d3ee)"}}></div><div>{s}</div></div>
            <div className="dim">{fmt(get(s))}</div>
          </div>
        ))}
      </div>
    </CardContent></Card>
  );
}
'@

# 19) Data
Write-TextFile -Path "$Root\data\tokenomics.json" -Content @'
[
  {"label":"社区与用户奖励","value":50,"color":"#22d3ee"},
  {"label":"团队与顾问","value":20,"color":"#a78bfa"},
  {"label":"项目基金","value":10,"color":"#22c55e"},
  {"label":"市场推广","value":10,"color":"#f59e0b"},
  {"label":"合作伙伴/投资者","value":10,"color":"#f472b6"}
]
'@

# 20) Contracts
Write-TextFile -Path "$Root\contracts\addresses.ts" -Content @'
export const RSTOKEN: Record<number, `0x${string}` | undefined> = {
  56: process.env.NEXT_PUBLIC_RSTOKEN_ADDRESS_MAINNET as `0x${string}` | undefined,
  97: process.env.NEXT_PUBLIC_RSTOKEN_ADDRESS_TESTNET as `0x${string}` | undefined
};
export const RSTOKEN_DECIMALS = 18;
'@

Write-TextFile -Path "$Root\contracts\rstoken.json" -Content @'
[
  { "type": "function", "stateMutability": "view", "name": "name", "inputs": [], "outputs": [{"name":"","type":"string"}] },
  { "type": "function", "stateMutability": "view", "name": "symbol", "inputs": [], "outputs": [{"name":"","type":"string"}] },
  { "type": "function", "stateMutability": "view", "name": "decimals", "inputs": [], "outputs": [{"name":"","type":"uint8"}] },
  { "type": "function", "stateMutability": "view", "name": "totalSupply", "inputs": [], "outputs": [{"name":"","type":"uint256"}] },
  { "type": "function", "stateMutability": "view", "name": "balanceOf", "inputs": [{"name":"account","type":"address"}], "outputs": [{"name":"","type":"uint256"}] },
  { "type": "function", "stateMutability": "view", "name": "allowance", "inputs": [{"name":"owner","type":"address"},{"name":"spender","type":"address"}], "outputs": [{"name":"","type":"uint256"}] },
  { "type": "function", "stateMutability": "nonpayable", "name": "approve", "inputs": [{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}], "outputs": [{"name":"","type":"bool"}] },
  { "type": "function", "stateMutability": "nonpayable", "name": "transfer", "inputs": [{"name":"to","type":"address"},{"name":"amount","type":"uint256"}], "outputs": [{"name":"","type":"bool"}] },
  { "type": "function", "stateMutability": "nonpayable", "name": "transferFrom", "inputs": [{"name":"from","type":"address"},{"name":"to","type":"address"},{"name":"amount","type":"uint256"}], "outputs": [{"name":"","type":"bool"}] }
]
'@

Write-TextFile -Path "$Root\.gitignore" -Content @'
node_modules
.next
out
.env*
.DS_Store
'@

Write-Host ""
Write-Host "✅ All files for RStoken v1.5 have been written to $Root"
Write-Host "Next steps:"
Write-Host "1) Open PowerShell and run: cd $Root"
Write-Host "2) Install deps:      pnpm i   (或 npm i / yarn)"
Write-Host "3) Copy env:          Copy-Item .env.example .env.local"
Write-Host "4) Start dev server:  pnpm dev"

# fix: 给内容加内边距，避免 fixed 头/尾遮挡
param(
  [int]\ = 64,     # 顶部 Header 预留高度（px）
  [int]\ = 72   # 底部 Tabs 预留高度（px）
)

function Save-Utf8Bom([string]\, [string]\){
  \System.Text.UTF8Encoding = New-Object System.Text.UTF8Encoding(\True)
  [IO.File]::WriteAllText(\, \, \System.Text.UTF8Encoding)
}

function Ensure-Class([string]\, [string[]]\.next node_modules backup-* backup-*/**/* safe-bak-* safe-bak-*/**/* patch-backup-* patch-backup-*/**/* quickfix-bak-* quickfix-bak-*/**/* fix-bak-* fix-bak-*/**/* bottomtabs-bak-* bottomtabs-bak-*/**/* rollback-bak-* rollback-bak-*/**/* backups-* backups-*/**/*){
  if(-not \){ return (\.next node_modules backup-* backup-*/**/* safe-bak-* safe-bak-*/**/* patch-backup-* patch-backup-*/**/* quickfix-bak-* quickfix-bak-*/**/* fix-bak-* fix-bak-*/**/* bottomtabs-bak-* bottomtabs-bak-*/**/* rollback-bak-* rollback-bak-*/**/* backups-* backups-*/**/* -join ' ') }
  \ = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  foreach(\ in (\ -split '\s+')){ if(\){ [void]\.Add(\) } }
  foreach(\ in \.next node_modules backup-* backup-*/**/* safe-bak-* safe-bak-*/**/* patch-backup-* patch-backup-*/**/* quickfix-bak-* quickfix-bak-*/**/* fix-bak-* fix-bak-*/**/* bottomtabs-bak-* bottomtabs-bak-*/**/* rollback-bak-* rollback-bak-*/**/* backups-* backups-*/**/*){ if(\){ [void]\.Add(\) } }
  return [string]::Join(' ', \)
}

function Patch-Layout([string]\){
  if(-not (Test-Path \)){ return \False }
  \C:\Users\略\AppData\Local\Temp\rst-restore-20250928184428\RStoken5.1.2 = Get-Content \ -Raw

  # 1) <main className="..."> => 注入 pt/pb/min-h
  \ = "pt-".Replace('pt-','pt-').Replace('pt-64','pt-16') # 仅占位，无实际转换
  # Tailwind 的 pt-16≈64px，pb-20≈80px；我们直接塞入精确 px 用法
  \.next node_modules backup-* backup-*/**/* safe-bak-* safe-bak-*/**/* patch-backup-* patch-backup-*/**/* quickfix-bak-* quickfix-bak-*/**/* fix-bak-* fix-bak-*/**/* bottomtabs-bak-* bottomtabs-bak-*/**/* rollback-bak-* rollback-bak-*/**/* backups-* backups-*/**/* = @('min-h-screen', "pt-[px]", "pb-[px]")

  if(\C:\Users\略\AppData\Local\Temp\rst-restore-20250928184428\RStoken5.1.2 -match '<main([^>]*?)className="([^"]*)"(.*?)>'){
    \"use client";
import React from "react";
import { usePathname, useRouter } from "next/navigation";
import type { Route } from "next";

export default function BottomTabs(){
  const pathname = usePathname();
  const router = useRouter();
  const tabs: { href: string; label: string }[] = [ { "href": "/", "label": "首页" }, { "href": "/swap", "label": "闪兑" } ];
  return (
    <div className="fixed inset-x-0 bottom-0 z-40 border-t"
         style={{borderColor:"var(--rs-border)", background:"rgba(0,0,0,0.4)"}}>
      <div className="container mx-auto px-4 flex gap-2">
        {tabs.map(t => (
          <button key={t.href}
                  onClick={()=>router.push(t.href as Route)}
                  className={`flex-1 py-3 text-sm ${pathname===t.href ? "title-gradient" : "dim"}`}>{t.label}</button>
        ))}
      </div>
    </div>
  );
}
 = \System.Collections.Hashtable[0]
    \ = \System.Collections.Hashtable[2]
    \import { createConfig, http } from "wagmi";
import { injected } from "wagmi/connectors";
import { bsc, bscTestnet } from "viem/chains";

export const config = createConfig({
  chains: [bsc, bscTestnet],
  multiInjectedProviderDiscovery: true,
  connectors: [
    injected({ target: "metaMask" }),
    injected({ target: "okxWallet" }),
    injected({ target: "bitgetWallet" }),
    injected()
  ],
  transports: {
    [bsc.id]: http("https://bsc-dataseed.binance.org"),
    [bscTestnet.id]: http("https://data-seed-prebsc-1-s1.binance.org:8545"),
  },
  ssr: true
});
export default config; = \"use client";
import React from "react";
import { usePathname, useRouter } from "next/navigation";
import type { Route } from "next";

export default function BottomTabs(){
  const pathname = usePathname();
  const router = useRouter();
  const tabs: { href: string; label: string }[] = [ { "href": "/", "label": "首页" }, { "href": "/swap", "label": "闪兑" } ];
  return (
    <div className="fixed inset-x-0 bottom-0 z-40 border-t"
         style={{borderColor:"var(--rs-border)", background:"rgba(0,0,0,0.4)"}}>
      <div className="container mx-auto px-4 flex gap-2">
        {tabs.map(t => (
          <button key={t.href}
                  onClick={()=>router.push(t.href as Route)}
                  className={`flex-1 py-3 text-sm ${pathname===t.href ? "title-gradient" : "dim"}`}>{t.label}</button>
        ))}
      </div>
    </div>
  );
}
 -replace 'className="[^"]*"', ('className="' + (Ensure-Class \ \.next node_modules backup-* backup-*/**/* safe-bak-* safe-bak-*/**/* patch-backup-* patch-backup-*/**/* quickfix-bak-* quickfix-bak-*/**/* fix-bak-* fix-bak-*/**/* bottomtabs-bak-* bottomtabs-bak-*/**/* rollback-bak-* rollback-bak-*/**/* backups-* backups-*/**/*) + '"')
    \C:\Users\略\AppData\Local\Temp\rst-restore-20250928184428\RStoken5.1.2 = \C:\Users\略\AppData\Local\Temp\rst-restore-20250928184428\RStoken5.1.2.Replace(\"use client";
import React from "react";
import { usePathname, useRouter } from "next/navigation";
import type { Route } from "next";

export default function BottomTabs(){
  const pathname = usePathname();
  const router = useRouter();
  const tabs: { href: string; label: string }[] = [ { "href": "/", "label": "首页" }, { "href": "/swap", "label": "闪兑" } ];
  return (
    <div className="fixed inset-x-0 bottom-0 z-40 border-t"
         style={{borderColor:"var(--rs-border)", background:"rgba(0,0,0,0.4)"}}>
      <div className="container mx-auto px-4 flex gap-2">
        {tabs.map(t => (
          <button key={t.href}
                  onClick={()=>router.push(t.href as Route)}
                  className={`flex-1 py-3 text-sm ${pathname===t.href ? "title-gradient" : "dim"}`}>{t.label}</button>
        ))}
      </div>
    </div>
  );
}
,\import { createConfig, http } from "wagmi";
import { injected } from "wagmi/connectors";
import { bsc, bscTestnet } from "viem/chains";

export const config = createConfig({
  chains: [bsc, bscTestnet],
  multiInjectedProviderDiscovery: true,
  connectors: [
    injected({ target: "metaMask" }),
    injected({ target: "okxWallet" }),
    injected({ target: "bitgetWallet" }),
    injected()
  ],
  transports: {
    [bsc.id]: http("https://bsc-dataseed.binance.org"),
    [bscTestnet.id]: http("https://data-seed-prebsc-1-s1.binance.org:8545"),
  },
  ssr: true
});
export default config;)
  }
  elseif(\C:\Users\略\AppData\Local\Temp\rst-restore-20250928184428\RStoken5.1.2 -match '<main([^>]*)>'){
    # 有 <main> 无 className，补上
    \"use client";
import React from "react";
import { usePathname, useRouter } from "next/navigation";
import type { Route } from "next";

export default function BottomTabs(){
  const pathname = usePathname();
  const router = useRouter();
  const tabs: { href: string; label: string }[] = [ { "href": "/", "label": "首页" }, { "href": "/swap", "label": "闪兑" } ];
  return (
    <div className="fixed inset-x-0 bottom-0 z-40 border-t"
         style={{borderColor:"var(--rs-border)", background:"rgba(0,0,0,0.4)"}}>
      <div className="container mx-auto px-4 flex gap-2">
        {tabs.map(t => (
          <button key={t.href}
                  onClick={()=>router.push(t.href as Route)}
                  className={`flex-1 py-3 text-sm ${pathname===t.href ? "title-gradient" : "dim"}`}>{t.label}</button>
        ))}
      </div>
    </div>
  );
}
 = \System.Collections.Hashtable[0]
    \ = '<main className="' + ((\.next node_modules backup-* backup-*/**/* safe-bak-* safe-bak-*/**/* patch-backup-* patch-backup-*/**/* quickfix-bak-* quickfix-bak-*/**/* fix-bak-* fix-bak-*/**/* bottomtabs-bak-* bottomtabs-bak-*/**/* rollback-bak-* rollback-bak-*/**/* backups-* backups-*/**/* -join ' ')) + '"'+\System.Collections.Hashtable[1] + '>'
    \C:\Users\略\AppData\Local\Temp\rst-restore-20250928184428\RStoken5.1.2 = \C:\Users\略\AppData\Local\Temp\rst-restore-20250928184428\RStoken5.1.2.Replace(\"use client";
import React from "react";
import { usePathname, useRouter } from "next/navigation";
import type { Route } from "next";

export default function BottomTabs(){
  const pathname = usePathname();
  const router = useRouter();
  const tabs: { href: string; label: string }[] = [ { "href": "/", "label": "首页" }, { "href": "/swap", "label": "闪兑" } ];
  return (
    <div className="fixed inset-x-0 bottom-0 z-40 border-t"
         style={{borderColor:"var(--rs-border)", background:"rgba(0,0,0,0.4)"}}>
      <div className="container mx-auto px-4 flex gap-2">
        {tabs.map(t => (
          <button key={t.href}
                  onClick={()=>router.push(t.href as Route)}
                  className={`flex-1 py-3 text-sm ${pathname===t.href ? "title-gradient" : "dim"}`}>{t.label}</button>
        ))}
      </div>
    </div>
  );
}
,\)
  }
  elseif(\C:\Users\略\AppData\Local\Temp\rst-restore-20250928184428\RStoken5.1.2 -match '\{children\}'){
    # 没有 <main>，把 children 包起来
    \C:\Users\略\AppData\Local\Temp\rst-restore-20250928184428\RStoken5.1.2 = \C:\Users\略\AppData\Local\Temp\rst-restore-20250928184428\RStoken5.1.2 -replace '\{children\}', ('<main className="' + ((\.next node_modules backup-* backup-*/**/* safe-bak-* safe-bak-*/**/* patch-backup-* patch-backup-*/**/* quickfix-bak-* quickfix-bak-*/**/* fix-bak-* fix-bak-*/**/* bottomtabs-bak-* bottomtabs-bak-*/**/* rollback-bak-* rollback-bak-*/**/* backups-* backups-*/**/* -join ' ')) + '">{children}</main>')
  }

  Save-Utf8Bom \ \C:\Users\略\AppData\Local\Temp\rst-restore-20250928184428\RStoken5.1.2
  Write-Host "  [ok] "
  return \True
}

function Patch-PageContainer([string]\){
  if(-not (Test-Path \)){ return \False }
  \C:\Users\略\AppData\Local\Temp\rst-restore-20250928184428\RStoken5.1.2 = Get-Content \ -Raw
  \.next node_modules backup-* backup-*/**/* safe-bak-* safe-bak-*/**/* patch-backup-* patch-backup-*/**/* quickfix-bak-* quickfix-bak-*/**/* fix-bak-* fix-bak-*/**/* bottomtabs-bak-* bottomtabs-bak-*/**/* rollback-bak-* rollback-bak-*/**/* backups-* backups-*/**/* = @("pt-[px]", "pb-[px]")

  # 找到 return( <div className="container ...">
  if(\C:\Users\略\AppData\Local\Temp\rst-restore-20250928184428\RStoken5.1.2 -match 'className="([^"]*?\bcontainer\b[^"]*)"'){
    \"use client";
import React from "react";
import { usePathname, useRouter } from "next/navigation";
import type { Route } from "next";

export default function BottomTabs(){
  const pathname = usePathname();
  const router = useRouter();
  const tabs: { href: string; label: string }[] = [ { "href": "/", "label": "首页" }, { "href": "/swap", "label": "闪兑" } ];
  return (
    <div className="fixed inset-x-0 bottom-0 z-40 border-t"
         style={{borderColor:"var(--rs-border)", background:"rgba(0,0,0,0.4)"}}>
      <div className="container mx-auto px-4 flex gap-2">
        {tabs.map(t => (
          <button key={t.href}
                  onClick={()=>router.push(t.href as Route)}
                  className={`flex-1 py-3 text-sm ${pathname===t.href ? "title-gradient" : "dim"}`}>{t.label}</button>
        ))}
      </div>
    </div>
  );
}
 = \System.Collections.Hashtable[0]
    \ = \System.Collections.Hashtable[1]
    \import { createConfig, http } from "wagmi";
import { injected } from "wagmi/connectors";
import { bsc, bscTestnet } from "viem/chains";

export const config = createConfig({
  chains: [bsc, bscTestnet],
  multiInjectedProviderDiscovery: true,
  connectors: [
    injected({ target: "metaMask" }),
    injected({ target: "okxWallet" }),
    injected({ target: "bitgetWallet" }),
    injected()
  ],
  transports: {
    [bsc.id]: http("https://bsc-dataseed.binance.org"),
    [bscTestnet.id]: http("https://data-seed-prebsc-1-s1.binance.org:8545"),
  },
  ssr: true
});
export default config; = \"use client";
import React from "react";
import { usePathname, useRouter } from "next/navigation";
import type { Route } from "next";

export default function BottomTabs(){
  const pathname = usePathname();
  const router = useRouter();
  const tabs: { href: string; label: string }[] = [ { "href": "/", "label": "首页" }, { "href": "/swap", "label": "闪兑" } ];
  return (
    <div className="fixed inset-x-0 bottom-0 z-40 border-t"
         style={{borderColor:"var(--rs-border)", background:"rgba(0,0,0,0.4)"}}>
      <div className="container mx-auto px-4 flex gap-2">
        {tabs.map(t => (
          <button key={t.href}
                  onClick={()=>router.push(t.href as Route)}
                  className={`flex-1 py-3 text-sm ${pathname===t.href ? "title-gradient" : "dim"}`}>{t.label}</button>
        ))}
      </div>
    </div>
  );
}
 -replace 'className="[^"]*"', ('className="' + (Ensure-Class \ \.next node_modules backup-* backup-*/**/* safe-bak-* safe-bak-*/**/* patch-backup-* patch-backup-*/**/* quickfix-bak-* quickfix-bak-*/**/* fix-bak-* fix-bak-*/**/* bottomtabs-bak-* bottomtabs-bak-*/**/* rollback-bak-* rollback-bak-*/**/* backups-* backups-*/**/*) + '"')
    \C:\Users\略\AppData\Local\Temp\rst-restore-20250928184428\RStoken5.1.2 = \C:\Users\略\AppData\Local\Temp\rst-restore-20250928184428\RStoken5.1.2.Replace(\"use client";
import React from "react";
import { usePathname, useRouter } from "next/navigation";
import type { Route } from "next";

export default function BottomTabs(){
  const pathname = usePathname();
  const router = useRouter();
  const tabs: { href: string; label: string }[] = [ { "href": "/", "label": "首页" }, { "href": "/swap", "label": "闪兑" } ];
  return (
    <div className="fixed inset-x-0 bottom-0 z-40 border-t"
         style={{borderColor:"var(--rs-border)", background:"rgba(0,0,0,0.4)"}}>
      <div className="container mx-auto px-4 flex gap-2">
        {tabs.map(t => (
          <button key={t.href}
                  onClick={()=>router.push(t.href as Route)}
                  className={`flex-1 py-3 text-sm ${pathname===t.href ? "title-gradient" : "dim"}`}>{t.label}</button>
        ))}
      </div>
    </div>
  );
}
,\import { createConfig, http } from "wagmi";
import { injected } from "wagmi/connectors";
import { bsc, bscTestnet } from "viem/chains";

export const config = createConfig({
  chains: [bsc, bscTestnet],
  multiInjectedProviderDiscovery: true,
  connectors: [
    injected({ target: "metaMask" }),
    injected({ target: "okxWallet" }),
    injected({ target: "bitgetWallet" }),
    injected()
  ],
  transports: {
    [bsc.id]: http("https://bsc-dataseed.binance.org"),
    [bscTestnet.id]: http("https://data-seed-prebsc-1-s1.binance.org:8545"),
  },
  ssr: true
});
export default config;)
    Save-Utf8Bom \ \C:\Users\略\AppData\Local\Temp\rst-restore-20250928184428\RStoken5.1.2
    Write-Host "  [ok] "
    return \True
  }
  return \False
}

Write-Host "== 修复开始 ==" -ForegroundColor Cyan

\D:\RStoken5.1.2 = Get-Location
\D:\RStoken5.1.2\safe-rollback-20250928-183807  = Join-Path \D:\RStoken5.1.2 ("padfix-bak-" + (Get-Date -Format yyyyMMdd-HHmmss))
New-Item -ItemType Directory -Force -Path \D:\RStoken5.1.2\safe-rollback-20250928-183807 | Out-Null

# 备份候选文件
\ = @(
  'app\layout.tsx',
  'app\me\page.tsx',
  'app\portfolio\page.tsx',
  'features\account\MyPanel.tsx'
) | ForEach-Object { Join-Path \D:\RStoken5.1.2 \ } | Where-Object { Test-Path \ }

foreach(\ in \){
  Copy-Item \ (Join-Path \D:\RStoken5.1.2\safe-rollback-20250928-183807 (Split-Path -Leaf \)) -Force
}

# 1) 优先修全局 layout.tsx
\ = \False
\ = Join-Path \D:\RStoken5.1.2 'app\layout.tsx'
if(Test-Path \){
  Write-Host "
-- 修复 app/layout.tsx --" -ForegroundColor Yellow
  \ = Patch-Layout \
}else{
  Write-Host "  [skip] 未找到 app/layout.tsx"
}

# 2) 如果没改到（或没有 layout），分别给单页加 pt/pb
if(-not \){
  Write-Host "
-- 修复页面容器 --" -ForegroundColor Yellow
  [void](Patch-PageContainer (Join-Path \D:\RStoken5.1.2 'app\me\page.tsx'))
  [void](Patch-PageContainer (Join-Path \D:\RStoken5.1.2 'app\portfolio\page.tsx'))
  [void](Patch-PageContainer (Join-Path \D:\RStoken5.1.2 'features\account\MyPanel.tsx'))
}

Write-Host "
备份目录: \D:\RStoken5.1.2\safe-rollback-20250928-183807" -ForegroundColor DarkGray
Write-Host "
完成。现在刷新页面查看“我的”等页面是否仍被遮挡。" -ForegroundColor Green
Write-Host "若你的 Header 或 BottomTabs 高度不是 64/72px，可执行：" -ForegroundColor Yellow
Write-Host "  powershell -NoLogo -File "\" -TopPadPx 56 -BottomPadPx 64" -ForegroundColor Yellow
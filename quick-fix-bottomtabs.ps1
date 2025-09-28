$ErrorActionPreference = "Stop"

function SaveUtf8Bom([string]$path,[string]$content){
  $dir = Split-Path -Parent $path
  if($dir -and -not (Test-Path $dir)){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $enc = New-Object System.Text.UTF8Encoding($true)  # UTF-8 with BOM
  [IO.File]::WriteAllText($path,$content,$enc)
}

# 1) 写入干净可编译的 BottomTabs.tsx（首页 / 闪兑 / 我的）
$tabsPath = "components\layout\BottomTabs.tsx"
$tabsTsx = @"
"use client";
import React from "react";
import { useRouter, usePathname } from "next/navigation";
import type { Route } from "next";

export default function BottomTabs(){
  const router = useRouter();
  const pathname = usePathname();

  const Tab = (href: Route, label: string) => (
    <button
      onClick={() => router.push(href)}
      className={`flex-1 py-3 text-sm ${pathname === href ? "title-gradient" : "dim"}`}
    >
      {label}
    </button>
  );

  return (
    <div className="fixed inset-x-0 bottom-0 z-40 border-t" style={{borderColor:"var(--rs-border)", background:"rgba(0,0,0,0.4)"}}>
      <div className="container mx-auto px-4 flex gap-2">
        {Tab("/" as Route, "首页")}
        {Tab("/swap" as Route, "闪兑")}
        {Tab("/me" as Route, "我的")}
      </div>
    </div>
  );
}
"@

SaveUtf8Bom $tabsPath $tabsTsx
Write-Host "[ok] 写入 $tabsPath" -ForegroundColor Green

# 2) TypeScript 检查
cmd /c "pnpm exec tsc -p tsconfig.json --noEmit"
if($LASTEXITCODE -eq 0){
  Write-Host "[ok] TypeScript 通过" -ForegroundColor Green
}else{
  Write-Host "[fail] tsc exit $LASTEXITCODE（把上面的错误贴出来我再给补丁）" -ForegroundColor Red
}
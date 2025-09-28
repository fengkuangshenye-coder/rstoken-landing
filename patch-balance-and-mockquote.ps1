$ErrorActionPreference = "Stop"
function SaveUtf8Bom([string]$Path,[string]$Text){
  $crlf = "`r`n"
  $txt  = ($Text -split "`r?`n") -join $crlf
  $enc  = New-Object System.Text.UTF8Encoding($true)
  [IO.File]::WriteAllText($Path,$txt,$enc)
}
Write-Host "== Patch: fix useBalance watch + export mockQuote & icons ==" -ForegroundColor Cyan

# 1) public/tokens/* icons (bnc/usdt/rst)
$icons = Join-Path (Get-Location) "public\tokens"
if(!(Test-Path $icons)){ New-Item -ItemType Directory -Force -Path $icons | Out-Null }

$usdtSvg = @"
<svg viewBox='0 0 64 64' xmlns='http://www.w3.org/2000/svg'>
  <circle cx='32' cy='32' r='32' fill='#26A17B'/>
  <path fill='#fff' d='M18 20h28v6H35v18h-6V26H18zM26 14h12v6H26z'/>
</svg>
"@
$bnbSvg = @"
<svg viewBox='0 0 64 64' xmlns='http://www.w3.org/2000/svg'>
  <circle cx='32' cy='32' r='32' fill='#F3BA2F'/>
  <path fill='#111' d='M32 14l6 6-6 6-6-6 6-6zm-12 12l6 6-6 6-6-6 6-6zm24 0l6 6-6 6-6-6 6-6zM32 38l6 6-6 6-6-6 6-6z'/>
</svg>
"@
$rstSvg = @"
<svg viewBox='0 0 64 64' xmlns='http://www.w3.org/2000/svg'>
  <defs>
    <linearGradient id='g' x1='0' x2='1' y1='0' y2='1'>
      <stop offset='0' stop-color='#22d3ee'/><stop offset='1' stop-color='#a78bfa'/>
    </linearGradient>
  </defs>
  <circle cx='32' cy='32' r='32' fill='url(#g)'/>
  <text x='32' y='38' font-size='18' text-anchor='middle' fill='#000' font-family='Arial,Helvetica,sans-serif'>RST</text>
</svg>
"@
SaveUtf8Bom (Join-Path $icons "usdt.svg") $usdtSvg
SaveUtf8Bom (Join-Path $icons "bnb.svg")  $bnbSvg
SaveUtf8Bom (Join-Path $icons "rst.svg")  $rstSvg
Write-Host "  [ok] icons ready: /tokens/usdt.svg, /tokens/bnb.svg, /tokens/rst.svg"

# 2) lib/tokens.ts 导出 TOKENS + tokenIconSrc + mockQuote
$libDir = Join-Path (Get-Location) "lib"
if(!(Test-Path $libDir)){ New-Item -ItemType Directory -Force -Path $libDir | Out-Null }
$tokensPath = Join-Path $libDir "tokens.ts"
$tokensTs = @"
import type { Address } from "viem";

export type Token = {
  symbol: "BNB" | "USDT" | "RST";
  name: string;
  address?: Address;
  decimals: number;
};

export const TOKENS: Token[] = [
  { symbol: "BNB",  name: "BNB",         decimals: 18 },
  { symbol: "USDT", name: "Tether USD",  address: "0x55d398326f99059fF775485246999027B3197955" as Address, decimals: 18 },
  { symbol: "RST",  name: "RStoken",     decimals: 18 },
];

export function tokenIconSrc(symbol: string): string {
  const s = symbol.toUpperCase();
  if (s === "BNB")  return "/tokens/bnb.svg";
  if (s === "USDT") return "/tokens/usdt.svg";
  if (s === "RST")  return "/tokens/rst.svg";
  return "/tokens/usdt.svg";
}

// ----- demo quote (replace with 1inch/0x/OpenOcean later) -----
const RATE_USD_PER_BNB = 500; // demo: 1 BNB ≈ 500 USD
const RATE_RST_PER_USD = 1;   // demo: 1 USD ≈ 1 RST

export function mockQuote(amountIn: number, from: Token, to: Token): number {
  if (!amountIn || amountIn <= 0) return 0;
  let usd = 0;
  if (from.symbol === "BNB") usd = amountIn * RATE_USD_PER_BNB;
  else if (from.symbol === "USDT") usd = amountIn;
  else usd = amountIn / RATE_RST_PER_USD; // RST -> USD

  if (to.symbol === "BNB")  return usd / RATE_USD_PER_BNB;
  if (to.symbol === "USDT") return usd;
  return usd * RATE_RST_PER_USD; // -> RST
}
"@
SaveUtf8Bom $tokensPath $tokensTs
Write-Host "  [ok] lib/tokens.ts written (TOKENS/tokenIconSrc/mockQuote)"

# 3) 修复 features/account/MyPanel.tsx 的 useBalance({ ..., watch:true })
$myPanel = Join-Path (Get-Location) "features\account\MyPanel.tsx"
if(Test-Path $myPanel){
  $src = Get-Content $myPanel -Raw -Encoding UTF8
  # 去掉 watch:true
  $src = $src -replace 'watch\s*:\s*true\s*,?', ''
  # 若有 query:{} 且未包含 refetchInterval，则追加一个 10s
  $src = [regex]::Replace($src, 'query\s*:\s*{([^}]*)}', {
    param($m)
    $body = $m.Groups[1].Value
    if($body -match 'refetchInterval\s*:'){ return $m.Value }
    $bodyTrim = $body.Trim()
    $comma = ($bodyTrim.Length -gt 0) ? ', ' : ''
    return 'query: {' + $bodyTrim + $comma + 'refetchInterval: 10000}'
  })
  SaveUtf8Bom $myPanel $src
  Write-Host "  [ok] MyPanel.tsx: removed watch:true, ensured query.refetchInterval"
}else{
  Write-Host "  [skip] MyPanel.tsx not found, skip"
}

# 4) 运行 tsc 验证
$pnpm = (Get-Command pnpm.cmd -ErrorAction SilentlyContinue).Source
if(-not $pnpm){ throw "pnpm not found in PATH" }
Write-Host "`n== TypeScript check ==" -ForegroundColor Yellow
& $pnpm exec tsc -p tsconfig.json --noEmit
if($LASTEXITCODE -eq 0){
  Write-Host "  [ok] tsc passed" -ForegroundColor Green
}else{
  Write-Host "  [FAIL] tsc exit $LASTEXITCODE — paste errors here, I’ll patch" -ForegroundColor Red
}
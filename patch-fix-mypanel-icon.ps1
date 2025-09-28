$ErrorActionPreference = "Stop"

function SaveUtf8Bom([string]$Path,[string]$Text){
  $crlf = "`r`n"
  $txt  = ($Text -split "`r?`n") -join $crlf
  $enc  = New-Object System.Text.UTF8Encoding($true)
  [IO.File]::WriteAllText($Path,$txt,$enc)
}

function EnsureTokenIconImport([string]$filePath){
  if(!(Test-Path $filePath)){ return $false }
  $s = Get-Content $filePath -Raw -Encoding UTF8
  $changed = $false

  # 已有从 "@/lib/tokens" 的 import，补上 tokenIconSrc
  if($s -match 'import\s*{\s*([^}]*?)\s*}\s*from\s*"(?:@/)?lib/tokens"'){
    if($s -notmatch '\btokenIconSrc\b'){
      $s = $s -replace 'import\s*{\s*([^}]*?)\s*}\s*from\s*"(?:@/)?lib/tokens"',
                       'import { $1, tokenIconSrc } from "@/lib/tokens"'
      $changed = $true
    }
  } else {
    # 没有 import，插入到第一条 import 之后
    if($s -match 'import .+'){
      $s = $s -replace '(import[^\n]+\n)+', { param($m) $m.Value + 'import { tokenIconSrc } from "@/lib/tokens";' + "`r`n" }
      $changed = $true
    } else {
      $s = 'import { tokenIconSrc } from "@/lib/tokens";' + "`r`n" + $s
      $changed = $true
    }
  }

  # 替换 img 的 src={token.icon} / src={t.icon}
  $s2 = $s -replace 'src=\s*\{\s*token\.icon\s*\}', 'src={tokenIconSrc(token.symbol)}'
  $s2 = $s2 -replace 'src=\s*\{\s*t\.icon\s*\}',   'src={tokenIconSrc(t.symbol)}'
  if($s2 -ne $s){ $changed = $true; $s = $s2 }

  if($changed){ SaveUtf8Bom $filePath $s }
  return $changed
}

Write-Host "== Patch MyPanel icon usage ==" -ForegroundColor Cyan
$myPanel = Join-Path (Get-Location).Path "features\account\MyPanel.tsx"
if(Test-Path $myPanel){
  $changed = EnsureTokenIconImport $myPanel
  if($changed){ Write-Host "  [ok] MyPanel.tsx: 已注入 import/替换 token.icon" -ForegroundColor Green }
  else{ Write-Host "  [ok] MyPanel.tsx: 无需修改（已是 tokenIconSrc）" -ForegroundColor Green }
} else {
  Write-Host "  [warn] 未找到 features/account/MyPanel.tsx（已跳过）" -ForegroundColor Yellow
}

# 可选：确保 SwapPanel 也能用 tokenIconSrc（若文件存在）
$swapPanel = Join-Path (Get-Location).Path "features\swap\SwapPanel.tsx"
if(Test-Path $swapPanel){
  $s = Get-Content $swapPanel -Raw -Encoding UTF8
  $needImport = $s -match 'tokenIconSrc\(' -and $s -notmatch '\btokenIconSrc\b.+from\s*"(?:@/)?lib/tokens"'
  if($needImport){
    # 若已有从 lib/tokens 的 import，把 tokenIconSrc 加进去；否则新增一行 import
    if($s -match 'import\s*{\s*([^}]*?)\s*}\s*from\s*"(?:@/)?lib/tokens"'){
      if($s -notmatch '\btokenIconSrc\b'){
        $s = $s -replace 'import\s*{\s*([^}]*?)\s*}\s*from\s*"(?:@/)?lib/tokens"',
                         'import { $1, tokenIconSrc } from "@/lib/tokens"'
      }
    } else {
      if($s -match 'import .+'){
        $s = $s -replace '(import[^\n]+\n)+', { param($m) $m.Value + 'import { tokenIconSrc } from "@/lib/tokens";' + "`r`n" }
      } else {
        $s = 'import { tokenIconSrc } from "@/lib/tokens";' + "`r`n" + $s
      }
    }
    SaveUtf8Bom $swapPanel $s
    Write-Host "  [ok] SwapPanel.tsx: 已注入 tokenIconSrc import" -ForegroundColor Green
  } else {
    Write-Host "  [ok] SwapPanel.tsx: 无需修改" -ForegroundColor Green
  }
}

# TypeScript 验证
Write-Host "`n== TypeScript check ==" -ForegroundColor Yellow
try{
  pnpm exec tsc -p tsconfig.json --noEmit
  if($LASTEXITCODE -eq 0){
    Write-Host "  [ok] tsc passed" -ForegroundColor Green
  }else{
    Write-Host "  [fail] tsc exit $LASTEXITCODE（把报错贴出来我继续补丁）" -ForegroundColor Red
  }
}catch{
  Write-Host "  [warn] 无法运行 tsc：$($_.Exception.Message)" -ForegroundColor Yellow
}
param(
  [switch]$Fix  # 预留：需要自动修复可加 -Fix 运行（当前版本只诊断不改文件）
)

# -------- 基础工具 --------
function Add-Log([string]$text){
  $text | Out-File -FilePath $script:Log -Append -Encoding utf8
  Write-Host $text
}
function OK([string]$t){ Write-Host ("  [OK]   " + $t) -ForegroundColor Green; Add-Log ("[OK] " + $t) }
function WARN([string]$t){ Write-Host ("  [WARN] " + $t) -ForegroundColor Yellow; Add-Log ("[WARN] " + $t) }
function FAIL([string]$t){ Write-Host ("  [FAIL] " + $t) -ForegroundColor Red; Add-Log ("[FAIL] " + $t) }

# 找可执行文件：优先 node_modules\.bin，其次 PATH
function Get-BinPath([string]$tool){
  $local = Join-Path (Get-Location) ("node_modules\.bin\{0}.cmd" -f $tool)
  if(Test-Path $local){ return $local }
  $cmd = Get-Command $tool -ErrorAction SilentlyContinue
  if($cmd){ return $cmd.Source }
  return $null
}

# 执行命令，捕获输出与退出码（兼容 PS5）
function Exec([string]$exe, [string[]]$args){
  $out = & $exe @args 2>&1
  $code = $LASTEXITCODE
  if($null -eq $code){ $code = 0 }
  return @{ Exit=$code; Out=($out -join "`r`n") }
}

# 读/写 JSON（utf8 无 BOM）
function Read-Json([string]$path){
  if(!(Test-Path $path)){ return $null }
  return (Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json)
}
function Write-Json([object]$obj, [string]$path){
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($path, ($obj | ConvertTo-Json -Depth 64), $utf8NoBom)
}

# 递归 grep
function Grep([string]$pattern, [string]$label, [string[]]$paths){
  $found = $false
  foreach($p in $paths){
    if(!(Test-Path $p)){ continue }
    $matches = Select-String -Path (Join-Path $p "*") -Pattern $pattern -AllMatches -Encoding UTF8 -ErrorAction SilentlyContinue -Recurse
    if($matches){
      $found = $true
      Write-Host (">> " + $label) -ForegroundColor Cyan
      foreach($m in $matches){
        $line = $m.Line
        if($line.Length -gt 160){ $line = $line.Substring(0,160) + " ..." }
        $msg = ("  {0}:{1}  {2}" -f $m.Path.Replace((Get-Location).Path + "\",""), $m.LineNumber, $line)
        $msg | Out-File -FilePath $script:Log -Append -Encoding utf8
        Write-Host $msg
      }
    }
  }
  if(-not $found){ OK ($label + ": none") }
}

# -------- 开始 --------
$ts = Get-Date -Format yyyyMMdd-HHmmss
$script:Log = Join-Path (Get-Location) ("diagnose-{0}.log" -f $ts)
"" | Out-File -FilePath $script:Log -Encoding utf8  # 清空/创建

# 扫描哪些目录
$ScanDirs = @("app","components","features","lib","contracts","tests","pages","src") | Where-Object { Test-Path $_ }

Write-Host "=== Env ===" -ForegroundColor Magenta
$node = Get-BinPath "node"
$pnpm = Get-BinPath "pnpm"
if($node){ OK "node found: $node" } else { WARN "node not found (TypeScript/ESLint/Vitest 可能跳过)" }
if($pnpm){ OK "pnpm found: $pnpm" } else { WARN "pnpm not found（将尝试直接使用本地 node_modules\.bin）" }

# tsconfig.exclude 检查备份目录是否排除
$tscfg = Read-Json "tsconfig.json"
if($tscfg -and ($tscfg.compilerOptions -or $true)){
  $need = @(".next","backup-*","backup-*/**/*","patch-backup-*","patch-backup-*/**/*","fix-bak-*","quickfix-bak-*")
  if(-not $tscfg.exclude){ $tscfg | Add-Member -NotePropertyName exclude -NotePropertyValue @() }
  $set = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
  foreach($e in $tscfg.exclude){ if($e){ [void]$set.Add($e) } }
  $added = @()
  foreach($e in $need){ if(-not $set.Contains($e)){ [void]$set.Add($e); $added += $e } }
  if($added.Count -gt 0){
    if($Fix){ $tscfg.exclude = @($set); Write-Json $tscfg "tsconfig.json"; OK ("tsconfig.exclude 已更新: " + ($added -join ", ")) }
    else { OK "tsconfig.exclude OK（或可 -Fix 自动写入缺失项）" }
  } else { OK "tsconfig.exclude OK" }
} else {
  WARN "未读取到 tsconfig.json（跳过 exclude 检查）"
}

Write-Host "`n=== Source scan (hotspots) ===" -ForegroundColor Magenta
# 1) WalletConnect 残留
Grep 'walletConnect\s*\(' 'WalletConnect usage' $ScanDirs
# 2) 旧版 @wagmi/core
Grep '@wagmi/core' 'Legacy @wagmi/core import' $ScanDirs
# 3) router.push(href) 未加 typed Route
Grep 'router\.push\(\s*href\s*\)' 'router.push(href) without typed Route' $ScanDirs
# 4) wagmi v2 不支持 watch:true 的用法
Grep 'useBalance\(\s*\{[^\}]*watch\s*:\s*true' 'useBalance({ ..., watch:true }) - wagmi v2 不支持' $ScanDirs
# 5) tokenIconSrc helper
Grep 'tokenIconSrc\(' 'tokenIconSrc helper usage' $ScanDirs
# 6) 粗略检查乱码（常见“锛”“闂”等）
Grep '[\u9501\u95f7\u93e1\u93a7\u93b5\u947f\u93fe\u94a5\u949f]' 'TSX 乱码片段(可能的编码污染)' $ScanDirs

Write-Host "`n=== TypeScript ===" -ForegroundColor Magenta
# 优先 pnpm exec tsc；否则直接 tsc
$tscArgs = @("exec","tsc","-p","tsconfig.json","--noEmit")
if($pnpm){
  $r = Exec $pnpm $tscArgs
} else {
  $tsc = Get-BinPath "tsc"
  if($tsc){ $r = Exec $tsc @("-p","tsconfig.json","--noEmit") }
  else { $r = @{ Exit=127; Out="tsc not found" } }
}
Add-Log $r.Out
if($r.Exit -eq 0){ OK "TypeScript passed" } else { FAIL ("TypeScript failed (exit {0})" -f $r.Exit) }

Write-Host "`n=== ESLint ===" -ForegroundColor Magenta
$eslintTargets = @($ScanDirs)
if($pnpm){
  $r = Exec $pnpm @("exec","eslint","--ext",".ts,.tsx") + $eslintTargets
} else {
  $eslint = Get-BinPath "eslint"
  if($eslint){ $r = Exec $eslint @("--ext",".ts,.tsx") + $eslintTargets }
  else { $r = @{ Exit=127; Out="eslint not found" } }
}
Add-Log $r.Out
if($r.Exit -eq 0){ OK "ESLint passed" } else { FAIL ("ESLint failed (exit {0})" -f $r.Exit) }

Write-Host "`n=== Vitest ===" -ForegroundColor Magenta
if($pnpm){
  $r = Exec $pnpm @("exec","vitest","run","--reporter=dot")
} else {
  $vit = Get-BinPath "vitest"
  if($vit){ $r = Exec $vit @("run","--reporter=dot") }
  else { $r = @{ Exit=127; Out="vitest not found" } }
}
Add-Log $r.Out
if($r.Exit -eq 0){ OK "Vitest passed" } else { FAIL ("Vitest failed (exit {0})" -f $r.Exit) }

Write-Host "`n=== Summary ===" -ForegroundColor Magenta
Add-Log "诊断完成。"
Write-Host ("`nLog file: " + $script:Log) -ForegroundColor Cyan
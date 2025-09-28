$ErrorActionPreference = "Stop"
$root = (Get-Location).Path
$stamp = Get-Date -Format yyyyMMdd-HHmmss
$bakRoot = "D:\RStoken_backups\$stamp"
New-Item -ItemType Directory -Force -Path $bakRoot | Out-Null

function SaveJson([string]$path, $obj){
  $enc = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($path, ($obj | ConvertTo-Json -Depth 50), $enc)
}

# 1) 更新 tsconfig.exclude
$tsPath = Join-Path $root 'tsconfig.json'
if (Test-Path $tsPath) {
  Copy-Item $tsPath (Join-Path $bakRoot 'tsconfig.json')
  $ts = Get-Content $tsPath -Raw | ConvertFrom-Json
  if (-not $ts.PSObject.Properties.Name.Contains('exclude') -or $null -eq $ts.exclude) {
    $ts | Add-Member -NotePropertyName exclude -NotePropertyValue @()
  }
  $patterns = @(
    ".next","node_modules",
    "backup-*","backup-*/**/*",
    "patch-backup-*","patch-backup-*/**/*",
    "quickfix-bak-*","quickfix-bak-*/**/*",
    "fix-bak-*","fix-bak-*/**/*"
  )
  $set = New-Object System.Collections.Generic.HashSet[string]([StringComparer]::OrdinalIgnoreCase)
  foreach ($e in $ts.exclude) { if ($e) { [void]$set.Add($e) } }
  foreach ($p in $patterns) { [void]$set.Add($p) }
  $ts.exclude = @($set)
  SaveJson $tsPath $ts
  Write-Host "[ok] tsconfig.json exclude updated"
} else {
  Write-Host "[warn] tsconfig.json not found"
}

# 2) 把所有备份目录从项目根移走（最彻底）
$rx = '^(backup-|patch-backup-|quickfix-bak-|fix-bak-)'
$dirs = Get-ChildItem $root -Directory | Where-Object { $_.Name -match $rx }
if ($dirs) {
  foreach ($d in $dirs) {
    $dstDir = Join-Path $bakRoot $d.Name
    Move-Item $d.FullName $dstDir -Force
  }
  Write-Host ("[ok] moved " + $dirs.Count + " backup folders to " + $bakRoot)
} else {
  Write-Host "[ok] no backup folders to move"
}

# 3) 清缓存
Remove-Item -Recurse -Force "$root\**\*.tsbuildinfo" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$root\.next\cache" -ErrorAction SilentlyContinue

# 4) 跑 tsc
Write-Host "`nRunning tsc..."
& pnpm exec tsc -p tsconfig.json --noEmit
$code = $LASTEXITCODE
if ($code -eq 0) { Write-Host "[ok] TypeScript passed" }
else { Write-Host "[FAIL] tsc exit $code" }
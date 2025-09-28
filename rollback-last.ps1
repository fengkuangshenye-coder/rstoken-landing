# rollback-last.ps1 —— 一键回到最近检查点（先自动备份当前）
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Root) { $Root = "." }
Set-Location $Root

function New-ContentZip($src, $dst) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  if (Test-Path $dst) { Remove-Item $dst -Force }
  $base = Split-Path $src -Leaf
  $tmp = "$dst.__tmp__"
  if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
  Copy-Item $src $tmp -Recurse
  Remove-Item -Recurse -Force (Join-Path $tmp "$base\node_modules"), (Join-Path $tmp "$base\.next"), (Join-Path $tmp "$base\.git") -ErrorAction SilentlyContinue
  [System.IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $tmp $base), $dst)
  Remove-Item -Recurse -Force $tmp
}

# 目录与节点
$shots = Join-Path $Root ".snapshots"
New-Item -ItemType Directory -Force -Path $shots | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

# 0) 终止 Dev
taskkill /F /IM node.exe 2>$null | Out-Null

# 1) 备份当前工作区（以防回滚后想再回到现在）
$backup = Join-Path $shots "pre-rollback-$stamp.zip"
New-ContentZip $Root $backup
Write-Host "📦 Current state backed up to:"
Write-Host "   - $backup"

# 2) 优先用 Git 标签回滚
$useGit = Test-Path (Join-Path $Root ".git")
$rolled = $false
if ($useGit) {
  try {
    $tags = git tag --list "checkpoint-*" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" } | Sort-Object
    if ($tags.Count -gt 0) {
      $lastTag = $tags[-1]
      Write-Host "⏪ Git hard reset to tag: $lastTag"
      git reset --hard $lastTag | Out-Null
      $rolled = $true
    } else {
      Write-Host "• 找不到 checkpoint-* 标签，转用 ZIP 回滚方案"
    }
  } catch {
    Write-Host "• Git 回滚失败（$($_.Exception.Message)），转用 ZIP 回滚方案"
  }
}

# 3) 若无 Git 标签，则用最新 ZIP 快照回滚（原地覆盖）
if (-not $rolled) {
  $zip = Get-ChildItem $shots -Filter "RStoken-1.5-*.zip" | Sort-Object Name | Select-Object -Last 1
  if (-not $zip) {
    Write-Host "❌ 没有找到任何 ZIP 检查点（.snapshots\\RStoken-1.5-*.zip）。无法回滚。"
    Write-Host "   请先运行 .\\save-checkpoint.ps1 创建检查点。"
    exit 1
  }
  Write-Host "⏪ Restoring from ZIP: $($zip.FullName)"
  $tmpRestore = Join-Path $shots "_restore_$stamp"
  New-Item -ItemType Directory -Force -Path $tmpRestore | Out-Null
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory($zip.FullName, $tmpRestore)

  # 将解压内容覆盖回项目根目录
  $base = Split-Path $Root -Leaf
  $srcDir = Join-Path $tmpRestore $base
  if (-not (Test-Path $srcDir)) { $srcDir = $tmpRestore } # 兼容意外结构
  Get-ChildItem $srcDir -Recurse | ForEach-Object {
    $rel = $_.FullName.Substring($srcDir.Length).TrimStart('\')
    $dest = Join-Path $Root $rel
    if ($_.PSIsContainer) {
      New-Item -ItemType Directory -Force -Path $dest | Out-Null
    } else {
      Copy-Item $_.FullName $dest -Force
    }
  }
  Remove-Item -Recurse -Force $tmpRestore
  $rolled = $true
}

if (-not $rolled) {
  Write-Host "❌ 未能回滚。"
  exit 1
}

# 4) 安装依赖并重启 dev（便于立即验证）
Write-Host "🔧 Installing deps & starting dev..."
try { corepack enable } catch {}
try { corepack prepare pnpm@latest --activate } catch {}
pnpm install
pnpm dev

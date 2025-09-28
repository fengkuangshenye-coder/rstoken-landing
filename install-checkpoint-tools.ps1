# RStoken v1.5 — 超级一键安装：保存/回滚检查点 + 桌面快捷方式
# 作用：
# 1) 写入 save-checkpoint.ps1 / rollback-last.ps1 / create-shortcuts.ps1
# 2) 自动创建桌面快捷方式（Save / Rollback）
# 3) 所有动作安全、可回滚，脚本可重复执行（幂等）

$ErrorActionPreference = "Stop"

# === 如需自定义项目路径，这里改 ===
$ProjectPath = 'D:\RStoken5.1.2'

if (-not (Test-Path $ProjectPath)) {
  throw "项目目录不存在：$ProjectPath"
}
Set-Location $ProjectPath

# ---------------------------
# 内容：save-checkpoint.ps1
# ---------------------------
$saveCheckpoint = @'
# save-checkpoint.ps1 —— 保存检查点（Git + Tag + ZIP）
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Root) { $Root = "." }
Set-Location $Root

# 准备 .snapshots 目录
$shots = Join-Path $Root ".snapshots"
New-Item -ItemType Directory -Force -Path $shots | Out-Null

# Git 初始化（如果尚未 init）
if (-not (Test-Path (Join-Path $Root ".git"))) {
  git init | Out-Null
  if (-not (Test-Path (Join-Path $Root ".gitignore"))) {
    @"
node_modules
.next
out
.env*
.DS_Store
"@ | Out-File -Encoding utf8 -FilePath (Join-Path $Root ".gitignore")
  }
}

# 提交与打标签
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$tag = "checkpoint-$stamp"
git add -A
$hasChanges = (git status --porcelain)
if ($hasChanges) { git commit -m "checkpoint: $stamp" | Out-Null } else { Write-Host "• 工作区无改动，基于 HEAD 打标签" }
git tag -a $tag -m "checkpoint $stamp" | Out-Null

# 制作 ZIP 快照（排除 node_modules/.next/.git）
Add-Type -AssemblyName System.IO.Compression.FileSystem
$base = Split-Path $Root -Leaf
$tmp = Join-Path $shots "_tmp_$stamp"
$zip = Join-Path $shots "RStoken-1.5-$stamp.zip"

Copy-Item $Root $tmp -Recurse
Remove-Item -Recurse -Force (Join-Path $tmp "$base\node_modules"), (Join-Path $tmp "$base\.next"), (Join-Path $tmp "$base\.git") -ErrorAction SilentlyContinue
[System.IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $tmp $base), $zip)
Remove-Item -Recurse -Force $tmp

Write-Host "✅ Checkpoint saved:"
Write-Host "   - Git tag: $tag"
Write-Host "   - Zip: $zip"
'@

# ---------------------------
# 内容：rollback-last.ps1
# ---------------------------
$rollbackLast = @'
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
'@

# ---------------------------
# 内容：create-shortcuts.ps1
# ---------------------------
$createShortcuts = @'
# create-shortcuts.ps1 —— 创建桌面快捷方式（Save / Rollback）
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Root) { $Root = "." }

$desktop = [Environment]::GetFolderPath('Desktop')
$psExe = (Get-Command powershell.exe).Source

$items = @(
  @{ name='RStoken Save Checkpoint'; script='save-checkpoint.ps1'; desc='保存检查点（Git+Tag+ZIP）' },
  @{ name='RStoken Rollback to Last Checkpoint'; script='rollback-last.ps1'; desc='回到最近检查点（先备份当前）' }
)

$wsh = New-Object -ComObject WScript.Shell

foreach ($i in $items) {
  $lnkPath = Join-Path $desktop ($i.name + '.lnk')
  $scriptPath = Join-Path $Root $i.script

  if (-not (Test-Path $scriptPath)) {
    Write-Warning "找不到脚本：$scriptPath"
    continue
  }

  Unblock-File -Path $scriptPath -ErrorAction SilentlyContinue

  $s = $wsh.CreateShortcut($lnkPath)
  $s.TargetPath = $psExe
  $s.Arguments  = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
  $s.WorkingDirectory = $Root
  $s.IconLocation = "$psExe,0"
  $s.Description = "RStoken v1.5 - $($i.desc)"
  $s.Save()

  Write-Host "✔ 已创建快捷方式：$lnkPath"
}

Write-Host "完成。桌面有两个图标：Save Checkpoint / Rollback to Last Checkpoint。"
'@

# 写入三个脚本
Set-Content -Path (Join-Path $ProjectPath "save-checkpoint.ps1") -Encoding UTF8 -Value $saveCheckpoint
Set-Content -Path (Join-Path $ProjectPath "rollback-last.ps1") -Encoding UTF8 -Value $rollbackLast
Set-Content -Path (Join-Path $ProjectPath "create-shortcuts.ps1") -Encoding UTF8 -Value $createShortcuts

# 解除阻止标记（防止从网络复制导致的执行提示）
Unblock-File (Join-Path $ProjectPath "save-checkpoint.ps1") -ErrorAction SilentlyContinue
Unblock-File (Join-Path $ProjectPath "rollback-last.ps1") -ErrorAction SilentlyContinue
Unblock-File (Join-Path $ProjectPath "create-shortcuts.ps1") -ErrorAction SilentlyContinue

# 创建桌面快捷方式
Write-Host "🔗 正在创建桌面快捷方式..."
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ProjectPath "create-shortcuts.ps1")

Write-Host "`n✅ 安装完成："
Write-Host "   - $ProjectPath\save-checkpoint.ps1"
Write-Host "   - $ProjectPath\rollback-last.ps1"
Write-Host "   - 桌面快捷方式已创建（Save / Rollback）"

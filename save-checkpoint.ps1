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

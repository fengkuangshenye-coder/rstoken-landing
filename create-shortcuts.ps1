# create-shortcuts.ps1 — Create desktop shortcuts (Save / Rollback)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Root) { $Root = "." }

$desktop = [Environment]::GetFolderPath("Desktop")
$psExe   = (Get-Command powershell.exe).Source

$items = @(
  @{ name = "RStoken Save Checkpoint"; script = "save-checkpoint.ps1"; desc = "Save checkpoint (Git + Tag + ZIP)"; },
  @{ name = "RStoken Rollback to Last Checkpoint"; script = "rollback-last.ps1"; desc = "Rollback to last checkpoint (backup current first)"; }
)

$wsh = New-Object -ComObject WScript.Shell
foreach ($i in $items) {
  $lnkPath    = Join-Path $desktop ($i.name + ".lnk")
  $scriptPath = Join-Path $Root $i.script

  if (-not (Test-Path $scriptPath)) {
    Write-Warning ("Missing script: " + $scriptPath)
    continue
  }

  Unblock-File -Path $scriptPath -ErrorAction SilentlyContinue

  $s = $wsh.CreateShortcut($lnkPath)
  $s.TargetPath      = $psExe
  $s.Arguments       = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
  $s.WorkingDirectory= $Root
  $s.IconLocation    = "$psExe,0"
  $s.Description     = $i.desc
  $s.Save()

  Write-Host ("✔ Created shortcut: " + $lnkPath)
}

Write-Host "Done. Two shortcuts are now on your Desktop."
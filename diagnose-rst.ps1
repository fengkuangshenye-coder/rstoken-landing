param([switch]$Fix)

$ErrorActionPreference = "Continue"
function Section($t){ Write-Host "`n=== $t ===" }
function OK($m){ Write-Host "  [OK]  $m" -ForegroundColor Green }
function WARN($m){ Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function FAIL($m){ Write-Host "  [FAIL] $m" -ForegroundColor Red }

$root = (Get-Location).Path
$log  = Join-Path $root ("diagnose-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
"RST Diagnose Log $(Get-Date)" | Out-File -Encoding UTF8 $log

Section "Env check (node/pnpm/tsc/eslint/vitest)"
& node --version *> $null;                $hasNode   = ($LASTEXITCODE -eq 0)
& pnpm --version *> $null;                $hasPnpm   = ($LASTEXITCODE -eq 0)
if (-not $hasPnpm) { try { corepack enable *> $null; corepack prepare pnpm@latest --activate *> $null } catch {} ; & pnpm --version *> $null; $hasPnpm = ($LASTEXITCODE -eq 0) }
& pnpm exec tsc -v *> $null;              $hasTsc    = ($LASTEXITCODE -eq 0)
& pnpm exec eslint -v *> $null;           $hasEslint = ($LASTEXITCODE -eq 0)
& pnpm exec vitest --version *> $null;    $hasVitest = ($LASTEXITCODE -eq 0)
if($hasNode){OK "node ok"} else {FAIL "node not found"}
if($hasPnpm){OK "pnpm ok"} else {FAIL "pnpm not available"}
if($hasTsc){OK "tsc ok"} else {WARN "tsc not found"}
if($hasEslint){OK "eslint ok"} else {WARN "eslint not found"}
if($hasVitest){OK "vitest ok"} else {WARN "vitest not found"}

Section "tsconfig.json: exclude backup dirs"
$tsPath = Join-Path $root "tsconfig.json"
if (Test-Path $tsPath) {
  $ts = Get-Content $tsPath -Raw | ConvertFrom-Json
  if (-not $ts.PSObject.Properties.Name.Contains('exclude') -or $null -eq $ts.exclude) { $ts | Add-Member -NotePropertyName exclude -NotePropertyValue @() }
  $need = @(".next","node_modules","backup-*","backup-*/**/*","patch-backup-*","patch-backup-*/**/*")
  $set  = New-Object System.Collections.Generic.HashSet[string]([StringComparer]::OrdinalIgnoreCase)
  foreach($e in $ts.exclude){ if($e){[void]$set.Add($e)} }
  $added = @()
  foreach($e in $need){ if($set.Add($e)){ $added += $e } }
  if ($added.Count -gt 0) {
    if ($Fix) {
      $ts.exclude = @($set)
      $utf8 = New-Object System.Text.UTF8Encoding($false)
      [IO.File]::WriteAllText($tsPath, ($ts | ConvertTo-Json -Depth 20), $utf8)
      OK ("exclude updated: " + ($added -join ", "))
    } else {
      WARN ("should add to tsconfig.exclude: " + ($added -join ", ") + " (run with -Fix to auto-write)")
    }
  } else { OK "exclude already contains backup dirs" }
} else { WARN "tsconfig.json not found" }

function Run-Tool([string]$Title,[string]$Exe,[string[]]$CmdArgs){
  Section $Title
  Write-Host ("  > " + $Exe + " " + ($CmdArgs -join " "))
  & $Exe @CmdArgs 2>&1 | Tee-Object -FilePath $log -Append
  if($LASTEXITCODE -eq 0){ OK "$Title passed" } else { FAIL "$Title failed (exit $LASTEXITCODE)" }
  return $LASTEXITCODE
}

if($hasTsc -and (Test-Path $tsPath)){ Run-Tool "TypeScript check" "pnpm" @("exec","tsc","-p","tsconfig.json","--noEmit") | Out-Null } else { WARN "skip tsc" }
$eslintDirs=@(); foreach($d in @("app","components","features","lib","contracts","tests")){ if(Test-Path (Join-Path $root $d)){ $eslintDirs+=$d } }
if($hasEslint -and $eslintDirs.Count -gt 0){ Run-Tool ("ESLint "+($eslintDirs -join ",")) "pnpm" (@("exec","eslint","--ext",".ts,.tsx") + $eslintDirs) | Out-Null } elseif($hasEslint){ WARN "skip eslint (no dirs)" }
if($hasVitest){ Run-Tool "Vitest" "pnpm" @("exec","vitest","run","--reporter=dot") | Out-Null }

Section "Heuristics (common hotspots)"
$wcFound=$false; foreach($p in @("lib\wagmi.ts","lib\wagmi.tsx")){ $full=Join-Path $root $p; if(Test-Path $full){ if(Select-String -Path $full -Pattern "walletConnect\(" -Quiet){ $wcFound=$true } } }
if($wcFound){ WARN "walletConnect() detected; if wagmi v2 types mismatch, remove it or align versions." } else { OK "no walletConnect() hotspot found" }
$btm=Join-Path $root "components\layout\BottomTabs.tsx"
if(Test-Path $btm){
  $s=Get-Content $btm -Raw
  if($s -match 'router\.push\(\s*href\s*\)' -and $s -notmatch 'as Route'){ WARN "BottomTabs.tsx: router.push(href) -> router.push(href as Route)" } else { OK "BottomTabs.tsx typedRoutes ok" }
}

Write-Host ""
Write-Host ("Log file: "+$log)
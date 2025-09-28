# RStoken v1.5 – 完整性与缺失检测脚本
# 用法：在项目根目录执行： .\verify-rstoken-1.5.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Root) { $Root = "." }

function Read-Text($path) {
  if (-not (Test-Path $path)) { return $null }
  return Get-Content -Raw -Encoding UTF8 -ErrorAction SilentlyContinue $path
}

function Test-Patterns {
  param([string]$Content, [string[]]$Patterns)
  $missing = @()
  foreach ($p in $Patterns) {
    if ($null -eq $Content -or ($Content -notmatch $p)) { $missing += $p }
  }
  return $missing
}

function Test-Json {
  param([string]$Path)
  try { return ConvertFrom-Json (Get-Content -Raw -Encoding UTF8 $Path) } catch { return $null }
}

# ========== 期望文件清单 ==========
$expected = @(
  "package.json","next.config.mjs","tsconfig.json","next-env.d.ts",
  "postcss.config.mjs","tailwind.config.ts","app/globals.css",".eslintrc.cjs",".prettierrc",".editorconfig",
  "vitest.config.ts","tests/setup.ts","tests/utils.test.ts",".nvmrc",".env.example","README.md",
  "app/layout.tsx","app/page.tsx","app/swap/page.tsx","app/portfolio/page.tsx","app/providers.tsx","app/api/quote/route.ts",
  "components/layout/GlobalStyles.tsx","components/layout/TopNav.tsx","components/layout/BottomTabs.tsx",
  "components/layout/ScrollProgress.tsx","components/layout/Starfield.tsx",
  "components/ui/Button.tsx","components/ui/Card.tsx","components/ui/Input.tsx","components/ui/Badge.tsx",
  "components/wallet/ConnectButtons.tsx","components/wallet/ChainGuard.tsx",
  "hooks/useLocalStorage.ts","hooks/useScrollProgress.ts","hooks/useBalances.ts",
  "lib/format.ts","lib/math.ts","lib/tokens.ts","lib/wagmi.ts","lib/erc20.ts",
  "features/oracle/OraclePreview.tsx","features/tokenomics/TokenomicsCard.tsx",
  "features/roadmap/RoadmapCard.tsx","features/swap/SwapPanel.tsx","features/portfolio/PortfolioCard.tsx",
  "data/tokenomics.json","contracts/addresses.ts","contracts/rstoken.json",".gitignore"
)

# ========== 关键文件的“必要片段”规则 ==========
$rules = @(
  @{ path="package.json"; must=@('"name"\s*:\s*"rstoken-dapp-1.5"', '"next"\s*:\s*"\^14', '"wagmi"') },
  @{ path="tsconfig.json"; must=@('"paths"\s*:\s*{\s*"@/\*"\s*:\s*\["\./\*"\]') },
  @{ path="next.config.mjs"; must=@('reactStrictMode\s*:\s*true') },
  @{ path="postcss.config.mjs"; must=@('tailwindcss') },
  @{ path="tailwind.config.ts"; must=@('content:\s*\[', 'features/\*\*/\*\.{js,ts,jsx,tsx}') },
  @{ path="app/layout.tsx"; must=@('<Providers>', '<TopNav />', '<BottomTabs />', '<Starfield />') },
  @{ path="app/page.tsx"; must=@('OraclePreview', 'TokenomicsCard', '全球人口', 'RStoken（人生币）') },
  @{ path="app/swap/page.tsx"; must=@('SwapPanel', 'RoadmapCard') },
  @{ path="app/providers.tsx"; must=@('WagmiProvider', 'QueryClientProvider') },
  @{ path="app/api/quote/route.ts"; must=@('export\s+async\s+function\s+GET', 'amountOut', 'minOut') },
  @{ path="components/layout/TopNav.tsx"; must=@('ConnectButtons') },
  @{ path="components/layout/BottomTabs.tsx"; must=@('usePathname', 'router\.push') },
  @{ path="components/ui/Button.tsx"; must=@('export\s+function\s+Button') },
  @{ path="features/swap/SwapPanel.tsx"; must=@('export\s+default\s+function\s+SwapPanel', 'mockQuote', 'calcMinReceived', 'TokenRow', 'Quick') },
  @{ path="features/tokenomics/TokenomicsCard.tsx"; must=@('Tokenomics', '<svg', 'rotate\(-90 100 100\)') },
  @{ path="lib/wagmi.ts"; must=@('createConfig', 'bsc', 'injected', 'walletConnect') },
  @{ path="contracts/addresses.ts"; must=@('RSTOKEN', '56', '97') }
)

$results = @()
$missingFiles = @()
$emptyFiles = @()
$patternFails = @()

# 1) 存在性 & 非空
foreach ($rel in $expected) {
  $full = Join-Path $Root $rel
  $exists = Test-Path $full
  $size = $exists ? (Get-Item $full).Length : 0
  if (-not $exists) { $missingFiles += $rel; continue }
  if ($size -eq 0) { $emptyFiles += $rel }

  # 2) 关键片段匹配
  $rule = $rules | Where-Object { $_.path -eq $rel }
  if ($rule) {
    $content = Read-Text $full
    $miss = Test-Patterns -Content $content -Patterns $rule.must
    if ($miss.Count -gt 0) {
      $patternFails += [PSCustomObject]@{ File=$rel; Missing=$miss -join "; " }
    }
  }

  $results += [PSCustomObject]@{
    File = $rel
    Exists = $exists
    Bytes = $size
  }
}

# 3) 结构化检查：tokenomics.json / rstoken.json
$tokPath = Join-Path $Root "data/tokenomics.json"
$tok = Test-Json $tokPath
$tokOk = $false
if ($tok -ne $null -and $tok.Count -eq 5 -and ($tok | Where-Object { $_.label -match "社区" -and $_.value -eq 50 })) { $tokOk = $true }

$abiPath = Join-Path $Root "contracts/rstoken.json"
$abi = Test-Json $abiPath
$abiOk = $false
if ($abi -ne $null -and ($abi | Where-Object { $_.name -eq "approve" }) -and ($abi | Where-Object { $_.name -eq "balanceOf" })) { $abiOk = $true }

# 输出报告
Write-Host ""
Write-Host "==== RStoken v1.5 完整性报告 ====" -ForegroundColor Cyan
"{0,-50} {1,8} {2,8}" -f "文件", "存在", "字节" | Write-Host
$results | Sort-Object File | ForEach-Object {
  "{0,-50} {1,8} {2,8}" -f $_.File, ($(if($_.Exists){"YES"}else{"NO"})), $_.Bytes | Write-Host
}

Write-Host ""
Write-Host "--- 缺失文件 ---" -ForegroundColor Yellow
if ($missingFiles.Count -eq 0) { Write-Host "  (无)" } else { $missingFiles | ForEach-Object { "  $_" | Write-Host } }

Write-Host ""
Write-Host "--- 空文件(0字节) ---" -ForegroundColor Yellow
if ($emptyFiles.Count -eq 0) { Write-Host "  (无)" } else { $emptyFiles | ForEach-Object { "  $_" | Write-Host } }

Write-Host ""
Write-Host "--- 关键片段缺失 ---" -ForegroundColor Yellow
if ($patternFails.Count -eq 0) { Write-Host "  (无)" } else { $patternFails | ForEach-Object { "  $($_.File): $($_.Missing)" | Write-Host } }

Write-Host ""
Write-Host "--- 结构化校验 ---" -ForegroundColor Cyan
Write-Host ("tokenomics.json 解析：" + ($(if($tok){"OK"}else{"FAIL"})))
Write-Host ("tokenomics.json 条目/分配检查：" + ($(if($tokOk){"OK"}else{"FAIL"})))
Write-Host ("rstoken.json ABI 解析：" + ($(if($abi){"OK"}else{"FAIL"})))
Write-Host ("rstoken.json 必备方法(approve/balanceOf)：" + ($(if($abiOk){"OK"}else{"FAIL"})))

# 建议
Write-Host ""
Write-Host "提示：" -ForegroundColor Cyan
Write-Host "1) 如有“缺失/空文件/关键片段缺失”，我可以发送修复脚本补齐对应文件。"
Write-Host "2) 也可直接重新运行 bootstrap 脚本覆盖写入（建议先 git 提交做快照）。"

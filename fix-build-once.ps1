# RStoken v1.5 — 一键修复构建缺依赖/RN包问题（安全备份版）
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Root) { $Root = "." }

function Backup-File {
  param([string]$Path, [string]$Bucket)
  if (Test-Path $Path) {
    $rel = [IO.Path]::GetRelativePath($Root, $Path)
    $dst = Join-Path $Bucket $rel
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    Copy-Item $Path $dst -Force
  }
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$bk = Join-Path $Root "backup-$stamp"
New-Item -ItemType Directory -Force -Path $bk | Out-Null

Write-Host "📦 Backup folder: $bk"

# 1) 备份可能要改的文件
$toBackup = @(
  (Join-Path $Root "next.config.mjs"),
  (Join-Path $Root "features\tokenomics\TokenomicsCard.tsx"),
  (Join-Path $Root "lib\wagmi.ts")
)
$toBackup | ForEach-Object { Backup-File -Path $_ -Bucket $bk }

# 2) 写入 next.config.mjs（加入 webpack alias -> false）
$nextCfg = @'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  experimental: { typedRoutes: true },
  webpack: (config) => {
    config.resolve = config.resolve || {};
    config.resolve.alias = {
      ...(config.resolve.alias || {}),
      // 这些仅在原生或 Node CLI 下使用，Web 端屏蔽掉即可
      "@react-native-async-storage/async-storage": false,
      "pino-pretty": false
    };
    return config;
  }
};
export default nextConfig;
'@
Set-Content -Path (Join-Path $Root "next.config.mjs") -Encoding UTF8 -Value $nextCfg
Write-Host "✔ Patched next.config.mjs (alias RN/CLI-only deps → false)"

# 3) 如存在 JSON import 断言，则自动去掉（保持兼容）
$tokenomicsPath = Join-Path $Root "features\tokenomics\TokenomicsCard.tsx"
if (Test-Path $tokenomicsPath) {
  $content = Get-Content -Raw -Encoding UTF8 $tokenomicsPath
  if ($content -match 'assert\s*{\s*type\s*:\s*"json"\s*}') {
    $content = $content -replace 'import\s+data\s+from\s+"@/data/tokenomics\.json"\s+assert\s+{\s*type\s*:\s*"json"\s*}\s*;',
                                  'import data from "@/data/tokenomics.json";'
    Set-Content -Path $tokenomicsPath -Encoding UTF8 -Value $content
    Write-Host "✔ Removed JSON import assertion in TokenomicsCard.tsx"
  } else {
    Write-Host "• TokenomicsCard.tsx has no JSON import assertions, skip."
  }
}

# 4) 打开构建脚本 & 安装 zod@^3（消 peer 依赖告警）
Write-Host "🔧 Enabling pnpm scripts & adding zod peer..."
try { corepack enable } catch {}
try { corepack prepare pnpm@latest --activate } catch {}
pnpm config set ignore-scripts false | Out-Null
pnpm add -D zod@^3.23.8

# 5) 清理并重启 dev
Write-Host "🧹 Cleaning cache and restarting dev server..."
taskkill /F /IM node.exe 2>$null | Out-Null
Remove-Item -Recurse -Force (Join-Path $Root ".next") -ErrorAction SilentlyContinue

pnpm install
pnpm dev

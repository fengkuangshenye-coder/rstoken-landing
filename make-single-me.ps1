param([Parameter(Mandatory=$true)][string]$ProjectRoot)

function J([string]$a,[string]$b){ Join-Path -Path $a -ChildPath $b }
function Ensure-Dir([string]$p){ if(-not(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }

# 1) 删掉 App Router 的 /me，避免冲突
$pathsToRemove = @(
  J $ProjectRoot 'app\me\page.tsx',
  J $ProjectRoot 'src\app\me\page.tsx'
)
foreach($p in $pathsToRemove){ if(Test-Path $p){ Remove-Item -Force $p } }

# 2) 确保功能组件存在（src/features/referral/MePage.tsx）
$featDir = J $ProjectRoot 'src\features\referral'
Ensure-Dir $featDir
$meComp = J $featDir 'MePage.tsx'
if(-not (Test-Path $meComp)){
$meCompSrc = @'
import * as React from "react";
export default function MePage(){
  return (
    <div style={{padding:"24px",color:"#fff"}}>
      <div style={{fontSize:12,display:"inline-block",padding:"2px 6px",border:"1px solid #34d399",background:"rgba(52,211,153,0.2)",borderRadius:6,marginBottom:8}}>
        Me v2 ✅
      </div>
      <h1 style={{fontSize:20,margin:"12px 0"}}>我的</h1>
      <p style={{opacity:.7}}>这是占位组件：说明 /me 已命中新页面。你也可以把我换成前面那份完整版 MePage。</p>
    </div>
  );
}
'@
Set-Content -Path $meComp -Value $meCompSrc -Encoding UTF8
}

# 3) 选择 Pages Router 入口位置：优先 pages/，否则 src/pages/，都没有就创建 pages/
$rootPages = J $ProjectRoot 'pages'
$srcPages  = J $ProjectRoot 'src\pages'
$targetDir = $rootPages
if(-not (Test-Path $rootPages) -and (Test-Path $srcPages)){ $targetDir = $srcPages }
Ensure-Dir $targetDir

# 删除可能的重复入口（/me/index.tsx）
$dup = J $targetDir 'me\index.tsx'
if(Test-Path $dup){ Remove-Item -Force $dup }

# 4) 写入唯一的 /me 页面（动态导入，避免 SSR 报错）
$meRoute = J $targetDir 'me.tsx'
$importPath = ($targetDir -like "*src\pages*") ? "../features/referral/MePage" : "../src/features/referral/MePage"
$meRouteSrc = @"
import dynamic from "next/dynamic";
const Me = dynamic(() => import("$importPath"), { ssr: false });
export default Me;
"@
Set-Content -Path $meRoute -Value $meRouteSrc -Encoding UTF8

# 5) 提示一下当前实际使用的入口
"OK: wrote route at $meRoute"

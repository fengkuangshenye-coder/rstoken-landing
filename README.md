# RStoken v1.5 DApp

- Next.js (App Router) + TypeScript
- 首页：Hero + 预言机演示 + Tokenomics
- 闪兑页：SwapPanel + 路线图（右列 sticky）
- 资产页：本地余额示意

## 开发
pnpm i
Copy-Item .env.example .env.local
pnpm dev

## 构建
pnpm build && pnpm start

## 质量
pnpm typecheck && pnpm lint && pnpm test

'use client';

import * as React from "react";
import { useAccount, useBalance, useChainId } from "wagmi";
import type { Address } from "./referral";
import { TOKENS } from "../../lib/tokens";
import {
  captureReferrerFromURL, getMyInviteLink, setMeAddress,
  getMyRewards, withdrawMyRewards, recordContributionUSDT, TOTAL_RATE
} from "./referral";

/** ---------- 小组件 ---------- */
function Badge({ children, tone = "emerald" }: { children: React.ReactNode; tone?: "emerald"|"indigo"|"yellow"|"red" }) {
  const border = { emerald:"#059669", indigo:"#4f46e5", yellow:"#ca8a04", red:"#ef4444" }[tone];
  const bg = {
    emerald:"rgba(16,185,129,.14)",
    indigo:"rgba(79,70,229,.14)",
    yellow:"rgba(202,138,4,.14)",
    red:"rgba(239,68,68,.14)"
  }[tone];
  return (
    <span className="inline-block text-xs px-2 py-1 rounded" style={{border:`1px solid ${border}`, background:bg}}>
      {children}
    </span>
  );
}

function IconDot({ grad = "to right, #a78bfa, #60a5fa" }: { grad?: string }) {
  return <span className="inline-block w-3 h-3 rounded-full" style={{background:`linear-gradient(${grad})`}} />;
}

function Row({label, value, loading, grad}:{label:string; value:string; loading?:boolean; grad?:string;}){
  return (
    <div className="row">
      <div className="flex items-center gap-3">
        <IconDot grad={grad}/>
        <div className="font-medium">{label}</div>
      </div>
      <div className="opacity-90">
        {loading ? <div className="skeleton w-16 h-4" /> : value}
      </div>
    </div>
  );
}

/** ---------- 余额查询 ---------- */
function useTokenBalances(address?: Address) {
  const chainId = useChainId();
  const cfg = TOKENS[chainId];
  const enabled = !!address && !!cfg;

  const bnb = useBalance({ address, chainId,     query: { enabled } });
  const usdt= useBalance({ address, chainId, token: cfg?.USDT?.address as Address, query:{ enabled: enabled && !!cfg?.USDT?.address }});
  const rst = useBalance({ address, chainId, token: cfg?.RST?.address  as Address, query:{ enabled: enabled && !!cfg?.RST?.address  }});

  const nativeSymbol = cfg?.NATIVE.symbol ?? "原生";
  return { cfg, nativeSymbol, bnb, usdt, rst };
}

/** ---------- 主页面 ---------- */
export default function MePage() {
  const { address, isConnected, status } = useAccount();
  const chainId = useChainId();
  const [copied, setCopied] = React.useState(false);

  // 连接后：记录自己地址 & 捕获 URL 中上级
  React.useEffect(() => {
    if (!isConnected || !address) return;
    setMeAddress(address as Address);
    captureReferrerFromURL(address as Address);
  }, [isConnected, address]);

  const { cfg, nativeSymbol, bnb, usdt, rst } = useTokenBalances(address as Address);
  const inviteLink = isConnected && address ? getMyInviteLink(address as Address) : "";
  const rewards = getMyRewards(address as Address);

  // 诊断信息（仅用于底部 debug）
  const reasons: string[] = [];
  if (!isConnected) reasons.push("未连接钱包：点击右上角“连接钱包”。");
  if (!cfg) reasons.push(`当前网络 ${chainId} 暂不受支持：请切换到 BSC 主网(56) / 测试网(97)，或在 Wagmi 配置中添加该网络 RPC。`);
  if (cfg && !cfg.RST?.address) reasons.push("RST 合约地址未设置：请在 .env.local 填写 NEXT_PUBLIC_RSTOKEN_ADDRESS_* 后重启。");
  if (cfg && cfg.USDT && cfg.USDT.address === "0x0000000000000000000000000000000000000000") {
    reasons.push("测试网 USDT 地址仍是占位符：请在 src/lib/tokens.ts 替换为真实测试网 USDT 地址。");
  }

  const simulate = () => { if (isConnected && address) { recordContributionUSDT(address as Address, 100); alert("已模拟：本地址买入 100 USDT，已给上级结算 30% 分润（15/10/5）"); } };
  const withdraw = () => { if (isConnected && address) { withdrawMyRewards(address as Address); alert("演示：已把待领取清零（真实上线请改为合约/后端领取）"); } };

  return (
    <div
      className="min-h-screen text-white pt-20 md:pt-24"  // ✅ 顶部留白，避免被导航栏遮挡
      style={{
        background:"#0b0d12",
        backgroundImage:
          "radial-gradient(600px 300px at 10% -10%, rgba(79,70,229,.18), transparent 70%)," +
          "radial-gradient(600px 300px at 100% 10%, rgba(16,185,129,.12), transparent 70%)"
      }}
    >
      {/* 顶部小标 */}
      <div className="px-4"><Badge>Me v2 ✅</Badge></div>

      <div className="container-narrow px-4 pb-12">
        {/* Header */}
        <div className="mt-2 mb-5 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold tracking-tight">我的</h1>
            <p className="opacity-75 text-sm mt-1">
              连接：{isConnected ? "已连接" : (status==="reconnecting" ? "重连中…" : "未连接")}
              {" ｜ "}网络：{String(chainId)}
              {address ? <>{" ｜ "}地址：<span className="opacity-90">{address.slice(0,6)}…{address.slice(-4)}</span></> : null}
              {" ｜ "}分润总比例：{Math.round(TOTAL_RATE*100)}%
            </p>
          </div>
          {/* ✅ 只在已连接时显示一个小徽章；未连接时这里什么也不显示（避免出现第二个“连接钱包”提示） */}
          {isConnected && <Badge tone="emerald">已连接</Badge>}
        </div>

        {/* 资产 */}
        <div className="space-y-3">
          <Row label={nativeSymbol} value={bnb.data?.formatted ?? "0"} loading={bnb.isLoading||bnb.isFetching} grad="to right, #f59e0b, #f97316" />
          <Row label="USDT"  value={usdt.data?.formatted ?? "0"} loading={usdt.isLoading||usdt.isFetching} grad="to right, #22c55e, #10b981" />
          <Row label="RST"   value={rst.data?.formatted  ?? "0"} loading={rst.isLoading||rst.isFetching} grad="to right, #a78bfa, #60a5fa" />
        </div>

        {/* 邀请与分润 */}
        <div className="mt-8 card p-4 space-y-3">
          <div className="text-sm opacity-80">规则：总 30% USDT（一级 15%、二级 10%、三级 5%）</div>

          <div className="flex items-center gap-2">
            <input className="input" readOnly value={inviteLink || "请先连接钱包生成邀请链接"} />
            <button
              className="btn btn-primary"
              disabled={!inviteLink}
              onClick={async()=>{ if(!inviteLink) return; await navigator.clipboard.writeText(inviteLink); setCopied(true); setTimeout(()=>setCopied(false),1200); }}>
              {copied ? "已复制" : "复制"}
            </button>
          </div>

          <div className="card p-3 space-y-2">
            <div className="text-sm">待领取（USDT）：<b>{rewards.pendingUSDT}</b></div>
            <div className="text-xs opacity-75">累计业绩：一级 {rewards.stats.l1} ｜ 二级 {rewards.stats.l2} ｜ 三级 {rewards.stats.l3}</div>
            <div className="flex gap-2 pt-1">
              <button className="btn btn-ghost" onClick={simulate}>模拟：我买入 100 USDT</button>
              <button className="btn btn-success" onClick={withdraw}>领取（演示清零）</button>
            </div>
            <div className="text-xs opacity-60">* 本区为前端演示；正式上线请改为合约/后端账本与领取。</div>
          </div>
        </div>

        {/* Debug（可保留） */}
        {reasons.length>0 && (
          <div className="mt-6 card p-4" style={{borderColor:"rgba(239,68,68,.4)", background:"rgba(239,68,68,.10)"}}>
            <div className="text-sm font-medium mb-1">为什么余额还是 0 / 邀请为空：</div>
            <ul className="list-disc pl-5 text-sm opacity-90">
              {reasons.map((r,i)=><li key={i}>{r}</li>)}
            </ul>
          </div>
        )}
      </div>
    </div>
  );
}



"use client";
import React, { useEffect, useMemo, useState } from "react";
import { useAccount } from "wagmi";
import { TOKENS, mockQuote, tokenIconSrc } from "@/lib/tokens";

const fmt = (n: number, d = 6) => (isFinite(n) ? Number(n).toFixed(d) : "0");

export default function SwapPanel(){
  const { isConnected } = useAccount();
  const [fromToken, setFromToken] = useState(TOKENS[0]); // BNB
  const [toToken, setToToken]     = useState(TOKENS[2]); // RST
  const [amountIn, setAmountIn]   = useState("");
  const amountNum = parseFloat(amountIn) || 0;

  const out = useMemo(()=> mockQuote(amountNum, fromToken, toToken), [amountNum, fromToken, toToken]);
  const canSwap = isConnected && amountNum > 0 && out > 0 && fromToken.symbol !== toToken.symbol;

  function TokenRow({
    label, value, onChange, token, onPick
  }: {
    label: string; value: string; onChange: (v: string)=>void;
    token: typeof TOKENS[number]; onPick: (t: typeof TOKENS[number])=>void;
  }){
    const [open, setOpen] = useState(false);
    return (
      <div className="rounded-2xl border p-3" style={{borderColor:"var(--rs-border)",background:"rgba(255,255,255,.03)"}}>
        <div className="mb-2 flex items-center justify-between">
          <span className="text-xs dim">{label}</span>
          <div className="relative">
            <button className="rounded-xl border px-2 py-1 text-sm"
              style={{borderColor:"var(--rs-border)",background:"rgba(255,255,255,.08)"}}
              onClick={()=>setOpen(v=>!v)}
            >
              <span className="inline-flex items-center gap-2">
                <img src={tokenIconSrc(token.symbol)} alt={token.symbol} className="h-4 w-4 rounded-full"/>
                {token.symbol}
              </span> ▾
            </button>
            {open && (
              <div className="absolute right-0 z-10 mt-2 w-44 overflow-hidden rounded-xl border"
                   style={{borderColor:"var(--rs-border)",background:"#141518"}}>
                {TOKENS.map(t=> (
                  <button key={t.symbol}
                          className="flex w-full items-center gap-2 px-2 py-1 text-left text-sm hover:bg-white/5"
                          onClick={()=>{ onPick(t); setOpen(false); }}>
                    <img src={tokenIconSrc(t.symbol)} alt={t.symbol} className="h-4 w-4 rounded-full"/>{t.symbol}
                    <span className="ml-1 text-xs text-white/40">— {t.name}</span>
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>
        <input type="number" inputMode="decimal" placeholder="0.0" value={value}
               onChange={e=>onChange(e.currentTarget.value)}
               className="w-full rounded-xl border bg-transparent px-3 py-2 text-sm"
               style={{borderColor:"var(--rs-border)"}}/>
      </div>
    );
  }

  return (
    <div className="rounded-2xl border p-4" style={{borderColor:"var(--rs-border)",background:"rgba(255,255,255,.03)"}}>
      <div className="text-white/80 mb-2">闪兑 · Swap（演示报价）</div>
      <div className="space-y-3">
        <TokenRow label="支付" value={amountIn} onChange={setAmountIn} token={fromToken} onPick={setFromToken}/>
        <div className="text-center text-white/40">↓</div>
        <TokenRow label="获得（预估）" value={out ? fmt(out) : ""} onChange={()=>{}} token={toToken} onPick={setToToken}/>
      </div>
      <div className="mt-4 grid grid-cols-2 gap-3">
        <button className="rounded-2xl border px-4 py-2 text-sm" style={{borderColor:"var(--rs-border)"}} onClick={()=>alert("Approve（占位）")}>批准 / Approve</button>
        <button className="rounded-2xl px-4 py-2 text-sm text-black" disabled={!canSwap}
          style={{background:"linear-gradient(90deg,#22d3ee,#a78bfa,#60a5fa)", opacity: canSwap?1:.6}}
          onClick={()=>alert("模拟下单成功（占位）")}
        >立即闪兑</button>
      </div>
    </div>
  );
}

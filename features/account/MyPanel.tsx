"use client";
import React from "react";

/**
 * 紧凑行高版本：把每一项做成和资产页一致的大小（px-4 py-3，去掉多余 min-h/h-*）。
 * 不依赖 wagmi/tokens，纯 UI；后续要接余额可再往 Row 里填值。
 */

type RowProps = { label: string; value?: string | number };

function Row({ label, value = 0 }: RowProps){
  return (
    <div
      className="flex items-center justify-between rounded-2xl border px-4 py-3"
      style={{ borderColor: "var(--rs-border, rgba(255,255,255,.12))", background: "rgba(255,255,255,.03)" }}
    >
      <div className="flex items-center gap-3">
        <span className="inline-grid place-items-center h-6 w-6 rounded-full bg-gradient-to-r from-fuchsia-400 to-cyan-300 text-[10px] text-black/80 shadow" />
        <span className="text-white">{label}</span>
      </div>
      <div className="text-white/80 text-right tabular-nums">{value}</div>
    </div>
  );
}

export default function MyPanel(){
  return (
    <div className="space-y-3">
      <Row label="BNB" />
      <Row label="USDT" />
      <Row label="RST" />
    </div>
  );
}
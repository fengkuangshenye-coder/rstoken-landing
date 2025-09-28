"use client";
import React from "react";
import { Card, CardContent } from "@/components/ui/Card";
import useBalances from "@/hooks/useBalances";
import useLocalStorage from "@/hooks/useLocalStorage";
import { fmt } from "@/lib/format";

export default function PortfolioCard(){
  const [addr]=useLocalStorage<string>("rst_wallet","");
  const {get}=useBalances(addr);
  const rows=["BNB","USDT","RST"];
  return (
    <Card><CardContent>
      {addr? <div className="dim text-sm mb-4">地址：{addr}</div> : <div className="dim text-sm mb-4">未连接钱包</div>}
      <div className="grid gap-3">
        {rows.map(s=> (
          <div key={s} className="flex items-center justify-between rounded-xl border px-3 py-2" style={{borderColor:"var(--rs-border)", background:"rgba(255,255,255,0.03)"}}>
            <div className="flex items-center gap-2"><div className="h-6 w-6 rounded-full" style={{background:"linear-gradient(135deg,#f472b6,#22d3ee)"}}></div><div>{s}</div></div>
            <div className="dim">{fmt(get(s))}</div>
          </div>
        ))}
      </div>
    </CardContent></Card>
  );
}

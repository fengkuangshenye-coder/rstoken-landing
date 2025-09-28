"use client";
import React from "react";
import { Card, CardContent } from "@/components/ui/Card";
import data from "@/data/tokenomics.json";

type Item={label:string,value:number,color:string};
export default function TokenomicsCard(){
  const items=data as Item[]; const total=items.reduce((s,d)=>s+d.value,0);
  const r=80, stroke=28; const C=2*Math.PI*r; let acc=0;
  const arcs=items.map(d=>{const len=C*(d.value/total); const dasharray=`${len} ${C-len}`; const dashoffset=-(C*(acc/total)); acc+=d.value; return {...d,dasharray,dashoffset}});
  const Legend=({c,name,v}:{c:string,name:string,v:number})=> (
    <div className="flex items-center justify-between rounded-2xl border px-3 py-3" style={{borderColor:"var(--rs-border)", background:"rgba(255,255,255,.04)"}}>
      <div className="flex items-center gap-3"><span style={{display:"inline-block",width:12,height:12,borderRadius:9999,background:c}}/> <span className="text-sm">{name}</span></div>
      <div className="text-sm" style={{color:"#9ca3af"}}>{v}%</div>
    </div>
  );
  return (
    <div>
      <h2 className="title-gradient text-2xl font-bold mb-3">代币分配</h2>
      <p className="muted text-sm mb-5">初始分配：社区 50%，团队与顾问 20%，项目基金 10%，市场 10%，合作伙伴/投资者 10%。</p>
      <div className="grid gap-6 md:grid-cols-2 items-center">
        <Card className="glass"><CardContent>
          <div className="rounded-3xl p-4" style={{background:"rgba(255,255,255,.03)", border:"1px solid var(--rs-border)"}}>
            <svg viewBox="0 0 200 200" width="100%" height="100%" style={{maxWidth:420,display:"block",margin:"0 auto"}}>
              <circle cx={100} cy={100} r={80} fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth={28} />
              <g transform={`rotate(-90 100 100)`}>
                {arcs.map(a=> <circle key={a.label} cx={100} cy={100} r={80} fill="none" stroke={a.color} strokeWidth={28} strokeDasharray={a.dasharray} strokeDashoffset={a.dashoffset} strokeLinecap="butt"/>) }
              </g>
              <text x={100} y={96} textAnchor="middle" fontSize={12} fill="#94a3b8">RSTOKEN</text>
              <text x={100} y={114} textAnchor="middle" fontSize={16} fill="#e2e8f0" fontWeight={600}>Tokenomics</text>
            </svg>
          </div>
        </CardContent></Card>
        <div className="grid gap-3">{items.map(d=> <Legend key={d.label} c={d.color} name={d.label} v={d.value}/>)}</div>
      </div>
    </div>
  );
}


"use client";
import React, { useEffect, useRef, useState } from "react";
import { Card, CardContent } from "@/components/ui/Card";
import { Badge } from "@/components/ui/Badge";

export default function OraclePreview(){
  const [play,setPlay]=useState(true); const cache=useRef(true);
  const [births,setB]=useState(16); const [deaths,setD]=useState(6); const net=births-deaths;
  useEffect(()=>{const onVis=()=>{if(document.hidden){cache.current=play;setPlay(false)}else setPlay(cache.current)};document.addEventListener("visibilitychange",onVis);return()=>document.removeEventListener("visibilitychange",onVis)},[play]);
  useEffect(()=>{ if(!play) return; const id=setInterval(()=>{setB(b=>b+Math.floor(Math.random()*3)); setD(d=>d+Math.floor(Math.random()*2));},2000); return()=>clearInterval(id)},[play]);
  const Box=({title,value,gradient}:{title:string,value:number,gradient:string})=> (
    <div className="rounded-2xl p-4" style={{background:gradient,border:"1px solid rgba(255,255,255,0.08)"}}>
      <div className="text-xs" style={{color:"#b3c0d1"}}>{title}</div>
      <div className="mt-2 text-3xl font-semibold" style={{color:"#a5f3fc"}}>{value}</div>
    </div>
  );
  return (
    <div className="relative">
      <Card className="glass">
        <CardContent>
          <div className="mb-4 flex items-center justify-between">
            <Badge>预言机 · 演示</Badge>
            <div className="text-xs" style={{color:"#8aa0b2"}}>非实时 | 仅用于展示交互</div>
          </div>
          <div className="grid gap-3 md:grid-cols-2">
            <Box title="出生（↑增发）" value={births} gradient="linear-gradient(135deg, rgba(59,130,246,.12), rgba(14,165,233,.08))"/>
            <Box title="死亡（↓销毁）" value={deaths} gradient="linear-gradient(135deg, rgba(244,114,182,.14), rgba(99,102,241,.08))"/>
          </div>
          <div className="mt-4 rounded-2xl border px-4 py-3 flex items-center justify-between" style={{borderColor:"var(--rs-border)", background:"rgba(255,255,255,.04)"}}>
            <div className="text-sm dim">净变化（供给 Δ）</div>
            <div className="text-xl font-semibold" style={{background:"linear-gradient(90deg,#86efac,#a7f3d0)",WebkitBackgroundClip:"text",backgroundClip:"text",color:"transparent"}}>{net>0?`+${net}`:net} RST</div>
          </div>
          <div className="mt-4 flex gap-2">
            <button className="rounded-xl border px-3 py-2 text-sm" style={{borderColor:"var(--rs-border)",background:"rgba(255,255,255,.08)"}} onClick={()=>setPlay(p=>!p)}>{play?"暂停":"继续"}演示</button>
            <button className="rounded-xl px-3 py-2 text-sm" style={{background:"rgba(255,255,255,.06)"}} onClick={()=>{setB(16);setD(6)}}>重置</button>
          </div>
        </CardContent>
      </Card>
      <div className="absolute -inset-6 -z-0 rounded-[32px]" style={{background:"radial-gradient(40% 60% at 20% 10%, rgba(34,211,238,.28), transparent), radial-gradient(40% 60% at 80% 20%, rgba(244,114,182,.28), transparent)", filter:"blur(20px)"}} />
    </div>
  );
}

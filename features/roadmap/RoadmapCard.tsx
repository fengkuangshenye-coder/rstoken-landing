"use client";
import React from "react";
import { Card, CardContent } from "@/components/ui/Card";
export default function RoadmapCard(){
  const items=[
    { title:"初始阶段（1–3个月）", color:"#22d3ee", bullets:["完成智能合约与预言机系统","启动 ICO 并进行全球宣传","对接去中心化交易所，确保上架流通"]},
    { title:"发展阶段（6–12个月）", color:"#a78bfa", bullets:["完成全球人口数据的实时同步与合约优化","在 DeFi、钱包、支付平台扩大应用场景"]},
    { title:"成熟阶段（1–2年）", color:"#22c55e", bullets:["供应/销毁机制稳定运行","完成 DAO 治理，让社区参与投票","打造全球用户基础与商业生态"]},
  ];
  return (
    <Card className="glass"><CardContent>
      <div className="font-semibold mb-2">路线图 · RStoken 1.5</div>
      <div className="space-y-4">
        {items.map(it=> (
          <div key={it.title} className="relative pl-4">
            <span className="absolute left-0 top-2 h-2 w-2 rounded-full" style={{background:it.color}}/>
            <div className="text-sm" style={{color:"#e5e7eb"}}>{it.title}</div>
            <ul className="list-disc list-inside text-xs muted mt-1">{it.bullets.map(b=> <li key={b}>{b}</li>)}</ul>
          </div>
        ))}
      </div>
    </CardContent></Card>
  );
}

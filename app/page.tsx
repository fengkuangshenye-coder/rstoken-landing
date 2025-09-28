"use client";
import React from "react";
import OraclePreview from "@/features/oracle/OraclePreview";
import TokenomicsCard from "@/features/tokenomics/TokenomicsCard";
import { Card, CardContent } from "@/components/ui/Card";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";

export default function HomePage(){
  return (
    <section className="container mx-auto px-4 pt-24 md:pt-28">
      <div className="grid items-start gap-10 md:grid-cols-2">
        <div>
          <Badge className="mb-4">跨时代 · 科技美学</Badge>
          <h1 className="text-4xl md:text-6xl font-bold">全球人口<span className="title-gradient"> 同步变化 </span>的智能代币</h1>
          <p className="mt-4 muted text-base md:text-lg">RStoken（人生币）是一种智能代币，它的发行和销毁直接根据全球人口变化来调整：每当全球出生一名新生儿，RStoken 增发一枚；每当全球有一名生命消逝，RStoken 销毁一枚。</p>
          <div className="mt-6 flex flex-wrap items-center gap-3">
            <Button size="lg" onClick={()=>location.assign("/swap")}>立即参与</Button>
            <Button variant="outline" size="lg">查看白皮书</Button>
          </div>
          <div className="mt-6 flex flex-wrap gap-6 dim">
            <div>🌐 2025 年全球人口约 <span style={{color:"#fff"}}>80 亿</span></div>
            <div>✅ 合约可审计</div>
            <div>🪙 公平与可持续激励</div>
          </div>
        </div>
        <OraclePreview />
      </div>

      <div className="mt-16 grid gap-6 md:grid-cols-3">
        {[{i:"🪙",t:"自动化供给",d:"基于出生/死亡数据自动增发与销毁，代币与社会基本面同频。"},
          {i:"✅",t:"公平透明",d:"数据来源与合约逻辑公开透明，可持续审计与追溯。"},
          {i:"🌐",t:"全球可及",d:"无论身处何地，均可参与购买与持有，感受宏观变化。"}].map(x=> (
          <Card key={x.t}><CardContent>
            <div className="mb-3 inline-flex rounded-xl border px-3 py-2"
                 style={{borderColor:"var(--rs-border)",background:"rgba(255,255,255,0.05)",color:"#67e8f9"}}>{x.i}</div>
            <div className="text-lg font-semibold">{x.t}</div>
            <div className="mt-2 text-sm muted">{x.d}</div>
          </CardContent></Card>
        ))}
      </div>

      <div className="mt-16"><TokenomicsCard /></div>
    </section>
  );
}

"use client";
import React from "react";
import SwapPanel from "@/features/swap/SwapPanel";
import RoadmapCard from "@/features/roadmap/RoadmapCard";
import { Card, CardContent } from "@/components/ui/Card";

export default function SwapPage(){
  return (
    <section className="container mx-auto px-4 pt-24">
      <h2 className="title-gradient text-2xl font-bold mb-4">一键闪兑 · 同源视觉</h2>
      <div className="grid gap-6 md:grid-cols-2 items-start">
        <SwapPanel />
        <div className="flex flex-col gap-4 md:sticky md:top-24">
          <RoadmapCard />
          <Card className="glass">
            <CardContent>
              <div className="font-semibold mb-2">接入说明</div>
              <ul className="list-disc list-inside text-sm muted">
                <li>报价：将 <code>mockQuote</code> 替换为 1inch / 0x / OpenOcean / 自营路由。</li>
                <li>批准：ERC-20 先 <code>approve</code>，再进行 <code>swap</code>。</li>
                <li>RST 地址：部署后替换占位地址与 <code>decimals</code>。</li>
                <li>链：默认 BSC，可切换 Testnet 调试。</li>
              </ul>
            </CardContent>
          </Card>
        </div>
      </div>
    </section>
  );
}

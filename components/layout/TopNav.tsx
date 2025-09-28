"use client";
import React from "react";
import ScrollProgress from "@/components/layout/ScrollProgress";
import ConnectButtons from "@/components/wallet/ConnectButtons";

export default function TopNav(){
  return (
    <div className="fixed inset-x-0 top-0 z-40">
      <ScrollProgress />
      <div className="container mx-auto flex h-16 items-center justify-between px-4 backdrop-blur" style={{background:"rgba(0,0,0,.35)"}}>
        <div className="flex items-center gap-2">
          <div className="grid h-8 w-8 place-items-center rounded-xl" style={{background:"linear-gradient(135deg,#f472b6,#22d3ee)",color:"#0b0d10",fontWeight:700}}>RS</div>
          <div className="leading-tight">
            <div className="text-sm" style={{color:"rgba(255,255,255,.75)"}}>RStoken v1.5</div>
            <div className="text-xs dim">Life-Linked Crypto</div>
          </div>
        </div>
        <div className="hidden md:flex items-center gap-3">
          <ConnectButtons />
        </div>
      </div>
    </div>
  );
}

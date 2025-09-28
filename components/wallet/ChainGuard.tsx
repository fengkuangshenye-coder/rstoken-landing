"use client";
import React from "react";
import { useAccount, useChainId, useSwitchChain } from "wagmi";
import { bsc } from "viem/chains";

export default function ChainGuard({ children }: { children: React.ReactNode }){
  const { isConnected } = useAccount();
  const chainId = useChainId();
  const { switchChain } = useSwitchChain();

  if (!isConnected) return <>{children}</>;
  if (chainId !== bsc.id) {
    return (
      <div className="rounded-xl border p-3 text-sm" style={{borderColor:"var(--rs-border)", background:"rgba(255,255,255,.04)"}}>
        当前网络不是 BSC 主网。
        <button className="ml-2 underline" onClick={()=>switchChain({ chainId: bsc.id })}>一键切换</button>
      </div>
    );
  }
  return <>{children}</>;
}

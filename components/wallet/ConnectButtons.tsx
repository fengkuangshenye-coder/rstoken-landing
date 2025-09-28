"use client";
import React from "react";
import { useAccount, useConnect, useDisconnect, useChainId, useSwitchChain } from "wagmi";
import { bsc, bscTestnet } from "viem/chains";

export default function ConnectButtons(){
  const { address, isConnected } = useAccount();
  const { connect, connectors, status: cStatus } = useConnect();
  const { disconnect } = useDisconnect();
  const chainId = useChainId();
  const { switchChain } = useSwitchChain();

  const short=(a?:string)=> a? `${a.slice(0,6)}…${a.slice(-4)}`:"";

  if (isConnected) {
    return (
      <div className="flex items-center gap-2">
        <span className="text-xs text-white/70">{short(address)}</span>
        <select
          className="rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm"
          value={chainId}
          onChange={(e)=> switchChain({ chainId: Number(e.target.value) })}
        >
          {[bsc, bscTestnet].map(c => (<option key={c.id} value={c.id}>{c.name}</option>))}
        </select>
        <button className="rounded-xl border px-3 py-2 text-sm hover:bg-white/10" onClick={()=>disconnect()}>断开</button>
      </div>
    );
  }

  const injected = connectors.find(c=>c.id==="injected");
  const wc = connectors.find(c=>c.id==="walletConnect");

  return (
    <div className="flex items-center gap-2">
      {injected && <button disabled={cStatus==="pending"} className="rounded-xl border px-3 py-2 text-sm hover:bg-white/10" onClick={()=>connect({ connector: injected })}>🦊 连接钱包</button>}
      {wc && <button disabled={cStatus==="pending"} className="rounded-xl border px-3 py-2 text-sm hover:bg-white/10" onClick={()=>connect({ connector: wc })}>👜 WalletConnect</button>}
    </div>
  );
}

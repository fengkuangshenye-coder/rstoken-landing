"use client";
import React, { useRef } from "react";
import { WagmiProvider } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import wagmiConfig from "@/lib/wagmi";

export default function Providers({ children }: { children: React.ReactNode }) {
  const qc = useRef(new QueryClient()).current;
  return (
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={qc}>{children}</QueryClientProvider>
    </WagmiProvider>
  );
}

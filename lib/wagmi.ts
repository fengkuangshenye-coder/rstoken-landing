import { createConfig, http } from "wagmi";
import { injected } from "wagmi/connectors";
import { bsc, bscTestnet } from "viem/chains";

export const config = createConfig({
  chains: [bsc, bscTestnet],
  multiInjectedProviderDiscovery: true,
  connectors: [
    injected({ target: "metaMask" }),
    injected({ target: "okxWallet" }),
    injected(), // fallback
  ],
  transports: {
    [bsc.id]: http("https://bsc-dataseed.binance.org"),
    [bscTestnet.id]: http("https://data-seed-prebsc-1-s1.binance.org:8545"),
  },
  ssr: true,
});
export const wagmiConfig = config;
export default config;
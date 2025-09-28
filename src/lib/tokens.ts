export const CHAINS = { BSC_MAINNET: 56, BSC_TESTNET: 97 } as const;
export const TOKENS: Record<number, {
  NATIVE: { symbol: string, decimals: number },
  USDT?: { address: `0x${string}`, decimals: number },
  RST?: { address: `0x${string}`, decimals: number },
}> = {
  [56]: {
    NATIVE: { symbol: "BNB", decimals: 18 },
    USDT: { address: "0x55d398326f99059fF775485246999027B3197955", decimals: 18 },
    RST: { address: (process.env.NEXT_PUBLIC_RSTOKEN_ADDRESS_MAINNET as `0x${string}`) || undefined as any, decimals: 18 },
  },
  [97]: {
    NATIVE: { symbol: "tBNB", decimals: 18 },
    USDT: { address: "0x0000000000000000000000000000000000000000", decimals: 18 }, // TODO: 鏇挎崲涓烘祴璇曠綉 USDT
    RST: { address: (process.env.NEXT_PUBLIC_RSTOKEN_ADDRESS_TESTNET as `0x${string}`) || undefined as any, decimals: 18 },
  },
};

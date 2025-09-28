export type Token = {
  symbol: string;
  name: string;
  address?: `0x${string}`; // 无地址视为原生币
  decimals: number;
  icon: string;            // /tokens/*.svg
};

export const TOKENS: Token[] = [
  { symbol: "BNB",  name: "BNB",        decimals: 18, icon: "/tokens/bnb.svg" },  // 原生
  { symbol: "USDT", name: "Tether USD", decimals: 18, icon: "/tokens/usdt.svg", address: "0x55d398326f99059fF775485246999027B3197955" },
  { symbol: "RST",  name: "RStoken",    decimals: 18, icon: "/tokens/rst.svg",  address: "0x0000000000000000000000000000000000000000" } // 占位
];

export function tokenIconSrc(symbol: string): string {
  switch (symbol.toUpperCase()) {
    case "BNB":  return "/tokens/bnb.svg";
    case "USDT": return "/tokens/usdt.svg";
    case "RST":  return "/tokens/rst.svg";
    default:     return "/tokens/usdt.svg";
  }
}

export function isNative(t: Token) {
  return !t.address;
}

// —— 演示用的报价函数（可先跑通 UI，后续替换为 1inch/0x/OpenOcean/自营路由）
const RATE_USD_PER_BNB = 500; // 1 BNB ≈ 500 USD（占位）
const RATE_RST_PER_USD = 1;   // 1 USD ≈ 1 RST（占位）

export function mockQuote(amountIn: number, from: Token, to: Token): number {
  if (!amountIn || amountIn <= 0) return 0;
  let usd = 0;
  if (from.symbol === "BNB") usd = amountIn * RATE_USD_PER_BNB;
  else if (from.symbol === "USDT") usd = amountIn;
  else usd = amountIn / RATE_RST_PER_USD; // RST -> USD

  if (to.symbol === "BNB")  return usd / RATE_USD_PER_BNB;
  if (to.symbol === "USDT") return usd;
  return usd * RATE_RST_PER_USD;          // -> RST
}

export function findToken(symbol: string): Token | undefined {
  return TOKENS.find(t => t.symbol.toUpperCase() === symbol.toUpperCase());
}

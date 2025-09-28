import { NextRequest } from "next/server";

const RATE_USD_PER_BNB = 500;
const RATE_RST_PER_USD = 1;

function toUsd(amount: number, symbol: string){
  if (symbol === "BNB") return amount * RATE_USD_PER_BNB;
  if (symbol === "USDT") return amount;
  if (symbol === "RST") return amount / RATE_RST_PER_USD;
  return 0;
}
function fromUsd(usd: number, symbol: string){
  if (symbol === "BNB") return usd / RATE_USD_PER_BNB;
  if (symbol === "USDT") return usd;
  if (symbol === "RST") return usd * RATE_RST_PER_USD;
  return 0;
}

export async function GET(req: NextRequest){
  const { searchParams } = new URL(req.url);
  const from = (searchParams.get("from")||"").toUpperCase();
  const to = (searchParams.get("to")||"").toUpperCase();
  const amount = Number(searchParams.get("amount")||"0");
  const slippageBps = Number(searchParams.get("slippageBps")||"50");

  if (!from || !to || !Number.isFinite(amount) || amount<=0) {
    return new Response(JSON.stringify({ error: "bad_params" }), { status: 400 });
  }
  const usd = toUsd(amount, from);
  const out = fromUsd(usd, to);
  const minOut = out * (1 - slippageBps/10000);

  return Response.json({ from, to, amountIn: amount, amountOut: out, minOut, priceImpact: 0 });
}

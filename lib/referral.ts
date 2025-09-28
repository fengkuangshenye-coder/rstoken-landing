"use client";
export const TIER_RATES = [0.15, 0.10, 0.05] as const; // 15%/10%/5%
export const TOTAL_RATE = TIER_RATES.reduce((a,b)=>a+b,0);
const LS_KEY_REF = "rst.ref"; const LS_KEY_MY = "rst.my";
export function captureReferralFromUrl(){
  if (typeof window === "undefined") return;
  const ref = new URLSearchParams(window.location.search).get("ref");
  if (ref && /^0x[a-fA-F0-9]{40}$/.test(ref)) localStorage.setItem(LS_KEY_REF, ref.toLowerCase());
}
export function setMyAddress(a?: string){ if(typeof window!=="undefined"&&a) localStorage.setItem(LS_KEY_MY, a.toLowerCase()); }
export function getRefAddress(){ if(typeof window==="undefined") return null; return localStorage.getItem(LS_KEY_REF); }
export function getMyAddress(){ if(typeof window==="undefined") return null; return localStorage.getItem(LS_KEY_MY); }
export function getInviteLink(my?: string){
  if (typeof window === "undefined") return "";
  const base = window.location.origin; const me = my || getMyAddress() || "";
  return me ? `${base}/swap?ref=${me}` : `${base}/swap`;
}
export function calcRewards(outAmount:number){
  const v = Number.isFinite(outAmount) && outAmount>0 ? outAmount : 0;
  return { total: v*TOTAL_RATE, level1:v*TIER_RATES[0], level2:v*TIER_RATES[1], level3:v*TIER_RATES[2] };
}
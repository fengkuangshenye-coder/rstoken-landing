export type Address = `0x${string}`;
const LS_KEYS = { ME:"ref_me_address", REF_OF:"ref_referrer_of", CHILDREN:"ref_children_of", REWARDS:"ref_rewards_usdt", STATS:"ref_stats" } as const;
export const REF_SPLIT = { L1:0.15, L2:0.10, L3:0.05 } as const;
export const TOTAL_RATE = REF_SPLIT.L1 + REF_SPLIT.L2 + REF_SPLIT.L3; // 0.30

const parse = <T,>(k:string,def:T):T => { if(typeof window==="undefined") return def; try{ return (JSON.parse(localStorage.getItem(k)||"") as T) ?? def }catch{ return def } };
const save  = (k:string,v:any)=>{ if(typeof window!=="undefined") localStorage.setItem(k,JSON.stringify(v)) };
const norm  = (a?:string|null)=>(a||"").toLowerCase() as Address;
const isAddr= (a?:string)=>/^0x[a-fA-F0-9]{40}$/.test(a||"");

export function captureReferrerFromURL(my?:Address){
  if(typeof window==="undefined") return;
  const url=new URL(window.location.href);
  const ref=norm(url.searchParams.get("ref"));
  if(!isAddr(ref)) return;
  if(my && norm(my)===ref) return;
  const refOf=parse<Record<Address,Address>>(LS_KEYS.REF_OF,{} as any);
  const me=norm(my || parse<Address>(LS_KEYS.ME,"" as any));
  if(!me) return;
  if(!refOf[me]){
    refOf[me]=ref; save(LS_KEYS.REF_OF,refOf);
    const children=parse<Record<Address,Address[]>>(LS_KEYS.CHILDREN,{} as any);
    children[ref]=Array.from(new Set([...(children[ref]||[]),me])); save(LS_KEYS.CHILDREN,children);
  }
}

export function setMeAddress(addr?:Address){ if(!addr) return; save(LS_KEYS.ME,norm(addr)); }

export function getMyInviteLink(addr?:Address){
  if(typeof window==="undefined") return "";
  const base=`${location.origin}${location.pathname}`;
  if(!addr) return "";
  return `${base}?ref=${addr}`;
}

export function getUplines(of:Address){
  const refOf=parse<Record<Address,Address>>(LS_KEYS.REF_OF,{} as any);
  const l1=refOf[of]; const l2=l1?refOf[l1]:undefined; const l3=l2?refOf[l2]:undefined;
  return { l1,l2,l3 };
}

export function recordContributionUSDT(buyer:Address,amountUSDT:number){
  const {l1,l2,l3}=getUplines(buyer);
  const rewards=parse<Record<Address,number>>(LS_KEYS.REWARDS,{} as any);
  const stats=parse<Record<Address,{l1:number;l2:number;l3:number;}>>(LS_KEYS.STATS,{} as any);
  const add=(who?:Address,part?:"l1"|"l2"|"l3",rate?:number)=>{
    if(!who||!rate) return;
    rewards[who]=(rewards[who]||0)+amountUSDT*rate;
    stats[who]=stats[who]||{l1:0,l2:0,l3:0};
    if(part) stats[who][part]+=amountUSDT;
  };
  add(l1,"l1",REF_SPLIT.L1); add(l2,"l2",REF_SPLIT.L2); add(l3,"l3",REF_SPLIT.L3);
  save(LS_KEYS.REWARDS,rewards); save(LS_KEYS.STATS,stats);
}

export function getMyRewards(addr?:Address){
  const a=norm(addr || parse<Address>(LS_KEYS.ME,"" as any));
  const rewards=parse<Record<Address,number>>(LS_KEYS.REWARDS,{} as any);
  const stats=parse<Record<Address,{l1:number;l2:number;l3:number;}>>(LS_KEYS.STATS,{} as any);
  return { pendingUSDT:Number((rewards[a]||0).toFixed(6)), stats:stats[a]||{l1:0,l2:0,l3:0} };
}

export function withdrawMyRewards(addr?:Address){
  const a=norm(addr || parse<Address>(LS_KEYS.ME,"" as any));
  const rewards=parse<Record<Address,number>>(LS_KEYS.REWARDS,{} as any);
  if(rewards[a]){ rewards[a]=0; save(LS_KEYS.REWARDS,rewards); }
}

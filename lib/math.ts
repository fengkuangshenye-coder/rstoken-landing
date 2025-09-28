export const calcMinReceived=(out:number, bps:number)=> out * (1 - (bps||0)/10000);
export const safe=(n:number)=> Number.isFinite(n)? n : 0;

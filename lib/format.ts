export const fmt=(n:number)=> Number.isFinite(n)? (n>=1? n.toFixed(6).replace(/0+$/,"").replace(/\.$/,"") : n.toPrecision(6)) : "0";

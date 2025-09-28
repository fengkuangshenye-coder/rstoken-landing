"use client";
import useLocalStorage from "@/hooks/useLocalStorage";
export default function useBalances(addr?:string){
  const [map,setMap]=useLocalStorage<Record<string,number>>("rst_balances",{BNB:1.2345,USDT:1200,RST:5000});
  const get=(sym:string)=> map[sym]||0; const set=(sym:string,val:number)=> setMap({...map,[sym]:val});
  return {get,set};
}

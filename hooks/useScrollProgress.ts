"use client";
import { useEffect, useState } from "react";
export default function useScrollProgress(){
  const [p,setP]=useState(0);
  useEffect(()=>{
    const onScroll=()=>{const h=document.documentElement;const sc=h.scrollTop;const height=h.scrollHeight-h.clientHeight;setP(height>0?sc/height:0)};
    onScroll(); window.addEventListener("scroll", onScroll, {passive:true});
    return ()=>window.removeEventListener("scroll", onScroll);
  },[]); return p;
}

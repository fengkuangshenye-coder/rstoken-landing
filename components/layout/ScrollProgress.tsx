"use client";
import React from "react";
import useScrollProgress from "@/hooks/useScrollProgress";
export default function ScrollProgress(){
  const p = useScrollProgress();
  return <div style={{width:`${(p*100).toFixed(2)}%`}} className="h-0.5 bg-gradient-to-r from-cyan-400 via-violet-400 to-rose-400"/>;
}

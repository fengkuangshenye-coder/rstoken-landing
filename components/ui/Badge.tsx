"use client";
import React from "react";
export function Badge({children, className=""}:{children:React.ReactNode,className?:string}){
  return <div className={`inline-flex items-center rounded-lg px-2.5 py-1 text-xs border border-white/10 bg-white/10 ${className}`}>{children}</div>;
}

"use client";
import React from "react";
export function Button(
  {children, className="", variant="primary", size="md", ...props}:
  {children:React.ReactNode,className?:string,variant?:"primary"|"outline"|"ghost",size?:"sm"|"md"|"lg"} & React.ButtonHTMLAttributes<HTMLButtonElement>
){
  const sz={sm:"h-8 px-3 text-sm", md:"h-10 px-4 text-sm", lg:"h-11 px-5 text-base"};
  const base="inline-flex items-center justify-center rounded-2xl font-medium focus:outline-none focus:ring-2 focus:ring-cyan-400/40 transition";
  const st={primary:"bg-gradient-to-r from-rose-400 via-violet-400 to-cyan-400 text-black hover:opacity-90",outline:"border border-white/20 bg-white/5 text-white hover:bg-white/10",ghost:"text-white/80 hover:bg-white/5"};
  return <button className={`${base} ${sz[size]} ${st[variant]} ${className}`} {...props}>{children}</button>;
}

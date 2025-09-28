"use client";
import React from "react";
export function Input(props: React.InputHTMLAttributes<HTMLInputElement>){
  return <input {...props} className={`w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm text-white placeholder:dim focus:outline-none focus:ring-2 focus:ring-cyan-400/40 ${props.className||""}`} />
}

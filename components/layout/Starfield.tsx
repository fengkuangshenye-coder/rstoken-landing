"use client";
import React from "react";
export default function Starfield(){
  return (
    <div aria-hidden className="pointer-events-none fixed inset-0 -z-10">
      <div className="absolute inset-0" style={{background:
        "radial-gradient(60% 40% at 50% 0%, rgba(37,99,235,0.25) 0%, rgba(0,0,0,0) 60%),"+
        "radial-gradient(50% 50% at 50% 100%, rgba(14,165,233,0.18) 0%, rgba(0,0,0,0) 60%)"}} />
      <div className="absolute inset-0" style={{mixBlendMode:"screen", opacity:.7, background:
        "radial-gradient(1200px 400px at 20% 10%, rgba(236,72,153,0.08), transparent),"+
        "radial-gradient(1000px 500px at 80% 20%, rgba(59,130,246,0.08), transparent),"+
        "radial-gradient(800px 600px at 50% 90%, rgba(34,197,94,0.06), transparent)"}} />
      <div className="absolute inset-0" style={{animation:"twinkle 6s linear infinite", background:
        "radial-gradient(1px 1px at 20% 30%, rgba(255,255,255,0.7), transparent),"+
        "radial-gradient(1px 1px at 70% 40%, rgba(255,255,255,0.5), transparent),"+
        "radial-gradient(1px 1px at 40% 80%, rgba(255,255,255,0.6), transparent),"+
        "radial-gradient(1px 1px at 85% 70%, rgba(255,255,255,0.5), transparent)"}} />
    </div>
  );
}

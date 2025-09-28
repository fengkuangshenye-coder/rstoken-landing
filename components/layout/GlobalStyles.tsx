"use client";
import React from "react";
export default function GlobalStyles(){
  return (
    <style>{String.raw`
      :root{
        --rs-bg:#0A0B0E; --rs-fg:white; --rs-muted:rgba(255,255,255,.70); --rs-dim:rgba(255,255,255,.55);
        --rs-border:rgba(255,255,255,.12); --rs-card:rgba(255,255,255,.03);
        --rs-accent-start:#f472b6; --rs-accent-mid:#a78bfa; --rs-accent-end:#22d3ee;
        --rs-green:#22c55e; --rs-amber:#f59e0b; --rs-radius:20px; --rs-shadow:0 24px 96px rgba(99,102,241,.25);
      }
      html,body{background:var(--rs-bg);color:var(--rs-fg);} a{text-decoration:none;color:inherit} .container{max-width:80rem}
      .glass{background:linear-gradient(135deg,rgba(255,255,255,.04),rgba(255,255,255,.02))}
      .card{border:1px solid var(--rs-border);background:var(--rs-card);border-radius:var(--rs-radius);box-shadow:var(--rs-shadow)}
      .title-gradient{background:linear-gradient(90deg,var(--rs-accent-end),var(--rs-accent-mid),var(--rs-accent-start));-webkit-background-clip:text;background-clip:text;color:transparent}
      .muted{color:var(--rs-muted)} .dim{color:var(--rs-dim)}
      .fade-in{ opacity:0; transform:translateY(10px); animation:fadein .6s ease forwards; }
      @keyframes fadein{to{opacity:1; transform:none}}
      @keyframes twinkle{0%,100%{opacity:.8}50%{opacity:.3}}
      button { cursor: pointer; }
    `}</style>
  );
}

"use client";
import React from "react";
import PortfolioCard from "@/features/portfolio/PortfolioCard";

export default function PortfolioPage(){
  return (
    <section className="container mx-auto px-4 pt-24 min-h-screen pt-[64px] pb-[72px]">
      <h2 className="title-gradient text-2xl font-bold mb-4">资产</h2>
      <PortfolioCard />
    </section>
  );
}

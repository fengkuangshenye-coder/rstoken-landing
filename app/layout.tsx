import React from "react";
import Providers from "@/app/providers";
import TopNav from "@/components/layout/TopNav";
import BottomTabs from "@/components/layout/BottomTabs";
import Starfield from "@/components/layout/Starfield";
import GlobalStyles from "@/components/layout/GlobalStyles";
import "./globals.css";

export const metadata = {
  title: "RStoken v1.5",
  description: "Life-Linked Crypto DApp"
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-CN">
      <body className="rs-safe" style={{ background: "#0A0B0E", color: "#fff" }}>
        <Providers>
          <Starfield />
          <GlobalStyles />
          <TopNav />
          <main className="pb-24">{children}</main>
          <BottomTabs />
        </Providers>
      </body>
    </html>
  );
}

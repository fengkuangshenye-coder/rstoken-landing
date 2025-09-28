"use client";
import MyPanel from "@/features/account/MyPanel";

export default function Page(){
  return (
    <div className="me-compact me-compact container mx-auto max-w-3xl p-4 min-h-screen pt-[64px] pb-[72px]">
      <h1 className="mb-4 text-lg font-semibold">我的</h1>
      <MyPanel />
    </div>
  );
}

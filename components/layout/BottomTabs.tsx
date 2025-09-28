"use client";
import { usePathname, useRouter } from "next/navigation";
type Route = `/${string}`;

function Tab(href: string, label: string){
  const router = useRouter();
  const pathname = usePathname();
  return (
    <button
      onClick={()=>router.push(href as Route)}
      className={`flex-1 py-3 text-sm ${pathname===href?"title-gradient":"dim"}`}
    >
      {label}
    </button>
  );
}

export default function BottomTabs(){
  return (
    <div className="fixed inset-x-0 bottom-0 z-40 border-t" style={{borderColor:"var(--rs-border)", background:"rgba(0,0,0,0.4)"}}>
      <div className="container mx-auto px-4 flex gap-2">
        {Tab("/","首页")}
        {Tab("/swap","闪兑")}
        {Tab("/portfolio","资产")}
        {Tab("/me","我的")}
      </div>
    </div>
  );
}

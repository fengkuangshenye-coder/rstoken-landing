"use client";
import React from "react";
export function Card({children, className=""}:{children:React.ReactNode,className?:string}){return <div className={`card ${className}`}>{children}</div>}
export function CardContent({children, className=""}:{children:React.ReactNode,className?:string}){return <div className={`p-6 ${className}`}>{children}</div>}

'use client';
import React from "react";

export default function InputField({ type="text", placeholder, value, onChange, Icon }) {
  return (
    <div className="relative">
      {Icon && <Icon className="absolute left-3 top-1/2 -translate-y-1/2 text-[#2ECC71]" />}
      <input
        type={type}
        placeholder={placeholder}
        value={value}
        onChange={onChange}
        required
        className="w-full pl-10 py-2 border border-[#2ECC71]/50 rounded-xl 
                   bg-white/80 backdrop-blur-sm text-[#0077B6] text-sm 
                   placeholder-[#0077B6]/60 shadow-inner 
                   focus:outline-none focus:ring-2 focus:ring-[#0077B6] 
                   focus:border-transparent transition"
      />
    </div>
  );
}

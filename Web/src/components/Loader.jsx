'use client';
import { motion } from "framer-motion";

export default function Loader() {
  return (
    <div className="fixed inset-0 flex items-center justify-center bg-white/70 backdrop-blur-md z-50">
      <motion.div
        className="w-12 h-12 border-4 border-t-[#0077B6] border-[#ADE8F4] rounded-full"
        animate={{ rotate: 360 }}
        transition={{ repeat: Infinity, duration: 1, ease: "linear" }}
      />
    </div>
  );
}

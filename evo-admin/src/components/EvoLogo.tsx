import Image from "next/image";

export default function EvoLogo({ className = "w-24 h-auto" }: { className?: string }) {
  return (
    <div className={`relative flex items-center justify-center ${className}`}>
      <img 
        src="/logo.png" 
        alt="EVO Logo" 
        className="w-full h-full object-contain drop-shadow-[0_0_15px_rgba(0,200,83,0.8)] contrast-125 brightness-110"
      />
    </div>
  );
}

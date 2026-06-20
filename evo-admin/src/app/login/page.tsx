"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import EvoLogo from "@/components/EvoLogo";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 60000); // 60s timeout for cold start

      const res = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/login`,
        {
          method: "POST",
          headers: { 
            "Bypass-Tunnel-Reminder": "true", 
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ email, password }),
          signal: controller.signal
        }
      );
      
      clearTimeout(timeoutId);
      const data = await res.json();

      if (!res.ok) throw new Error(data.error || "خطأ في تسجيل الدخول");

      // Store token
      localStorage.setItem("evo_admin_token", data.accessToken);
      router.push("/dashboard");
    } catch (err: any) {
      if (err.name === 'AbortError' || err.message === 'Failed to fetch') {
        setError("يبدو أن الخادم كان في وضع السبات (Render Free Tier). يرجى المحاولة مرة أخرى الآن.");
      } else {
        setError(err.message || "حدث خطأ");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div dir="rtl" className="min-h-screen bg-[#0B0F19] flex items-center justify-center p-4 relative overflow-hidden font-alexandria">
      {/* Background Effects */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none flex items-center justify-center">
        <div className="w-[800px] h-[800px] bg-[var(--color-brand-500)] opacity-5 rounded-full blur-[120px] mix-blend-screen" />
      </div>

      <div className="w-full max-w-md relative z-10 animate-fade-in-up">
        {/* Brand Header */}
        <div className="text-center mb-10 relative">
          <div className="flex items-center justify-center gap-4 mb-6" dir="ltr">
            <EvoLogo className="h-28 drop-shadow-[0_0_15px_rgba(0,200,83,0.8)]" />
            <span className="text-4xl font-cy-bold tracking-[0.2em] text-white font-bold mt-2" style={{ textShadow: "0 0 20px rgba(255,255,255,0.2)" }}>ADMIN</span>
          </div>
          <p className="text-gray-400 font-alexandria">أدخل بيانات الاعتماد للوصول إلى لوحة التحكم</p>
        </div>

        {/* Card */}
        <div className="bg-[var(--color-card)] border border-white/5 rounded-3xl p-8 sm:p-10 shadow-2xl relative overflow-hidden backdrop-blur-sm">
          <div className="absolute top-0 right-0 w-32 h-32 bg-[var(--color-brand-500)] opacity-5 blur-3xl rounded-full"></div>
          <form onSubmit={handleLogin} className="space-y-6 relative z-10">
            <div className="space-y-1.5">
              <label className="block text-sm font-bold text-gray-300">
                البريد الإلكتروني
              </label>
              <div className="relative group">
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  placeholder="admin@evo.jo"
                  className="w-full bg-[#0B0F19] border border-white/10 rounded-xl px-5 py-4 text-white placeholder-gray-600 focus:outline-none focus:border-[var(--color-brand-500)] transition-all font-cy-bold text-left focus:shadow-[0_0_15px_rgba(0,200,83,0.1)]"
                  dir="ltr"
                />
                <span className="absolute left-4 top-1/2 -translate-y-1/2 opacity-50 group-focus-within:opacity-100 transition-opacity">📧</span>
              </div>
            </div>

            <div className="space-y-1.5">
              <label className="block text-sm font-bold text-gray-300">
                كلمة المرور
              </label>
              <div className="relative group">
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  placeholder="••••••••"
                  className="w-full bg-[#0B0F19] border border-white/10 rounded-xl px-5 py-4 text-white placeholder-gray-600 focus:outline-none focus:border-[var(--color-brand-500)] transition-all font-cy-bold text-left focus:shadow-[0_0_15px_rgba(0,200,83,0.1)] tracking-widest"
                  dir="ltr"
                />
                <span className="absolute left-4 top-1/2 -translate-y-1/2 opacity-50 group-focus-within:opacity-100 transition-opacity">🔒</span>
              </div>
            </div>

            {error && (
              <div className="bg-red-500/10 border border-red-500/30 rounded-xl px-4 py-3 text-red-400 text-sm font-bold animate-fade-in-up flex items-start gap-2">
                <span className="mt-0.5 shrink-0">⚠️</span>
                <span>{error}</span>
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-[var(--color-brand-500)] hover:bg-[#00B047] disabled:opacity-50 disabled:hover:bg-[var(--color-brand-500)] disabled:cursor-not-allowed text-[#0B0F19] font-black py-4 rounded-xl transition-all shadow-[0_0_20px_rgba(0,200,83,0.2)] active:scale-95 text-base mt-2 flex items-center justify-center gap-2"
            >
              {loading ? (
                <>
                  <span className="w-5 h-5 border-2 border-black/20 border-t-black rounded-full animate-spin inline-block" />
                  جاري تسجيل الدخول...
                </>
              ) : (
                "تسجيل الدخول ⚡"
              )}
            </button>
          </form>
        </div>

        <p className="text-center text-gray-600 text-xs mt-6">
          EVO Admin v1.0 · Jordan 🇯🇴
        </p>
      </div>
    </div>
  );
}


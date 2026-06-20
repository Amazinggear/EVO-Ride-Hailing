"use client";

import { useState } from "react";

export default function NotificationsPage() {
  const [targetAudience, setTargetAudience] = useState("all");
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");

  const getToken = () => localStorage.getItem("evo_admin_token") || "";

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !body) {
      setMessage("⚠️ الرجاء تعبئة جميع الحقول");
      return;
    }
    setLoading(true);
    setMessage("");
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/notifications/send`, {
        method: "POST",
        headers: {
          "Bypass-Tunnel-Reminder": "true",
          Authorization: `Bearer ${getToken()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ targetAudience, title, body }),
      });
      const data = await res.json();
      if (res.ok) {
        setMessage("✅ تم إرسال الإشعار بنجاح لجميع المستخدمين المستهدفين.");
        setTitle("");
        setBody("");
      } else {
        setMessage(`❌ خطأ: ${data.error}`);
      }
    } catch (err) {
      setMessage("❌ فشل الاتصال بالخادم");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div dir="rtl" className="max-w-2xl mx-auto space-y-6 animate-fade-in-up">
      <div className="text-center mb-8">
        <h1 className="text-3xl font-black text-white mb-2">إرسال إشعارات جماعية 📢</h1>
        <p className="text-gray-400">تواصل مع الكباتن والعملاء عبر Push Notifications بضغطة زر</p>
      </div>

      <div className="bg-[var(--color-card)] border border-white/5 shadow-2xl rounded-3xl p-8">
        <form onSubmit={handleSend} className="space-y-6">
          <div>
            <label className="block text-sm font-bold text-gray-400 mb-2">الفئة المستهدفة</label>
            <div className="grid grid-cols-3 gap-3">
              {[
                { id: "all", label: "الجميع (ركاب + كباتن)" },
                { id: "driver", label: "الكباتن فقط" },
                { id: "passenger", label: "العملاء فقط" },
              ].map((opt) => (
                <button
                  key={opt.id}
                  type="button"
                  onClick={() => setTargetAudience(opt.id)}
                  className={`py-3 px-4 rounded-xl text-sm font-bold border transition-all ${
                    targetAudience === opt.id
                      ? "bg-[var(--color-brand-500)]/20 border-[var(--color-brand-500)] text-[var(--color-brand-500)]"
                      : "bg-[#0B0F19] border-white/5 text-gray-400 hover:border-white/20"
                  }`}
                >
                  {opt.label}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-sm font-bold text-gray-400 mb-2">عنوان الإشعار</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="مثال: خصم 50% على رحلاتك اليوم!"
              className="w-full bg-[#0B0F19] border border-white/10 rounded-xl px-5 py-4 text-white placeholder-gray-600 focus:outline-none focus:border-[var(--color-brand-500)] text-sm font-bold"
            />
          </div>

          <div>
            <label className="block text-sm font-bold text-gray-400 mb-2">محتوى الإشعار</label>
            <textarea
              value={body}
              onChange={(e) => setBody(e.target.value)}
              placeholder="اكتب رسالتك هنا..."
              rows={4}
              className="w-full bg-[#0B0F19] border border-white/10 rounded-xl px-5 py-4 text-white placeholder-gray-600 focus:outline-none focus:border-[var(--color-brand-500)] text-sm font-bold resize-none"
            />
          </div>

          {message && (
            <div className={`p-4 rounded-xl text-sm font-bold ${message.includes("✅") ? "bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] border border-[var(--color-brand-500)]/20" : "bg-red-500/10 text-red-400 border border-red-500/20"}`}>
              {message}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-[var(--color-brand-500)] hover:bg-[var(--color-brand-600)] disabled:opacity-50 text-[#0B0F19] font-black py-4 rounded-xl text-lg transition-all active:scale-95 shadow-[0_0_20px_rgba(0,200,83,0.2)]"
          >
            {loading ? "جاري الإرسال..." : "إرسال الإشعار الآن 🚀"}
          </button>
        </form>
      </div>
    </div>
  );
}

"use client";

import { useEffect, useState } from "react";

export default function SystemLogsPage() {
  const [logs, setLogs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [category, setCategory] = useState("");

  const getToken = () => localStorage.getItem("evo_admin_token") || "";

  const fetchLogs = async (cat?: string) => {
    setLoading(true);
    try {
      const q = cat ? `?category=${cat}` : "";
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/system-logs${q}`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      const data = await res.json();
      setLogs(data.logs || []);
    } catch { setLogs([]); }
    finally { setLoading(false); }
  };

  useEffect(() => { fetchLogs(); }, []);

  const CATS = [
    { key: "", label: "الكل" },
    { key: "system", label: "⚙️ نظام" },
    { key: "payment", label: "💳 دفع" },
    { key: "notification", label: "📢 إشعارات" },
    { key: "gps", label: "📍 GPS" },
  ];

  return (
    <div dir="rtl" className="space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-black text-white">سجل النظام 📋</h1>
          <p className="text-gray-400 text-sm mt-1">أخطاء النظام، الدفع، الإشعارات، و GPS</p>
        </div>
      </div>

      <div className="flex gap-2 flex-wrap">
        {CATS.map(c => (
          <button key={c.key} onClick={() => { setCategory(c.key); fetchLogs(c.key); }}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${category === c.key ? 'bg-[var(--color-brand-500)] text-[#0B0F19]' : 'bg-white/5 text-gray-400 hover:bg-white/10'}`}>
            {c.label}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="flex items-center justify-center h-40"><div className="w-8 h-8 border-4 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" /></div>
      ) : logs.length === 0 ? (
        <div className="bg-[var(--color-card)] rounded-3xl p-8 text-center text-gray-500">✅ لا توجد أخطاء مسجلة</div>
      ) : (
        <div className="bg-[var(--color-card)] border border-white/5 rounded-3xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-white/5 bg-[#0B0F19]/40">
                  <th className="px-4 py-3 text-right text-gray-400 font-bold">التصنيف</th>
                  <th className="px-4 py-3 text-right text-gray-400 font-bold">المستوى</th>
                  <th className="px-4 py-3 text-right text-gray-400 font-bold">الرسالة</th>
                  <th className="px-4 py-3 text-right text-gray-400 font-bold">الوقت</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {logs.map((log: any) => (
                  <tr key={log.id} className="hover:bg-white/5">
                    <td className="px-4 py-3 text-xs font-bold text-gray-300">{log.category}</td>
                    <td className="px-4 py-3">
                      <span className={`text-xs font-bold px-2 py-1 rounded-full ${log.level==='error'?'bg-red-500/10 text-red-400':log.level==='warn'?'bg-amber-500/10 text-amber-400':'bg-blue-500/10 text-blue-400'}`}>
                        {log.level}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-gray-300 max-w-md truncate">{log.message}</td>
                    <td className="px-4 py-3 text-xs text-gray-500 font-cy-bold">{new Date(log.created_at).toLocaleString("ar-JO")}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}

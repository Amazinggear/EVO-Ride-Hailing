"use client";

import { useEffect, useState } from "react";

interface FinancialSummary {
  totalRevenue: number; totalCommission: number; totalRides: number;
  avgFarePerRide: number; activeDrivers: number; growthRate: number;
}

interface Transaction {
  id: string; full_name?: string; type: string; amount: number; created_at: string;
}

export default function FinancialReportsPage() {
  const [summary, setSummary] = useState<FinancialSummary>({ totalRevenue: 0, totalCommission: 0, totalRides: 0, avgFarePerRide: 0, activeDrivers: 0, growthRate: 0 });
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [txnLoading, setTxnLoading] = useState(true);
  const [error, setError] = useState("");

  const getToken = () => localStorage.getItem("evo_admin_token") || "";

  useEffect(() => {
    const token = getToken();
    if (!token) { setLoading(false); setTxnLoading(false); return; }

    setLoading(true);
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/financials/summary`, {
      headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${token}` },
    })
      .then(r => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        return r.json();
      })
      .then(d => {
        if (d.summary) {
          const s = d.summary;
          const rev = parseFloat(s.total_revenue) || 0;
          const rides = parseInt(s.total_rides) || 0;
          setSummary({
            totalRevenue: rev,
            totalCommission: parseFloat(s.total_commission) || 0,
            totalRides: rides,
            avgFarePerRide: rides > 0 ? rev / rides : 0,
            activeDrivers: parseInt(s.unique_earners) || 0,
            growthRate: 0,
          });
        }
      })
      .catch(err => {
        console.error("Financial summary error:", err);
        setError("تعذّر تحميل الملخص المالي");
      })
      .finally(() => setLoading(false));

    setTxnLoading(true);
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/financials/transactions?limit=20`, {
      headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${token}` },
    })
      .then(r => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        return r.json();
      })
      .then(d => {
        // Normalize amount: PostgreSQL DECIMAL comes back as string — convert to number
        const txns = (d.transactions || []).map((t: Record<string, unknown>) => ({
          ...t,
          amount: parseFloat(String(t.amount)) || 0,
        }));
        setTransactions(txns);
      })
      .catch(err => console.error("Transactions error:", err))
      .finally(() => setTxnLoading(false));
  }, []);

  return (
    <div className="space-y-6" dir="rtl">
      <div>
        <h1 className="text-2xl font-bold text-white">التقارير المالية</h1>
        <p className="text-sm text-gray-400 mt-1">تحليل الإيرادات والعمولات من قاعدة البيانات</p>
      </div>

      {error && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-2xl px-5 py-4 text-red-400 text-sm font-bold flex items-center gap-3">
          <span>⚠️</span> {error}
          <button onClick={() => window.location.reload()} className="mr-auto underline hover:text-red-300">إعادة المحاولة</button>
        </div>
      )}

      {loading ? (
        <div className="flex justify-center py-12"><div className="w-8 h-8 border-4 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" /></div>
      ) : (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            { label: "إجمالي الإيرادات", value: `${summary.totalRevenue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} د.أ`, icon: "💰", color: "text-emerald-400", border: "border-emerald-500/20" },
            { label: "صافي العمولات", value: `${summary.totalCommission.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} د.أ`, icon: "📊", color: "text-blue-400", border: "border-blue-500/20" },
            { label: "إجمالي الرحلات", value: summary.totalRides.toLocaleString('en-US'), icon: "🚗", color: "text-purple-400", border: "border-purple-500/20" },
            { label: "الكباتن النشطين", value: summary.activeDrivers.toString(), icon: "👨‍✈️", color: "text-amber-400", border: "border-amber-500/20" },
          ].map((card, i) => (
            <div key={i} className={`bg-[var(--color-card)] rounded-2xl p-5 border ${card.border}`}>
              <span className="text-2xl">{card.icon}</span>
              <p className={`text-2xl font-bold ${card.color} mt-2`}>{card.value}</p>
              <p className="text-xs text-gray-400 mt-1">{card.label}</p>
            </div>
          ))}
        </div>
      )}

      <div className="bg-[var(--color-card)] rounded-3xl p-8 border border-white/5 text-center">
        <div className="text-5xl mb-4">📊</div>
        <h3 className="text-white font-bold text-lg mb-2">الرسوم البيانية</h3>
        <p className="text-gray-400 text-sm">
          {summary.totalRides > 0
            ? `تتوفر ${summary.totalRides} رحلة للتحليل البياني`
            : "ستظهر المخططات فور بدء استقبال الرحلات"}
        </p>
      </div>

      {/* REAL TRANSACTIONS FROM DATABASE */}
      <div className="bg-[var(--color-card)] rounded-3xl p-6 border border-white/5">
        <h3 className="font-bold text-white mb-6">آخر المعاملات المالية</h3>
        {txnLoading ? (
          <div className="flex justify-center py-8"><div className="w-6 h-6 border-2 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" /></div>
        ) : transactions.length === 0 ? (
          <p className="text-gray-500 text-center py-8">لا توجد معاملات مالية بعد</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm text-right">
              <thead>
                <tr className="text-gray-500 text-xs border-b border-white/5">
                  <th className="pb-3 px-2 font-bold">الكابتن</th>
                  <th className="pb-3 px-2 font-bold text-center">النوع</th>
                  <th className="pb-3 px-2 font-bold text-center">المبلغ</th>
                  <th className="pb-3 px-2 font-bold text-center">التاريخ</th>
                </tr>
              </thead>
              <tbody>
                {transactions.map((txn, i) => {
                  // amount is already normalized to number in fetch handler
                  const amt = typeof txn.amount === 'number' ? txn.amount : parseFloat(String(txn.amount)) || 0;
                  return (
                    <tr key={txn.id || i} className="border-b border-white/5 last:border-0 hover:bg-white/5">
                      <td className="py-3 px-2 text-gray-300 font-bold text-xs">{txn.full_name || '—'}</td>
                      <td className="py-3 px-2 text-center">
                        <span className={`px-2 py-0.5 rounded-full text-xs font-bold border ${
                          txn.type?.includes("recharge") ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/30" :
                          txn.type?.includes("commission") ? "bg-orange-500/10 text-orange-400 border-orange-500/30" :
                          "bg-white/5 text-gray-400 border-white/10"
                        }`}>
                          {txn.type?.includes("recharge") ? "شحن" : txn.type?.includes("commission") ? "عمولة" : txn.type}
                        </span>
                      </td>
                      <td className={`py-3 px-2 text-center font-bold text-xs ${amt > 0 ? "text-emerald-400" : "text-red-400"}`}>
                        {amt > 0 ? "+" : ""}{amt.toFixed(2)} د.أ
                      </td>
                      <td className="py-3 px-2 text-center text-gray-500 text-xs">
                        {new Date(txn.created_at).toLocaleDateString("ar-JO", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

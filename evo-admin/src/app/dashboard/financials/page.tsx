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

      <TransactionChart transactions={transactions} />

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

function TransactionChart({ transactions }: { transactions: Transaction[] }) {
  if (transactions.length === 0) {
    return (
      <div className="bg-[var(--color-card)] rounded-3xl p-8 border border-white/5 text-center">
        <div className="text-5xl mb-4">📊</div>
        <h3 className="text-white font-bold text-lg mb-2">الرسوم البيانية للمصروفات</h3>
        <p className="text-gray-400 text-sm">ستظهر المخططات فور بدء العمليات المالية وتسجيل الرحلات</p>
      </div>
    );
  }

  // Take the last 10 transactions (chronologically, oldest first to show a timeline trend)
  const sorted = [...transactions].reverse().slice(-10);
  const maxAmt = Math.max(...sorted.map(t => Math.abs(t.amount)), 1);
  const minAmt = Math.min(...sorted.map(t => Math.abs(t.amount)), 0);

  const width = 600;
  const height = 180;
  const paddingX = 40;
  const paddingY = 25;

  const points = sorted.map((t, i) => {
    const x = paddingX + (i * (width - paddingX * 2)) / (sorted.length - 1 || 1);
    const y = height - paddingY - ((Math.abs(t.amount) - minAmt) * (height - paddingY * 2)) / (maxAmt - minAmt || 1);
    return {
      x,
      y,
      amount: t.amount,
      type: t.type,
      date: new Date(t.created_at).toLocaleDateString("ar-JO", { day: 'numeric', month: 'short' }),
      name: t.full_name || "شحن"
    };
  });

  const linePath = points.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`).join(' ');
  const areaPath = points.length > 0
    ? `${linePath} L ${points[points.length - 1].x} ${height - paddingY} L ${points[0].x} ${height - paddingY} Z`
    : '';

  return (
    <div className="bg-[var(--color-card)] rounded-3xl p-6 border border-white/5 relative overflow-hidden group">
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_left,_var(--tw-gradient-stops))] from-[var(--color-brand-500)]/5 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none" />
      <div className="flex justify-between items-center mb-6">
        <span className="text-xs text-gray-500 font-mono">آخر {sorted.length} عمليات</span>
        <h3 className="text-white font-bold text-lg">مخطط حركة المعاملات الحية 📈</h3>
      </div>
      
      <div className="relative w-full h-[200px]">
        <svg viewBox={`0 0 ${width} ${height}`} className="w-full h-full overflow-visible">
          <defs>
            <linearGradient id="glowGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="var(--color-brand-500)" stopOpacity="0.25" />
              <stop offset="100%" stopColor="var(--color-brand-500)" stopOpacity="0" />
            </linearGradient>
          </defs>

          {/* Grid lines */}
          <line x1={paddingX} y1={paddingY} x2={width - paddingX} y2={paddingY} stroke="rgba(255,255,255,0.03)" strokeDasharray="3" />
          <line x1={paddingX} y1={height/2} x2={width - paddingX} y2={height/2} stroke="rgba(255,255,255,0.03)" strokeDasharray="3" />
          <line x1={paddingX} y1={height - paddingY} x2={width - paddingX} y2={height - paddingY} stroke="rgba(255,255,255,0.08)" />

          {/* Area under the line */}
          {areaPath && <path d={areaPath} fill="url(#glowGrad)" />}

          {/* Line Path */}
          {linePath && (
            <path
              d={linePath}
              fill="none"
              stroke="var(--color-brand-500)"
              strokeWidth="3"
              strokeLinecap="round"
              strokeLinejoin="round"
              className="drop-shadow-[0_0_8px_rgba(0,200,83,0.5)]"
            />
          )}

          {/* Data Points */}
          {points.map((p, i) => {
            const isRecharge = p.type?.includes("recharge");
            const color = isRecharge ? "#00C853" : "#FF9100";
            return (
              <g key={i} className="group/point cursor-pointer">
                {/* Invisible hover area */}
                <circle cx={p.x} cy={p.y} r="14" fill="transparent" />
                
                {/* Actual point */}
                <circle
                  cx={p.x}
                  cy={p.y}
                  r="5"
                  fill="#0B0F19"
                  stroke={color}
                  strokeWidth="2.5"
                  className="transition-all duration-300 group-hover/point:r-7 group-hover/point:stroke-white"
                />

                {/* Date Label on X Axis */}
                <text
                  x={p.x}
                  y={height - 6}
                  fill="rgba(255,255,255,0.4)"
                  fontSize="9"
                  fontFamily="monospace"
                  textAnchor="middle"
                  className="pointer-events-none"
                >
                  {p.date}
                </text>

                {/* Tooltip Overlay */}
                <g className="opacity-0 group-hover/point:opacity-100 transition-opacity duration-300 pointer-events-none">
                  {/* Tooltip Background */}
                  <rect
                    x={p.x - 55}
                    y={p.y - 45}
                    width="110"
                    height="32"
                    rx="6"
                    fill="#0B1221"
                    stroke="rgba(255,255,255,0.1)"
                    strokeWidth="1"
                  />
                  {/* Tooltip text - Name */}
                  <text
                    x={p.x}
                    y={p.y - 33}
                    fill="rgba(255,255,255,0.6)"
                    fontSize="7.5"
                    fontWeight="bold"
                    textAnchor="middle"
                  >
                    {p.name.length > 18 ? p.name.slice(0, 16) + ".." : p.name}
                  </text>
                  {/* Tooltip text - Value */}
                  <text
                    x={p.x}
                    y={p.y - 20}
                    fill={isRecharge ? "#00E676" : "#FF9100"}
                    fontSize="8.5"
                    fontWeight="bold"
                    textAnchor="middle"
                  >
                    {isRecharge ? "+" : "-"}{Math.abs(p.amount).toFixed(2)} د.أ
                  </text>
                </g>
              </g>
            );
          })}
        </svg>
      </div>
    </div>
  );
}

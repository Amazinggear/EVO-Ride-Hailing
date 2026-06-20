"use client";

import { useEffect, useState } from "react";
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from "recharts";

// ────── Types ──────
interface FinancialSummary {
  totalRevenue: number;
  totalCommission: number;
  totalRides: number;
  avgFarePerRide: number;
  activeDrivers: number;
  growthRate: number;
}

// ────── Mock Data ──────
type ChartItem = { label: string; revenue: number; commission: number; rides: number };

const weeklyRevenue: ChartItem[] = [
  { label: "الأحد", revenue: 1250, commission: 162, rides: 42 },
  { label: "الإثنين", revenue: 1840, commission: 239, rides: 61 },
  { label: "الثلاثاء", revenue: 2200, commission: 286, rides: 73 },
  { label: "الأربعاء", revenue: 1580, commission: 205, rides: 52 },
  { label: "الخميس", revenue: 1920, commission: 249, rides: 64 },
  { label: "الجمعة", revenue: 3100, commission: 403, rides: 103 },
  { label: "السبت", revenue: 2750, commission: 357, rides: 91 },
];

const monthlyRevenue: ChartItem[] = [
  { label: "يناير", revenue: 28400, commission: 3692, rides: 948 },
  { label: "فبراير", revenue: 32100, commission: 4173, rides: 1070 },
  { label: "مارس", revenue: 38700, commission: 5031, rides: 1290 },
  { label: "أبريل", revenue: 41200, commission: 5356, rides: 1373 },
  { label: "مايو", revenue: 44800, commission: 5824, rides: 1493 },
  { label: "يونيو", revenue: 52300, commission: 6799, rides: 1743 },
];

const carTypeBreakdown = [
  { name: "EV Sedan", value: 38, color: "#00C853" },
  { name: "EV Mini", value: 28, color: "#00B0FF" },
  { name: "EV Taxi", value: 20, color: "#FFAB40" },
  { name: "EV SUV", value: 9, color: "#EA80FC" },
  { name: "EV Luxury", value: 5, color: "#FF5252" },
];

const recentTransactions = [
  { id: "#TXN-1821", driver: "أحمد الخالدي", plate: "12-34567", type: "commission_deduction", amount: -1.82, date: "23:06", status: "مكتمل" },
  { id: "#TXN-1820", driver: "محمد العبادي", plate: "87-12345", type: "admin_recharge", amount: 20.0, date: "22:50", status: "مكتمل" },
  { id: "#TXN-1819", driver: "خالد النجار", plate: "56-78901", type: "commission_deduction", amount: -2.34, date: "22:42", status: "مكتمل" },
  { id: "#TXN-1818", driver: "عمر الشرع", plate: "33-45678", type: "commission_deduction", amount: -1.95, date: "22:31", status: "مكتمل" },
  { id: "#TXN-1817", driver: "سلمى الحموري", plate: "77-90123", type: "admin_recharge", amount: 15.0, date: "22:20", status: "مكتمل" },
  { id: "#TXN-1816", driver: "ياسر الحمود", plate: "45-67890", type: "commission_deduction", amount: -0.91, date: "22:15", status: "مكتمل" },
];

const MOCK_SUMMARY: FinancialSummary = {
  totalRevenue: 52300,
  totalCommission: 6799,
  totalRides: 1743,
  avgFarePerRide: 5.8,
  activeDrivers: 47,
  growthRate: 16.7,
};

type Period = "week" | "month";

const CustomTooltip = ({ active, payload, label }: any) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-[#0B0F19] border border-white/10 rounded-xl p-3 text-xs shadow-xl backdrop-blur-sm" dir="rtl">
        <p className="font-bold text-white mb-2">{label}</p>
        {payload.map((p: any, i: number) => (
          <p key={i} style={{ color: p.color }} className="font-bold">
            {p.name}: {typeof p.value === "number" && p.name.includes("إيراد")
              ? `${p.value.toLocaleString('en-US')} د.أ`
              : p.value}
          </p>
        ))}
      </div>
    );
  }
  return null;
};

export default function FinancialReportsPage() {
  const [period, setPeriod] = useState<Period>("week");
  const [summary, setSummary] = useState<FinancialSummary>(MOCK_SUMMARY);
  const [loading, setLoading] = useState(false);
  const chartData = period === "week" ? weeklyRevenue : monthlyRevenue;
  const xKey = "label";

  useEffect(() => {
    const token = localStorage.getItem("evo_admin_token");
    if (!token) return;
    setLoading(true);
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/financials/summary`, {
      headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${token}` },
    })
      .then(r => r.json())
      .then(d => {
        if (d.summary) {
          const s = d.summary;
          setSummary({
            totalRevenue: parseFloat(s.total_revenue) || 0,
            totalCommission: parseFloat(s.total_commission) || 0,
            totalRides: parseInt(s.total_rides) || 0,
            avgFarePerRide: s.total_rides > 0 ? parseFloat(s.total_revenue) / parseInt(s.total_rides) : 0,
            activeDrivers: parseInt(s.unique_earners) || 0,
            growthRate: 0,
          });
        }
      })
      .catch(() => setSummary(MOCK_SUMMARY))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="space-y-6" dir="rtl">
      {/* HEADER */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white">التقارير المالية</h1>
          <p className="text-sm text-gray-400 mt-1">تحليل شامل للإيرادات والعمولات والنمو</p>
        </div>
        <div className="flex items-center gap-2 bg-[var(--color-card)] border border-white/5 p-1 rounded-xl">
          {(["week", "month"] as const).map(p => (
            <button
              key={p}
              onClick={() => setPeriod(p)}
              className={`px-4 py-2 rounded-lg text-sm font-bold transition-all ${
                period === p
                  ? "bg-[var(--color-brand-500)] text-white shadow-[0_0_10px_rgba(0,200,83,0.3)]"
                  : "text-gray-400 hover:text-white"
              }`}
            >
              {p === "week" ? "أسبوعي" : "شهري"}
            </button>
          ))}
        </div>
      </div>

      {/* SUMMARY CARDS */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          {
            label: "إجمالي الإيرادات",
            value: `${summary.totalRevenue.toLocaleString('en-US')} د.أ`,
            sub: `+${summary.growthRate}% عن الشهر الماضي`,
            icon: "💰",
            color: "text-emerald-400",
            border: "border-emerald-500/20",
          },
          {
            label: "صافي العمولات",
            value: `${summary.totalCommission.toLocaleString('en-US')} د.أ`,
            sub: "13% من إجمالي الرحلات",
            icon: "📊",
            color: "text-blue-400",
            border: "border-blue-500/20",
          },
          {
            label: "إجمالي الرحلات",
            value: summary.totalRides.toLocaleString('en-US'),
            sub: `متوسط ${summary.avgFarePerRide.toFixed(2)} د.أ / رحلة`,
            icon: "🚗",
            color: "text-purple-400",
            border: "border-purple-500/20",
          },
          {
            label: "الكباتن المسجلون",
            value: summary.activeDrivers,
            sub: "منضمون للشبكة",
            icon: "👨‍✈️",
            color: "text-amber-400",
            border: "border-amber-500/20",
          },
        ].map((card, i) => (
          <div key={i} className={`bg-[var(--color-card)] rounded-2xl p-5 border ${card.border} relative overflow-hidden`}>
            <div className="flex justify-between items-start mb-3">
              <span className="text-2xl">{card.icon}</span>
              <span className={`text-xs font-bold px-2 py-1 rounded-full bg-white/5 ${card.color}`}>
                ↑
              </span>
            </div>
            <p className={`text-2xl font-bold ${card.color} mb-1`}>{card.value}</p>
            <p className="text-xs text-gray-400 font-bold">{card.label}</p>
            <p className="text-xs text-gray-600 mt-1">{card.sub}</p>
          </div>
        ))}
      </div>

      {/* CHARTS ROW */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        
        {/* Revenue Chart */}
        <div className="lg:col-span-2 bg-[var(--color-card)] rounded-3xl p-6 border border-white/5">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="font-bold text-white">الإيرادات والعمولات</h3>
              <p className="text-xs text-gray-400 mt-1">{period === "week" ? "آخر 7 أيام" : "آخر 6 أشهر"}</p>
            </div>
            <div className="flex gap-4 text-xs">
              <span className="flex items-center gap-1.5 text-gray-400">
                <span className="w-3 h-3 rounded-full bg-[var(--color-brand-500)] inline-block" /> إيرادات
              </span>
              <span className="flex items-center gap-1.5 text-gray-400">
                <span className="w-3 h-3 rounded-full bg-blue-400 inline-block" /> عمولات
              </span>
            </div>
          </div>
          <div className="h-[280px]" dir="ltr">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={chartData} margin={{ top: 5, right: 10, left: 0, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                <XAxis dataKey={xKey} tick={{ fill: "#6B7280", fontSize: 11 }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fill: "#6B7280", fontSize: 11 }} axisLine={false} tickLine={false} width={55} tickFormatter={v => `${v/1000}k`} />
                <Tooltip content={<CustomTooltip />} />
                <Line type="monotone" dataKey="revenue" name="الإيرادات" stroke="#00C853" strokeWidth={2.5} dot={{ fill: "#00C853", r: 4 }} activeDot={{ r: 6 }} />
                <Line type="monotone" dataKey="commission" name="العمولات" stroke="#60A5FA" strokeWidth={2} strokeDasharray="5 5" dot={{ fill: "#60A5FA", r: 3 }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Car Type Breakdown Pie */}
        <div className="bg-[var(--color-card)] rounded-3xl p-6 border border-white/5">
          <h3 className="font-bold text-white mb-6">توزيع نوع المركبة</h3>
          <div className="h-[200px]" dir="ltr">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={carTypeBreakdown} cx="50%" cy="50%" innerRadius={55} outerRadius={80} paddingAngle={3} dataKey="value">
                  {carTypeBreakdown.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip formatter={(v) => `${v}%`} contentStyle={{ background: "#0B0F19", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "12px" }} />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="space-y-2 mt-2">
            {carTypeBreakdown.map((item) => (
              <div key={item.name} className="flex items-center justify-between text-xs">
                <div className="flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full" style={{ background: item.color }} />
                  <span className="text-gray-400">{item.name}</span>
                </div>
                <span className="font-bold text-white">{item.value}%</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* RIDES BAR CHART */}
      <div className="bg-[var(--color-card)] rounded-3xl p-6 border border-white/5">
        <h3 className="font-bold text-white mb-6">حجم الرحلات اليومي</h3>
        <div className="h-[200px]" dir="ltr">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={weeklyRevenue} margin={{ top: 5, right: 10, left: 0, bottom: 5 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
              <XAxis dataKey="day" tick={{ fill: "#6B7280", fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: "#6B7280", fontSize: 11 }} axisLine={false} tickLine={false} />
              <Tooltip contentStyle={{ background: "#0B0F19", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "12px" }} />
              <Bar dataKey="rides" name="عدد الرحلات" radius={[6, 6, 0, 0]} barSize={35}>
                {weeklyRevenue.map((_, i) => (
                  <Cell key={i} fill={i === 5 ? "#00C853" : "#00C85330"} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* RECENT TRANSACTIONS TABLE */}
      <div className="bg-[var(--color-card)] rounded-3xl p-6 border border-white/5">
        <div className="flex items-center justify-between mb-6">
          <h3 className="font-bold text-white">آخر المعاملات المالية</h3>
          <button className="text-xs text-[var(--color-brand-500)] hover:underline font-bold">عرض الكل ←</button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm text-right">
            <thead>
              <tr className="text-gray-500 text-xs border-b border-white/5">
                <th className="pb-3 px-2 font-bold">المرجع</th>
                <th className="pb-3 px-2 font-bold">الكابتن</th>
                <th className="pb-3 px-2 font-bold">اللوحة</th>
                <th className="pb-3 px-2 font-bold text-center">النوع</th>
                <th className="pb-3 px-2 font-bold text-center">المبلغ</th>
                <th className="pb-3 px-2 font-bold text-center">الوقت</th>
                <th className="pb-3 px-2 font-bold text-center">الحالة</th>
              </tr>
            </thead>
            <tbody>
              {recentTransactions.map((txn, i) => (
                <tr key={i} className="border-b border-white/5 last:border-0 hover:bg-white/2 transition-colors">
                  <td className="py-3 px-2 text-xs font-bold text-[var(--color-brand-500)]" dir="ltr">{txn.id}</td>
                  <td className="py-3 px-2 text-gray-300 font-bold">{txn.driver}</td>
                  <td className="py-3 px-2 text-gray-400" dir="ltr">{txn.plate}</td>
                  <td className="py-3 px-2 text-center">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-bold border ${
                      txn.type === "admin_recharge"
                        ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/30"
                        : "bg-orange-500/10 text-orange-400 border-orange-500/30"
                    }`}>
                      {txn.type === "admin_recharge" ? "شحن" : "عمولة"}
                    </span>
                  </td>
                  <td className={`py-3 px-2 text-center font-bold ${txn.amount > 0 ? "text-emerald-400" : "text-red-400"}`}>
                    {txn.amount > 0 ? "+" : ""}{txn.amount.toFixed(2)} د.أ
                  </td>
                  <td className="py-3 px-2 text-center text-gray-500 text-xs">{txn.date}</td>
                  <td className="py-3 px-2 text-center">
                    <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] border border-[var(--color-brand-500)]/20">
                      {txn.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

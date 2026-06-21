"use client";

import { useEffect, useState } from "react";
import Link from "next/link";

interface Stats {
  totalDrivers: number; activeDrivers: number; pendingApprovals: number;
  totalRidesToday: number; totalRevenueToday: number; totalCommissionToday: number;
  totalPassengers: number; activeRides: number;
  onlinePassengers: number; onlineStaff: number;
}

export default function DashboardHome() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchStats = () => {
    const token = localStorage.getItem("evo_admin_token");
    if (!token) { setLoading(false); return; }
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/dashboard/stats`, {
      headers: { Authorization: `Bearer ${token}` },
    })
      .then(r => r.json())
      .then(d => setStats({
        totalDrivers: d.total_drivers || 0, activeDrivers: d.online_drivers || 0,
        pendingApprovals: d.pending_approvals || 0, totalRidesToday: d.rides_today || 0,
        totalRevenueToday: d.revenue_today || 0, totalCommissionToday: (d.revenue_today || 0) * 0.13,
        totalPassengers: d.total_passengers || 0, activeRides: d.active_rides || 0,
        onlinePassengers: d.online_passengers || 0, onlineStaff: d.online_staff || 0,
      }))
      .catch(() => setStats(null))
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchStats(); const i = setInterval(fetchStats, 15000); return () => clearInterval(i); }, []);

  if (loading) return <div className="flex items-center justify-center h-[60vh]"><div className="w-10 h-10 border-4 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" /></div>;

  const s = stats || { totalDrivers:0,activeDrivers:0,pendingApprovals:0,totalRidesToday:0,totalRevenueToday:0,totalCommissionToday:0,totalPassengers:0,activeRides:0,onlinePassengers:0,onlineStaff:0 };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">📊 لوحة المراقبة المباشرة</h1>
        <p className="text-sm text-gray-400 mt-1">نظرة عامة على مؤشرات الأداء الرئيسية — تحديث كل ١٥ ثانية</p>
      </div>

      {/* LIVE ONLINE COUNTERS */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
        {[
          { label: "🚗 كباتن متصلين", value: s.activeDrivers, color: "border-[var(--color-brand-500)]/30 text-[var(--color-brand-500)]", bg: "bg-[var(--color-brand-500)]/10" },
          { label: "👥 عملاء متصلين", value: s.onlinePassengers, color: "border-blue-500/30 text-blue-400", bg: "bg-blue-500/10" },
          { label: "🛡️ موظفين متصلين", value: s.onlineStaff, color: "border-purple-500/30 text-purple-400", bg: "bg-purple-500/10" },
          { label: "📍 رحلات نشطة", value: s.activeRides, color: "border-amber-500/30 text-amber-400", bg: "bg-amber-500/10" },
          { label: "⏳ طلبات معلقة", value: s.pendingApprovals, color: "border-orange-500/30 text-orange-400", bg: "bg-orange-500/10" },
          { label: "💰 إيراد اليوم", value: `${s.totalRevenueToday.toFixed(1)}`, color: "border-green-500/30 text-green-400", bg: "bg-green-500/10" },
        ].map(c => (
          <div key={c.label} className={`bg-[var(--color-card)] rounded-2xl p-4 border ${c.color} text-center`}>
            <div className={`w-10 h-10 ${c.bg} rounded-xl flex items-center justify-center mx-auto mb-2 text-lg`}>
              {c.value}
            </div>
            <p className="text-gray-400 text-xs font-bold">{c.label}</p>
          </div>
        ))}
      </div>

      {/* QUICK LINKS */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {[
          { href: "/dashboard/drivers", icon: "🚗", label: "الكباتن", count: s.totalDrivers },
          { href: "/dashboard/rides", icon: "📍", label: "الرحلات", count: s.totalRidesToday },
          { href: "/dashboard/wallets", icon: "💰", label: "المحافظ", count: "—" },
          { href: "/dashboard/admins", icon: "🛡️", label: "الموظفين", count: s.onlineStaff },
        ].map(l => (
          <Link key={l.href} href={l.href} className="bg-[var(--color-card)] border border-white/5 rounded-2xl p-4 hover:border-[var(--color-brand-500)]/30 transition-all group">
            <div className="flex items-center justify-between">
              <span className="text-2xl">{l.icon}</span>
              <span className="text-white font-cy-bold text-lg">{l.count}</span>
            </div>
            <p className="text-gray-400 text-xs font-bold mt-2">{l.label}</p>
          </Link>
        ))}
      </div>

      {/* ALERT PREVIEW + PLACEHOLDER */}
      <div className="bg-[var(--color-card)] rounded-3xl p-6 border border-white/5 text-center">
        <div className="text-4xl mb-3">🚨</div>
        <h3 className="text-white font-bold text-lg mb-2">مركز التنبيهات</h3>
        <p className="text-gray-400 text-sm">ستظهر هنا التنبيهات فور بدء النشاط: وثائق قاربت تنتهي، تقييمات منخفضة، إلغاءات متكررة، شكاوى.</p>
        <p className="text-gray-600 text-xs mt-3">آخر تحديث: {new Date().toLocaleTimeString("ar-JO")}</p>
      </div>
    </div>
  );
}

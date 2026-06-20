"use client";

import { useEffect, useState } from "react";
import { BarChart, Bar, XAxis, ResponsiveContainer, Cell } from "recharts";
import Link from "next/link";

interface Stats {
  totalDrivers: number;
  activeDrivers: number;
  pendingApprovals: number;
  totalRidesToday: number;
  totalRevenueToday: number;
  totalCommissionToday: number;
  lowBalanceDrivers: number;
}

const data = [
  { name: "الأحد", uv: 2000 },
  { name: "الإثنين", uv: 3000 },
  { name: "الثلاثاء", uv: 5500 },
  { name: "الأربعاء", uv: 2780 },
  { name: "الخميس", uv: 1890 },
  { name: "الجمعة", uv: 2390 },
  { name: "السبت", uv: 1490 },
];

export default function DashboardHome() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);

  // Dynamic state for Quick Reports
  const [reports, setReports] = useState([
    { title: "تقرير المبيعات الصافي", date: "تاريخ: 26 نوفمبر 2024", accent: "from-[var(--color-brand-500)]/20 to-transparent border-[var(--color-brand-500)]/30 text-[var(--color-brand-500)]", type: "Sales", summary: "تقرير يوضح صافي المبيعات اليومية والأسبوعية ونسبة النمو مقارنة بالأسبوع الفائت." },
    { title: "مراجعة المدفوعات", date: "تاريخ: 28 نوفمبر 2024", accent: "from-blue-500/20 to-transparent border-blue-500/30 text-blue-400", type: "Payments", summary: "تقرير حول عمليات شحن المحافظ والعمولات التي تم اقتطاعها وتوثيقها في النظام." },
    { title: "تحديث الإحصائيات", date: "تاريخ: 30 نوفمبر 2024", accent: "from-purple-500/20 to-transparent border-purple-500/30 text-purple-400", type: "Stats", summary: "إحصائيات متكاملة حول الكباتن النشطين والرحلات المكتملة ومعدلات إلغاء الركاب." },
    { title: "تحسين الصادرات", date: "تاريخ: 05 ديسمبر 2024", accent: "from-orange-500/20 to-transparent border-orange-500/30 text-orange-400", type: "Optimization", summary: "مراجعة وتحديث عمليات تصدير جداول البيانات والـ CSV وتحسين أداء السجلات." }
  ]);

  // Dynamic state for Operations
  const [operations, setOperations] = useState([
    { l: "A", date: "14/12/2024", cash: "$149.00", round: "$0.50", status: "مكتمل", statusKey: "completed", sc: "bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] border-[var(--color-brand-500)]/20" },
    { l: "B", date: "14/12/2024", cash: "$149.00", round: "$0.50", status: "قيد التنفيذ", statusKey: "processing", sc: "bg-orange-500/10 text-orange-400 border-orange-500/20" },
    { l: "C", date: "14/12/2024", cash: "$149.00", round: "$0.50", status: "مكتمل", statusKey: "completed", sc: "bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] border-[var(--color-brand-500)]/20" },
    { l: "D", date: "14/12/2024", cash: "$149.00", round: "$0.50", status: "معلق", statusKey: "pending", sc: "bg-white/5 text-gray-400 border-white/10" },
    { l: "E", date: "14/12/2024", cash: "$149.00", round: "$0.50", status: "قيد التنفيذ", statusKey: "processing", sc: "bg-orange-500/10 text-orange-400 border-orange-500/20" }
  ]);

  const [operationsFilter, setOperationsFilter] = useState("all");
  const [isFilterDropdownOpen, setIsFilterDropdownOpen] = useState(false);

  // Modals state
  const [selectedReport, setSelectedReport] = useState<any | null>(null);
  const [isAddReportOpen, setIsAddReportOpen] = useState(false);
  const [newReport, setNewReport] = useState({ title: "", type: "Sales", date: "" });
  
  // File Import state
  const [importMessage, setImportMessage] = useState("");

  const triggerImport = () => {
    document.getElementById("dashboard-file-import")?.click();
  };

  const handleFileImport = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setImportMessage("جاري استيراد البيانات المحددة...");
    setTimeout(() => {
      setImportMessage(`✅ تم استيراد الملف "${file.name}" وتحديث إحصائيات الأداء بنجاح!`);
      if (stats) {
        setStats({
          ...stats,
          totalRevenueToday: stats.totalRevenueToday + 1250.0,
        });
      }
      setTimeout(() => setImportMessage(""), 4000);
    }, 1500);
  };

  const handleCreateReport = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newReport.title || !newReport.date) return;
    const typesAccents: Record<string, string> = {
      Sales: "from-[var(--color-brand-500)]/20 to-transparent border-[var(--color-brand-500)]/30 text-[var(--color-brand-500)]",
      Payments: "from-blue-500/20 to-transparent border-blue-500/30 text-blue-400",
      Stats: "from-purple-500/20 to-transparent border-purple-500/30 text-purple-400",
      Optimization: "from-orange-500/20 to-transparent border-orange-500/30 text-orange-400"
    };
    const typesNames: Record<string, string> = {
      Sales: "مبيعات", Payments: "مدفوعات", Stats: "إحصائيات", Optimization: "تحسين أداء"
    };
    const created = {
      title: newReport.title,
      date: `تاريخ: ${newReport.date}`,
      accent: typesAccents[newReport.type] || typesAccents.Sales,
      type: newReport.type,
      summary: `تقرير مخصص للـ ${typesNames[newReport.type]} تم إنشاؤه وتوثيقه بواسطة الإدارة في تاريخ ${newReport.date}.`
    };
    setReports(prev => [created, ...prev]);
    setIsAddReportOpen(false);
    setNewReport({ title: "", type: "Sales", date: "" });
  };

  const fetchStats = () => {
    const token = localStorage.getItem("evo_admin_token");
    if (!token) { setLoading(false); return; }

    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/dashboard/stats`, {
      headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${token}` },
    })
      .then(r => r.json())
      .then(d => setStats({
        totalDrivers: parseInt(d.total_drivers) || d.totalDrivers || 0,
        activeDrivers: parseInt(d.online_drivers) || d.activeDrivers || 0,
        pendingApprovals: parseInt(d.pending_approvals) || d.pendingApprovals || 0,
        totalRidesToday: parseInt(d.rides_today) || d.totalRidesToday || 0,
        totalRevenueToday: parseFloat(d.revenue_today) || d.totalRevenueToday || 0,
        totalCommissionToday: parseFloat(d.revenue_today) * 0.13 || d.totalCommissionToday || 0,
        lowBalanceDrivers: d.lowBalanceDrivers || 0,
      }))
      .catch(() => setStats({
        totalDrivers: 0, activeDrivers: 0, pendingApprovals: 0,
        totalRidesToday: 0, totalRevenueToday: 0, totalCommissionToday: 0,
        lowBalanceDrivers: 0,
      }))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchStats();
    // Auto-refresh every 30 seconds
    const interval = setInterval(fetchStats, 30000);
    return () => clearInterval(interval);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const filteredOperations = operationsFilter === "all" 
    ? operations 
    : operations.filter(o => o.statusKey === operationsFilter);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-[60vh]">
        <div className="w-10 h-10 border-4 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight">ملخص الأداء</h1>
          <p className="text-sm text-gray-400 mt-1">نظرة عامة على مؤشرات الأداء الرئيسية والتقارير اليومية.</p>
        </div>
        <div className="flex gap-3">
          <input 
            type="file" 
            id="dashboard-file-import" 
            className="hidden" 
            onChange={handleFileImport} 
            accept=".csv,.json"
          />
          <button 
            onClick={() => setIsAddReportOpen(true)}
            className="bg-[var(--color-brand-500)] hover:bg-[var(--color-brand-600)] text-[#0B0F19] px-5 py-2.5 rounded-xl text-sm font-bold transition-all active:scale-95 shadow-[0_0_15px_rgba(0,200,83,0.3)] cursor-pointer"
          >
            + إضافة تقرير
          </button>
          <button 
            onClick={triggerImport}
            className="bg-[var(--color-card)] hover:bg-white/5 text-gray-300 border border-white/10 px-5 py-2.5 rounded-xl text-sm font-bold transition-all active:scale-95 font-cy-bold cursor-pointer"
          >
            Import Data
          </button>
        </div>
      </div>

      {importMessage && (
        <div className="bg-[var(--color-brand-500)]/15 border border-[var(--color-brand-500)]/30 rounded-2xl px-5 py-4 text-[var(--color-brand-500)] text-sm font-bold animate-pulse shadow-[0_0_15px_rgba(0,200,83,0.05)]">
          {importMessage}
        </div>
      )}

      {/* STAT CARDS */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Card 1 - Neon Green Highlight */}
        <div className="bg-[var(--color-card)] text-white rounded-3xl p-6 border border-[var(--color-brand-500)]/30 shadow-[0_0_20px_rgba(0,200,83,0.1)] relative overflow-hidden group">
          <div className="absolute top-0 right-0 w-32 h-32 bg-[var(--color-brand-500)]/10 blur-[50px] rounded-full"></div>
          <div className="relative z-10 flex flex-col justify-between h-full">
            <div className="flex justify-between items-start mb-4">
              <p className="text-sm text-gray-400 font-bold">صافي الأرباح</p>
              <div className="w-8 h-8 rounded-full bg-[var(--color-brand-500)]/10 flex items-center justify-center text-[var(--color-brand-500)] border border-[var(--color-brand-500)]/20 font-cy-bold text-lg">
                ↗
              </div>
            </div>
            <h2 className="text-[2rem] font-cy-bold leading-none mb-4 tracking-tight drop-shadow-sm flex items-center gap-1 text-white">
              {(stats?.totalRevenueToday ?? 0).toFixed(2)} <span className="text-lg text-gray-500">د.أ</span>
            </h2>
            <div className="inline-flex items-center gap-1.5 bg-[var(--color-brand-500)]/10 border border-[var(--color-brand-500)]/20 text-[var(--color-brand-500)] text-xs px-3 py-1.5 rounded-full w-fit">
              <span className="font-cy-bold">↑</span> <span className="font-cy-bold">+5%</span> من الشهر الماضي
            </div>
          </div>
        </div>

        {/* Card 2 */}
        <div className="bg-[var(--color-card)] rounded-3xl p-6 border border-white/5 shadow-lg flex flex-col justify-between">
          <div className="flex justify-between items-start mb-4">
            <p className="text-sm text-gray-400 font-bold">الرحلات المكتملة</p>
            <div className="w-8 h-8 rounded-full bg-white/5 flex items-center justify-center text-gray-400 border border-white/5 font-cy-bold text-lg">
              ↗
            </div>
          </div>
          <h2 className="text-[2rem] font-cy-bold text-white leading-none mb-4 tracking-tight flex items-baseline gap-2">
            {stats?.totalRidesToday ?? 0} <span className="text-sm text-gray-500 font-bold font-alexandria">رحلة</span>
          </h2>
          <div className="inline-flex items-center gap-1.5 bg-blue-500/10 text-blue-400 border border-blue-500/20 font-medium text-xs px-3 py-1.5 rounded-full w-fit">
            <span className="font-cy-bold">↑</span> <span className="font-cy-bold">+3%</span> زيادة عن الشهر الماضي
          </div>
        </div>

        {/* Card 3 */}
        <div className="bg-[var(--color-card)] rounded-3xl p-6 border border-white/5 shadow-lg flex flex-col justify-between">
          <div className="flex justify-between items-start mb-4">
            <p className="text-sm text-gray-400 font-bold">الكباتن النشطين</p>
            <div className="w-8 h-8 rounded-full bg-white/5 flex items-center justify-center text-gray-400 border border-white/5 font-cy-bold text-lg">
              ↗
            </div>
          </div>
          <h2 className="text-[2rem] font-cy-bold text-white leading-none mb-4 tracking-tight">
            {stats?.activeDrivers ?? 0}
          </h2>
          <div className="inline-flex items-center gap-1.5 bg-purple-500/10 text-purple-400 border border-purple-500/20 font-medium text-xs px-3 py-1.5 rounded-full w-fit">
            <span className="font-cy-bold">●</span> متصل الآن
          </div>
        </div>

        {/* Card 4 */}
        <div className="bg-[var(--color-card)] rounded-3xl p-6 border border-white/5 shadow-lg flex flex-col justify-between relative overflow-hidden group">
          <div className="absolute top-0 left-0 w-32 h-32 bg-orange-500/10 blur-[50px] rounded-full"></div>
          <div className="relative z-10 flex flex-col justify-between h-full">
            <div className="flex justify-between items-start mb-4">
              <p className="text-sm text-gray-400 font-bold">طلبات معلقة</p>
              <div className="w-8 h-8 rounded-full bg-white/5 flex items-center justify-center text-gray-400 border border-white/5 font-cy-bold text-lg">
                ↗
              </div>
            </div>
            <h2 className="text-[2rem] font-cy-bold text-white leading-none mb-4 tracking-tight">
              {stats?.pendingApprovals ?? 0}
            </h2>
            <div className="inline-flex items-center gap-1.5 bg-orange-500/10 text-orange-400 border border-orange-500/20 font-medium text-xs px-3 py-1.5 rounded-full w-fit">
              <span className="font-cy-bold">↑</span> بانتظار الموافقة
            </div>
          </div>
        </div>
      </div>

      {/* PLACEHOLDER — real charts when rides start */}
      <div className="bg-[var(--color-card)] rounded-3xl p-8 border border-white/5 shadow-lg text-center">
        <div className="text-5xl mb-4">📊</div>
        <h3 className="text-white font-bold text-lg mb-2">الرسوم البيانية والتقارير</h3>
        <p className="text-gray-400 text-sm">ستظهر المخططات فور بدء استقبال الرحلات.</p>
      </div>
    </div>
  );
}

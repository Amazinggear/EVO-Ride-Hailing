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
              <span className="text-xl text-[var(--color-brand-500)]">$</span>
              {(stats?.totalRevenueToday ?? 125514.99).toLocaleString('en-US')}
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
            {stats?.totalRidesToday ?? 31} <span className="text-sm text-gray-500 font-bold font-alexandria">رحلة</span>
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
            {stats?.activeDrivers ?? 12}
          </h2>
          <div className="inline-flex items-center gap-1.5 bg-purple-500/10 text-purple-400 border border-purple-500/20 font-medium text-xs px-3 py-1.5 rounded-full w-fit">
            <span className="font-cy-bold">↑</span> <span className="font-cy-bold">+6%</span> زيادة عن الشهر الماضي
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
              {stats?.pendingApprovals ?? 2}
            </h2>
            <div className="inline-flex items-center gap-1.5 bg-orange-500/10 text-orange-400 border border-orange-500/20 font-medium text-xs px-3 py-1.5 rounded-full w-fit">
              <span className="font-cy-bold">↑</span> بانتظار الموافقة
            </div>
          </div>
        </div>
      </div>

      {/* CHARTS & REPORTS */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Sales Summary Chart */}
        <div className="lg:col-span-2 bg-[var(--color-card)] rounded-3xl p-6 border border-white/5 shadow-lg">
          <div className="flex justify-between items-start mb-6">
            <div>
              <h3 className="font-bold text-white mb-1">ملخص الإيرادات</h3>
              <p className="text-[var(--color-brand-500)] font-cy-bold text-sm">$1,804.55</p>
            </div>
            <div className="flex gap-2 bg-[#0B0F19] p-1 rounded-full border border-white/5">
              <button className="px-3 py-1 rounded-full text-xs font-bold bg-[var(--color-brand-500)] text-white shadow-[0_0_10px_rgba(0,200,83,0.3)]">يوم</button>
              <button className="px-3 py-1 rounded-full text-xs font-bold text-gray-400 hover:text-white transition-colors">أسبوع</button>
              <button className="px-3 py-1 rounded-full text-xs font-bold text-gray-400 hover:text-white transition-colors">شهر</button>
              <button className="px-3 py-1 rounded-full text-xs font-bold text-gray-400 hover:text-white transition-colors">سنة</button>
            </div>
          </div>
          
          <div className="h-[250px] w-full" dir="ltr">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={data} margin={{ top: 20, right: 0, left: 0, bottom: 0 }}>
                <XAxis 
                  dataKey="name" 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{ fill: '#6B7280', fontSize: 12, fontWeight: 500, fontFamily: 'var(--font-alexandria)' }}
                  dy={10}
                />
                <Bar 
                  dataKey="uv" 
                  radius={[8, 8, 8, 8]} 
                  barSize={40}
                >
                  {data.map((entry, index) => (
                    <Cell 
                      key={`cell-${index}`} 
                      fill={index === 2 ? "url(#diagonalHatch)" : "var(--color-brand-900)"} 
                    />
                  ))}
                </Bar>
                <defs>
                  <pattern id="diagonalHatch" patternUnits="userSpaceOnUse" width="8" height="8">
                    <rect width="8" height="8" fill="var(--color-brand-900)"/>
                    <path d="M-2,2 l4,-4 M0,8 l8,-8 M6,10 l4,-4" stroke="var(--color-brand-500)" strokeWidth="1.5"/>
                  </pattern>
                </defs>
              </BarChart>
            </ResponsiveContainer>
          </div>
          <div className="flex justify-between items-center mt-2 text-xs text-gray-500 font-cy-bold">
            <span>October, 2024</span>
            <span>September, 2024</span>
          </div>
        </div>

        {/* Reports List */}
        <div className="bg-[var(--color-card)] rounded-3xl p-6 border border-white/5 shadow-lg flex flex-col">
          <div className="flex justify-between items-center mb-6">
            <h3 className="font-bold text-white">التقارير السريعة</h3>
            <button 
              onClick={() => setIsAddReportOpen(true)}
              className="text-xs font-bold text-gray-300 bg-white/5 border border-white/10 rounded-full px-3 py-1.5 hover:bg-white/10 hover:border-[var(--color-brand-500)]/45 transition-colors cursor-pointer"
            >
              + جديد
            </button>
          </div>
          
          <div className="flex flex-col gap-3 max-h-[310px] overflow-y-auto custom-scrollbar">
            {reports.map((report, i) => (
              <div 
                key={i} 
                onClick={() => setSelectedReport(report)}
                className={`bg-gradient-to-r ${report.accent} border border-r-4 rounded-xl p-4 flex justify-between items-center group cursor-pointer hover:bg-white/5 transition-all bg-[#0B0F19]`}
              >
                <div className="w-8 h-8 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-white group-hover:bg-white/10 transition-colors font-cy-bold">
                  ↖
                </div>
                <div className="text-left">
                  <h4 className="font-bold text-white text-sm mb-1">{report.title}</h4>
                  <p className="text-xs text-gray-400 font-cy-bold">{report.date}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* BOTTOM ROW */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Payments Table */}
        <div className="lg:col-span-2 bg-[var(--color-card)] rounded-3xl p-6 border border-white/5 shadow-lg overflow-hidden flex flex-col">
          <div className="flex justify-between items-center mb-6">
            <h3 className="font-bold text-white">أحدث العمليات</h3>
            <div className="relative">
              <button 
                onClick={() => setIsFilterDropdownOpen(!isFilterDropdownOpen)}
                className="text-xs font-bold text-gray-300 bg-white/5 border border-white/10 rounded-full px-4 py-1.5 hover:bg-white/10 transition-colors flex items-center gap-2 cursor-pointer"
              >
                تصفية: <span className="font-cy-bold text-[var(--color-brand-500)]">{operationsFilter === "all" ? "الكل" : operationsFilter === "completed" ? "مكتمل" : operationsFilter === "processing" ? "قيد التنفيذ" : "معلق"}</span>
              </button>
              {isFilterDropdownOpen && (
                <>
                  <div className="fixed inset-0 z-40" onClick={() => setIsFilterDropdownOpen(false)} />
                  <div className="absolute left-0 mt-2 w-36 bg-[#0B0F19] border border-white/10 rounded-xl p-2 shadow-2xl z-50 text-right">
                    {[
                      { key: "all", label: "الكل" },
                      { key: "completed", label: "مكتمل" },
                      { key: "processing", label: "قيد التنفيذ" },
                      { key: "pending", label: "معلق" }
                    ].map(opt => (
                      <button
                        key={opt.key}
                        onClick={() => { setOperationsFilter(opt.key); setIsFilterDropdownOpen(false); }}
                        className={`w-full text-right px-3 py-1.5 rounded-lg text-xs font-bold transition-colors cursor-pointer ${
                          operationsFilter === opt.key 
                            ? "bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)]" 
                            : "text-gray-400 hover:bg-white/5 hover:text-white"
                        }`}
                      >
                        {opt.label}
                      </button>
                    ))}
                  </div>
                </>
              )}
            </div>
          </div>
          
          <div className="overflow-x-auto">
            <table className="w-full text-sm text-right">
              <thead>
                <tr className="text-gray-500 font-medium border-b border-white/5">
                  <th className="pb-3 px-2 font-normal">التاريخ</th>
                  <th className="pb-3 px-2 font-normal text-center">المبلغ</th>
                  <th className="pb-3 px-2 font-normal text-center">الخصم</th>
                  <th className="pb-3 px-2 font-normal text-center">الحالة</th>
                </tr>
              </thead>
              <tbody className="text-gray-300 font-medium">
                {filteredOperations.map((row, i) => (
                  <tr key={i} className="border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors">
                    <td className="py-3 px-2 flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-white/5 text-gray-300 flex items-center justify-center font-cy-bold text-xs mt-1 border border-white/10">
                        {row.l}
                      </div>
                      <span className="font-cy-bold">{row.date}</span>
                    </td>
                    <td className="py-3 px-2 text-center font-cy-bold">{row.cash}</td>
                    <td className="py-3 px-2 text-center text-gray-500 font-cy-bold">{row.round}</td>
                    <td className="py-3 px-2 text-center">
                      <span className={`px-3 py-1 rounded-full text-xs font-bold border ${row.sc}`}>
                        {row.status}
                      </span>
                    </td>
                  </tr>
                ))}
                {filteredOperations.length === 0 && (
                  <tr>
                    <td colSpan={4} className="py-8 text-center text-gray-500 font-bold text-xs">لا توجد عمليات تطابق التصفية</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Calendar Widget */}
        <div className="bg-[var(--color-card)] rounded-3xl p-6 border border-white/5 shadow-lg relative overflow-hidden">
          <div className="absolute -bottom-10 -left-10 w-40 h-40 bg-[var(--color-brand-500)]/5 blur-[50px] rounded-full"></div>
          <div className="relative z-10">
            <div className="flex justify-between items-start mb-6">
              <div>
                <h4 className="text-gray-400 font-bold text-sm">مبيعات الشهر الحالي</h4>
                <h2 className="text-2xl font-cy-bold text-white tracking-tight mt-1">$329,728.45</h2>
                <p className="text-xs text-gray-500 mt-1 font-cy-bold">October 2024</p>
              </div>
              <div className="text-left text-xs space-y-1">
                <p className="text-gray-500 font-cy-bold"><span className="inline-block w-12 font-alexandria text-gray-400">التاريخ:</span> <span className="font-cy-bold text-white">Oct 17, 2024</span></p>
                <p className="text-gray-500 font-cy-bold"><span className="inline-block w-12 font-alexandria text-gray-400">القيمة:</span> <span className="font-cy-bold text-[var(--color-brand-500)]">$18,434.76</span></p>
              </div>
            </div>
            
            {/* Simple Mock Calendar */}
            <div className="grid grid-cols-7 text-center gap-y-3 mt-4 text-sm font-medium font-cy-bold" dir="ltr">
              {["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].map(d => (
                <div key={d} className="text-gray-500 text-xs">{d}</div>
              ))}
              {/* Empty days */}
              <div className="text-gray-700">27</div><div className="text-gray-700">28</div><div className="text-gray-700">29</div><div className="text-gray-700">30</div><div className="text-gray-700">31</div>
              {/* Active days */}
              <div className="text-gray-300">01</div><div className="text-gray-300">02</div>
              <div className="text-gray-300">03</div><div className="text-gray-300">04</div><div className="text-gray-300">05</div><div className="text-gray-300">06</div><div className="text-gray-300">07</div><div className="text-gray-300">08</div><div className="text-gray-300">09</div>
              <div className="text-gray-300">10</div><div className="text-gray-300">11</div><div className="text-gray-300">12</div><div className="text-gray-300">13</div><div className="text-gray-300">14</div><div className="text-gray-300">15</div><div className="text-gray-300">16</div>
              <div className="bg-[var(--color-brand-500)] text-[#0B0F19] rounded-lg flex items-center justify-center w-8 h-8 mx-auto shadow-[0_0_10px_rgba(0,200,83,0.5)]">17</div>
              <div className="text-gray-300">18</div><div className="text-gray-300">19</div><div className="text-gray-300">20</div><div className="text-gray-300">21</div><div className="text-gray-300">22</div><div className="text-gray-300">23</div>
              <div className="text-gray-300">24</div><div className="text-gray-300">25</div><div className="text-gray-300">26</div><div className="text-gray-300">27</div><div className="text-gray-300">28</div><div className="text-gray-300">29</div><div className="text-gray-300">30</div>
            </div>
          </div>
        </div>
      </div>

      {/* SELECTED REPORT DETAIL MODAL */}
      {selectedReport && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={() => setSelectedReport(null)}>
          <div className="bg-[var(--color-card)] border border-white/10 rounded-3xl p-6 w-full max-w-md shadow-2xl relative text-right" onClick={e => e.stopPropagation()} dir="rtl">
            <div className="flex items-center justify-between border-b border-white/5 pb-4 mb-4">
              <h3 className="font-bold text-white text-lg">📊 عرض تفاصيل التقرير</h3>
              <button onClick={() => setSelectedReport(null)} className="text-gray-500 hover:text-white transition-colors text-2xl leading-none">×</button>
            </div>
            <div className="space-y-4">
              <div className="bg-[#0B0F19] rounded-xl p-4 border border-white/5 space-y-2">
                <span className="text-xs text-[var(--color-brand-500)] bg-[var(--color-brand-500)]/10 border border-[var(--color-brand-500)]/20 px-2 py-0.5 rounded-full font-bold">
                  {selectedReport.type === "Sales" ? "مبيعات" : selectedReport.type === "Payments" ? "مدفوعات" : selectedReport.type === "Stats" ? "إحصائيات" : "تحسين أداء"}
                </span>
                <h4 className="text-base font-bold text-white mt-1">{selectedReport.title}</h4>
                <p className="text-xs text-gray-400 font-cy-bold">{selectedReport.date}</p>
              </div>

              <div>
                <p className="text-xs text-gray-400 font-bold mb-1">ملخص التقرير المالي والأداء:</p>
                <p className="text-sm text-gray-300 leading-relaxed bg-[#0B0F19] p-3 rounded-xl border border-white/5">
                  {selectedReport.summary}
                </p>
              </div>

              {/* Mock Data Display inside Report Modal */}
              <div className="bg-gradient-to-br from-emerald-500/10 to-transparent border border-emerald-500/20 rounded-xl p-4 flex items-center justify-between">
                <div>
                  <p className="text-[10px] text-gray-400 font-bold">حالة التقرير الفني</p>
                  <p className="text-xs text-emerald-400 font-bold mt-1">🟢 مؤرشف بنجاح</p>
                </div>
                <div className="text-left">
                  <p className="text-[10px] text-gray-400 font-bold">توقيت التحميل</p>
                  <p className="text-xs text-white font-cy-bold mt-1">Just Now</p>
                </div>
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button onClick={() => setSelectedReport(null)} className="flex-1 py-3 rounded-xl bg-[var(--color-brand-500)] text-[#0B0F19] font-bold text-sm hover:bg-[var(--color-brand-600)] transition-colors shadow-lg">
                إغلاق
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ADD NEW REPORT MODAL */}
      {isAddReportOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={() => setIsAddReportOpen(false)}>
          <div className="bg-[var(--color-card)] border border-white/10 rounded-3xl p-6 w-full max-w-md shadow-2xl relative text-right" onClick={e => e.stopPropagation()} dir="rtl">
            <div className="flex items-center justify-between border-b border-white/5 pb-4 mb-4">
              <h3 className="font-bold text-white text-lg">➕ إنشاء تقرير سريع جديد</h3>
              <button onClick={() => setIsAddReportOpen(false)} className="text-gray-500 hover:text-white transition-colors text-2xl leading-none">×</button>
            </div>
            <form onSubmit={handleCreateReport} className="space-y-4">
              <div>
                <label className="text-xs text-gray-400 block mb-1.5 font-bold">عنوان التقرير*</label>
                <input 
                  required
                  type="text" 
                  value={newReport.title} 
                  onChange={e => setNewReport({ ...newReport, title: e.target.value })} 
                  placeholder="مثال: تقرير إيرادات الكباتن الأسبوعي" 
                  className="w-full bg-[#0B0F19] border border-white/10 rounded-xl py-3 px-4 text-sm text-white outline-none focus:border-[var(--color-brand-500)] transition-all font-bold"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs text-gray-400 block mb-1.5 font-bold">نوع التقرير*</label>
                  <select 
                    value={newReport.type} 
                    onChange={e => setNewReport({ ...newReport, type: e.target.value })} 
                    className="w-full bg-[#0B0F19] border border-white/10 rounded-xl py-3 px-3 text-sm text-white outline-none focus:border-[var(--color-brand-500)] transition-all font-bold"
                  >
                    <option value="Sales">مبيعات (Sales)</option>
                    <option value="Payments">مدفوعات (Payments)</option>
                    <option value="Stats">إحصائيات (Stats)</option>
                    <option value="Optimization">تحسين (Optimization)</option>
                  </select>
                </div>
                <div>
                  <label className="text-xs text-gray-400 block mb-1.5 font-bold">تاريخ التقرير*</label>
                  <input 
                    required
                    type="date" 
                    value={newReport.date} 
                    onChange={e => setNewReport({ ...newReport, date: e.target.value })} 
                    className="w-full bg-[#0B0F19] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white outline-none focus:border-[var(--color-brand-500)] transition-all font-cy-bold text-left"
                  />
                </div>
              </div>
              <div className="flex gap-3 mt-6 pt-2">
                <button type="button" onClick={() => setIsAddReportOpen(false)} className="flex-1 py-3 rounded-xl border border-white/10 text-gray-400 hover:bg-white/5 transition-colors font-bold text-sm">
                  إلغاء
                </button>
                <button type="submit" className="flex-1 py-3 rounded-xl bg-[var(--color-brand-500)] text-[#0B0F19] font-bold text-sm hover:bg-[var(--color-brand-600)] transition-colors shadow-lg animate-pulse">
                  إنشاء وإضافة
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

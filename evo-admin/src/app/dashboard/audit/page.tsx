"use client";

import { useEffect, useState, useCallback } from "react";

interface AuditLog {
  id: string;
  adminId: string;
  adminName: string;
  action: string;
  targetType: string;
  targetId?: string;
  details?: Record<string, unknown>;
  ipAddress?: string;
  createdAt: string;
}

const ACTION_CONFIG: Record<string, { label: string; icon: string; color: string; bg: string }> = {
  driver_approved: { label: "موافقة كابتن", icon: "✅", color: "text-emerald-400", bg: "bg-emerald-500/10 border-emerald-500/20" },
  driver_rejected: { label: "رفض كابتن", icon: "❌", color: "text-red-400", bg: "bg-red-500/10 border-red-500/20" },
  wallet_recharged: { label: "شحن محفظة", icon: "💰", color: "text-blue-400", bg: "bg-blue-500/10 border-blue-500/20" },
  pricing_updated: { label: "تحديث الأسعار", icon: "💲", color: "text-amber-400", bg: "bg-amber-500/10 border-amber-500/20" },
  promo_created: { label: "إنشاء كود خصم", icon: "🎟️", color: "text-purple-400", bg: "bg-purple-500/10 border-purple-500/20" },
  promo_updated: { label: "تعديل كود خصم", icon: "✏️", color: "text-purple-300", bg: "bg-purple-500/10 border-purple-500/20" },
  user_suspended: { label: "إيقاف مستخدم", icon: "🚫", color: "text-orange-400", bg: "bg-orange-500/10 border-orange-500/20" },
  more_info_requested: { label: "طلب معلومات إضافية", icon: "📋", color: "text-gray-400", bg: "bg-white/5 border-white/10" },
  admin_login: { label: "تسجيل دخول", icon: "🔐", color: "text-cyan-400", bg: "bg-cyan-500/10 border-cyan-500/20" },
  surge_zone_created: { label: "إنشاء منطقة ارتفاع", icon: "📍", color: "text-pink-400", bg: "bg-pink-500/10 border-pink-500/20" },
};

const MOCK_LOGS: AuditLog[] = [
  { id: "1", adminId: "admin-1", adminName: "الإدارة العامة", action: "driver_approved", targetType: "driver", targetId: "d-123", details: { driverName: "أحمد الخالدي", plate: "12-34567" }, ipAddress: "192.168.1.10", createdAt: "2026-06-17T23:01:00Z" },
  { id: "2", adminId: "admin-1", adminName: "الإدارة العامة", action: "wallet_recharged", targetType: "driver", targetId: "d-456", details: { plate: "87-12345", amount: 20, driverName: "محمد العبادي" }, ipAddress: "192.168.1.10", createdAt: "2026-06-17T22:50:00Z" },
  { id: "3", adminId: "admin-1", adminName: "الإدارة العامة", action: "pricing_updated", targetType: "pricing", details: { carType: "ev_mini", oldBaseFare: 0.35, newBaseFare: 0.40 }, ipAddress: "192.168.1.10", createdAt: "2026-06-17T22:30:00Z" },
  { id: "4", adminId: "admin-1", adminName: "الإدارة العامة", action: "driver_rejected", targetType: "driver", targetId: "d-789", details: { driverName: "ناصر الربيع", reason: "المستندات غير مكتملة" }, ipAddress: "192.168.1.10", createdAt: "2026-06-17T22:15:00Z" },
  { id: "5", adminId: "admin-1", adminName: "الإدارة العامة", action: "promo_created", targetType: "promo", details: { code: "EVO20", discountType: "percentage", value: 20 }, ipAddress: "192.168.1.10", createdAt: "2026-06-17T21:55:00Z" },
  { id: "6", adminId: "admin-1", adminName: "الإدارة العامة", action: "wallet_recharged", targetType: "driver", details: { plate: "33-45678", amount: 15, driverName: "عمر الشرع" }, ipAddress: "192.168.1.10", createdAt: "2026-06-17T21:40:00Z" },
  { id: "7", adminId: "admin-1", adminName: "الإدارة العامة", action: "more_info_requested", targetType: "driver", details: { driverName: "سلمى الحموري", note: "صورة الرخصة غير واضحة" }, ipAddress: "192.168.1.10", createdAt: "2026-06-17T21:20:00Z" },
  { id: "8", adminId: "admin-1", adminName: "الإدارة العامة", action: "surge_zone_created", targetType: "surge_zone", details: { zoneName: "دوار الداخلية", multiplier: 1.5 }, ipAddress: "192.168.1.10", createdAt: "2026-06-17T20:58:00Z" },
  { id: "9", adminId: "admin-1", adminName: "الإدارة العامة", action: "driver_approved", targetType: "driver", details: { driverName: "خالد النجار", plate: "56-78901" }, ipAddress: "192.168.1.10", createdAt: "2026-06-17T20:30:00Z" },
  { id: "10", adminId: "admin-1", adminName: "الإدارة العامة", action: "admin_login", targetType: "system", details: { browser: "Chrome 120" }, ipAddress: "192.168.1.10", createdAt: "2026-06-17T20:00:00Z" },
  { id: "11", adminId: "admin-1", adminName: "الإدارة العامة", action: "promo_updated", targetType: "promo", details: { code: "WELCOME10", change: "تمديد الصلاحية حتى 2026-12-31" }, ipAddress: "192.168.1.10", createdAt: "2026-06-17T19:45:00Z" },
  { id: "12", adminId: "admin-1", adminName: "الإدارة العامة", action: "wallet_recharged", targetType: "driver", details: { plate: "45-67890", amount: 25, driverName: "ياسر الحمود" }, ipAddress: "192.168.1.10", createdAt: "2026-06-17T19:20:00Z" },
];

const formatTime = (iso: string) => {
  const d = new Date(iso);
  return d.toLocaleString("ar-JO-u-nu-latn", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });
};

const formatDetails = (details?: Record<string, unknown>) => {
  if (!details) return "—";
  return Object.entries(details)
    .map(([k, v]) => `${k}: ${v}`)
    .join(" | ");
};

type ActionFilter = "all" | keyof typeof ACTION_CONFIG;

export default function AuditLogPage() {
  const [logs, setLogs] = useState<AuditLog[]>(MOCK_LOGS);
  const [filter, setFilter] = useState<ActionFilter>("all");
  const [search, setSearch] = useState("");
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem("evo_admin_token");
    if (!token) return;
    setLoading(true);
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/audit-logs`, {
      headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${token}` },
    })
      .then(r => r.json())
      .then(d => {
        const arr = d.logs || d;
        if (Array.isArray(arr) && arr.length > 0) {
          // Map backend snake_case to frontend camelCase
          setLogs(arr.map((l: any) => ({
            id: l.id,
            adminId: l.admin_id,
            adminName: l.admin_name || 'الإدارة العامة',
            action: l.action,
            targetType: l.target_type,
            targetId: l.target_id,
            details: typeof l.details === 'string' ? JSON.parse(l.details) : l.details,
            ipAddress: l.ip_address,
            createdAt: l.created_at,
          })));
        }
      })
      .catch(() => setLogs(MOCK_LOGS))
      .finally(() => setLoading(false));
  }, []);

  const filtered = logs.filter(log => {
    const matchesFilter = filter === "all" || log.action === filter;
    const matchesSearch =
      !search ||
      log.adminName.includes(search) ||
      log.action.includes(search) ||
      JSON.stringify(log.details || {}).includes(search);
    return matchesFilter && matchesSearch;
  });

  const actionCounts = Object.keys(ACTION_CONFIG).reduce((acc, k) => {
    acc[k] = logs.filter(l => l.action === k).length;
    return acc;
  }, {} as Record<string, number>);

  return (
    <div className="space-y-6" dir="rtl">
      {/* HEADER */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white">سجل التدقيق</h1>
          <p className="text-sm text-gray-400 mt-1">جميع الإجراءات الإدارية مسجّلة ومؤرشفة</p>
        </div>
        <button 
          onClick={() => {
            const rows = [
              ['ID', 'Admin', 'Action', 'Target Type', 'Target ID', 'Details', 'IP', 'Time'],
              ...logs.map(l => [
                l.id, l.adminName, l.action, l.targetType, l.targetId || '',
                JSON.stringify(l.details || {}), l.ipAddress || '', l.createdAt,
              ])
            ];
            const csv = rows.map(r => r.map(c => `"${String(c).replace(/"/g, '""')}"`).join(',')).join('\n');
            const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url; a.download = `evo-audit-${new Date().toISOString().slice(0,10)}.csv`;
            a.click(); URL.revokeObjectURL(url);
          }}
          className="bg-[var(--color-card)] border border-white/10 text-gray-300 px-4 py-2.5 rounded-xl text-sm font-bold hover:bg-white/5 transition-colors flex items-center gap-2 w-fit"
        >
          📤 تصدير CSV
        </button>
      </div>

      {/* FILTERS */}
      <div className="bg-[var(--color-card)] rounded-2xl p-4 border border-white/5">
        {/* Search */}
        <div className="relative mb-4">
          <span className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-500">🔍</span>
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            type="text"
            placeholder="بحث في السجلات..."
            className="w-full bg-[#0B0F19] border border-white/5 rounded-xl py-3 pr-12 pl-4 text-sm text-white outline-none focus:border-[var(--color-brand-500)] transition-all font-alexandria placeholder:text-gray-500"
          />
        </div>
        
        {/* Action Filter Pills */}
        <div className="flex flex-wrap gap-2">
          <button
            onClick={() => setFilter("all")}
            className={`px-3 py-1.5 rounded-full text-xs font-bold border transition-all ${
              filter === "all"
                ? "bg-[var(--color-brand-500)] text-white border-transparent"
                : "bg-white/5 text-gray-400 border-white/10 hover:bg-white/10"
            }`}
          >
            الكل ({logs.length})
          </button>
          {Object.entries(ACTION_CONFIG).map(([key, cfg]) => {
            const count = actionCounts[key] || 0;
            if (count === 0) return null;
            return (
              <button
                key={key}
                onClick={() => setFilter(key as ActionFilter)}
                className={`px-3 py-1.5 rounded-full text-xs font-bold border transition-all ${
                  filter === key ? `${cfg.bg} ${cfg.color}` : "bg-white/5 text-gray-400 border-white/10 hover:bg-white/10"
                }`}
              >
                {cfg.icon} {cfg.label} ({count})
              </button>
            );
          })}
        </div>
      </div>

      {/* LOGS LIST */}
      <div className="space-y-2">
        {loading && (
          <div className="flex items-center justify-center py-10">
            <div className="w-8 h-8 border-4 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" />
          </div>
        )}
        
        {!loading && filtered.length === 0 && (
          <div className="text-center py-16 text-gray-500">
            <p className="text-4xl mb-3">📋</p>
            <p className="text-sm">لا توجد سجلات تطابق البحث</p>
          </div>
        )}

        {!loading && filtered.map((log, i) => {
          const cfg = ACTION_CONFIG[log.action] || {
            label: log.action,
            icon: "📝",
            color: "text-gray-400",
            bg: "bg-white/5 border-white/10",
          };
          const isExpanded = expandedId === log.id;

          return (
            <div
              key={log.id}
              className={`bg-[var(--color-card)] border rounded-2xl transition-all overflow-hidden ${
                isExpanded ? "border-[var(--color-brand-500)]/30" : "border-white/5 hover:border-white/10"
              }`}
            >
              <button
                className="w-full text-right p-4 flex items-center gap-4"
                onClick={() => setExpandedId(isExpanded ? null : log.id)}
              >
                {/* Icon */}
                <div className={`w-10 h-10 rounded-xl flex items-center justify-center text-lg shrink-0 border ${cfg.bg}`}>
                  {cfg.icon}
                </div>

                {/* Content */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className={`text-sm font-bold ${cfg.color}`}>{cfg.label}</span>
                    {log.targetType && (
                      <span className="text-xs text-gray-500 bg-white/5 px-2 py-0.5 rounded-full">{log.targetType}</span>
                    )}
                  </div>
                  <p className="text-xs text-gray-500 mt-0.5 truncate">{formatDetails(log.details)}</p>
                </div>

                {/* Meta */}
                <div className="text-left shrink-0 text-xs text-gray-500 space-y-0.5">
                  <p>{formatTime(log.createdAt)}</p>
                  {log.ipAddress && <p dir="ltr" className="text-gray-600">{log.ipAddress}</p>}
                </div>

                {/* Chevron */}
                <span className={`text-gray-600 transition-transform shrink-0 ${isExpanded ? "rotate-180" : ""}`}>▾</span>
              </button>

              {/* Expanded Details */}
              {isExpanded && (
                <div className="px-4 pb-4 border-t border-white/5 pt-4">
                  <div className="bg-[#0B0F19] rounded-xl p-4 text-xs space-y-2 font-mono">
                    <p><span className="text-gray-500">المعرّف:</span> <span className="text-gray-300" dir="ltr">#{log.id}</span></p>
                    <p><span className="text-gray-500">الإجراء:</span> <span className="text-[var(--color-brand-500)]" dir="ltr">{log.action}</span></p>
                    <p><span className="text-gray-500">المشرف:</span> <span className="text-gray-300">{log.adminName}</span></p>
                    {log.targetId && <p><span className="text-gray-500">الهدف:</span> <span className="text-gray-300" dir="ltr">{log.targetId}</span></p>}
                    {log.ipAddress && <p><span className="text-gray-500">IP:</span> <span className="text-gray-300" dir="ltr">{log.ipAddress}</span></p>}
                    <p><span className="text-gray-500">التوقيت:</span> <span className="text-gray-300" dir="ltr">{log.createdAt}</span></p>
                    {log.details && (
                      <div>
                        <p className="text-gray-500 mb-1">التفاصيل:</p>
                        <pre className="text-[var(--color-brand-500)] bg-black/30 p-2 rounded-lg overflow-x-auto text-xs leading-relaxed">
                          {JSON.stringify(log.details, null, 2)}
                        </pre>
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Pagination hint */}
      {filtered.length > 0 && (
        <div className="text-center text-xs text-gray-600 py-2">
          عرض {filtered.length} من {logs.length} سجل — قم بتوصيل الـ API لعرض المزيد
        </div>
      )}
    </div>
  );
}

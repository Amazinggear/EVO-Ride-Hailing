"use client";

import { useEffect, useState, useCallback } from "react";

interface AdminUser {
  id: string;
  full_name: string;
  email: string;
  admin_role: string;
  created_at: string;
  status: string;
  last_login_at?: string;
  total_hours?: number;
  total_visits?: number;
  last_seen?: string;
}

export default function AdminsPage() {
  const [admins, setAdmins] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ fullName: "", email: "", password: "", phone: "", adminRole: "support" });
  const [formLoading, setFormLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [deleting, setDeleting] = useState<string | null>(null);

  // ── Detail Panel ──
  const [selectedAdmin, setSelectedAdmin] = useState<AdminUser | null>(null);
  const [adminLogs, setAdminLogs] = useState<any[]>([]);
  const [logsLoading, setLogsLoading] = useState(false);

  const getToken = () => localStorage.getItem("evo_admin_token") || "";

  const fetchAdmins = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/admins`, {
        headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${getToken()}` },
      });
      const data = await res.json();
      if (data.admins) {
        setAdmins(data.admins);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAdmins();
  }, [fetchAdmins]);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormLoading(true);
    setMessage("");
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/admins`, {
        method: "POST",
        headers: {
          "Bypass-Tunnel-Reminder": "true",
          Authorization: `Bearer ${getToken()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(form),
      });
      const data = await res.json();
      if (res.ok) {
        setShowForm(false);
        setForm({ fullName: "", email: "", password: "", phone: "", adminRole: "support" });
        fetchAdmins();
      } else {
        setMessage(`❌ خطأ: ${data.error}`);
      }
    } catch (err) {
      setMessage("❌ فشل الاتصال بالخادم");
    } finally {
      setFormLoading(false);
    }
  };

  const updateRole = async (id: string, newRole: string) => {
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/admins/${id}/role`, {
        method: "PATCH",
        headers: {
          "Bypass-Tunnel-Reminder": "true",
          Authorization: `Bearer ${getToken()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ adminRole: newRole }),
      });
      if (res.ok) {
        fetchAdmins();
      } else {
        alert("فشل تحديث الصلاحية");
      }
    } catch (err) {
      alert("حدث خطأ أثناء التحديث");
    }
  };

  const handleDelete = async (id: string, name: string) => {
    if (!confirm(`هل أنت متأكد من حذف "${name}"؟`)) return;
    setDeleting(id);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/admins/${id}`, {
        method: "DELETE",
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      const data = await res.json();
      if (res.ok) {
        setSelectedAdmin(null);
        fetchAdmins();
      } else {
        alert(data.error || "فشل الحذف");
      }
    } catch (err) {
      alert("فشل الاتصال بالخادم");
    } finally {
      setDeleting(null);
    }
  };

  const selectAdmin = async (admin: AdminUser) => {
    if (selectedAdmin?.id === admin.id) {
      setSelectedAdmin(null);
      setAdminLogs([]);
      return;
    }
    setSelectedAdmin(admin);
    setLogsLoading(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/audit-logs?limit=30`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      const data = await res.json();
      // Filter logs for this specific admin
      const filtered = (data.logs || []).filter((l: any) => l.admin_id === admin.id);
      setAdminLogs(filtered);
    } catch { setAdminLogs([]); }
    finally { setLogsLoading(false); }
  };

  const ROLE_LABELS: Record<string, string> = {
    super_admin: "Super Admin (مدير عام)",
    operations: "Operations (عمليات)",
    finance: "Finance (مالية)",
    support: "Support (دعم فني)",
  };

  const timeAgo = (date?: string) => {
    if (!date) return '—';
    const diff = Math.floor((Date.now() - new Date(date).getTime()) / 60000);
    if (diff < 1) return 'الآن';
    if (diff < 60) return `${diff}د`;
    const h = Math.floor(diff / 60);
    if (h < 24) return `${h}س`;
    return `${Math.floor(h / 24)} يوم`;
  };

  const isOnline = (date?: string) => {
    if (!date) return false;
    const diff = Math.floor((Date.now() - new Date(date).getTime()) / 60000);
    return diff < 2; // active if last seen within 2 minutes (ping every 1 min)
  };

  return (
    <>
      <div dir="rtl" className="space-y-6 animate-fade-in-up">
        {/* Header */}
        <div className="flex items-center justify-between flex-wrap gap-4">
          <div>
            <h1 className="text-2xl font-black text-white flex items-center gap-2">
              صلاحيات الموظفين <span className="animate-bounce inline-block">🛡️</span>
            </h1>
            <p className="text-gray-400 text-sm mt-1">إدارة حسابات لوحة التحكم (RBAC)</p>
          </div>
          <button
            onClick={() => setShowForm(true)}
            className="bg-[var(--color-brand-500)] hover:bg-[var(--color-brand-600)] text-[#0B0F19] font-bold px-5 py-2.5 rounded-xl transition-all active:scale-95 flex items-center gap-2 shadow-[0_0_15px_rgba(0,200,83,0.3)]"
          >
            <span>+</span> إضافة موظف
          </button>
        </div>

        {/* Table */}
      {loading ? (
        <div className="flex items-center justify-center h-40">
          <div className="w-8 h-8 border-4 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" />
        </div>
      ) : (
        <div className="flex gap-4">
        <div className="bg-[var(--color-card)] border border-white/5 rounded-3xl overflow-hidden shadow-lg animate-fade-in-up delay-200 flex-1">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-white/5 bg-[#0B0F19]/40">
                  <th className="px-5 py-3 text-right text-gray-500 font-bold">الاسم</th>
                  <th className="px-4 py-3 text-right text-gray-500 font-bold">البريد الإلكتروني</th>
                  <th className="px-4 py-3 text-right text-gray-500 font-bold">الصلاحية</th>
                  <th className="px-4 py-3 text-center text-gray-500 font-bold">تاريخ الإضافة</th>
                  <th className="px-4 py-3 text-center text-gray-500 font-bold">ساعات العمل</th>
                  <th className="px-4 py-3 text-center text-gray-500 font-bold">آخر نشاط</th>
                  <th className="px-4 py-3 text-center text-gray-500 font-bold">حذف</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {admins.map((admin) => (
                  <tr
                    key={admin.id}
                    className={`transition-colors cursor-pointer ${
                      selectedAdmin?.id === admin.id
                        ? 'bg-[var(--color-brand-500)]/10 border-r-2 border-r-[var(--color-brand-500)]'
                        : 'hover:bg-white/5'
                    }`}
                  >
                    <td className="px-5 py-4 font-bold text-white" onClick={() => selectAdmin(admin)}>{admin.full_name}</td>
                    <td className="px-4 py-4 text-gray-300 font-cy-bold" dir="ltr">{admin.email}</td>
                    <td className="px-4 py-4">
                      <select 
                        value={admin.admin_role || "support"} 
                        onChange={(e) => { e.stopPropagation(); updateRole(admin.id, e.target.value); }}
                        onClick={(e) => e.stopPropagation()}
                        className="bg-[#0B0F19] border border-white/10 rounded-lg px-2 py-1 text-white text-xs font-bold outline-none focus:border-[var(--color-brand-500)]"
                      >
                        {Object.entries(ROLE_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                      </select>
                    </td>
                    <td className="px-4 py-4 text-center text-gray-500 text-xs font-cy-bold">
                      {new Date(admin.created_at).toLocaleDateString("ar-EG-u-nu-latn")}
                    </td>
                    <td className="px-4 py-4 text-center text-white font-cy-bold text-xs">
                      {admin.total_hours ? `${admin.total_hours} س` : '—'}
                    </td>
                    <td className="px-4 py-4 text-center text-xs font-bold">
                      {isOnline(admin.last_seen) ? (
                        <span className="text-green-400">🟢 الآن</span>
                      ) : (
                        <span className="text-gray-400">{timeAgo(admin.last_seen)}</span>
                      )}
                    </td>
                    <td className="px-4 py-4 text-center">
                      <button
                        onClick={(e) => { e.stopPropagation(); handleDelete(admin.id, admin.full_name); }}
                        disabled={deleting === admin.id}
                        className="text-red-400 hover:text-red-300 hover:bg-red-500/10 rounded-lg px-2 py-1 text-xs font-bold transition-colors disabled:opacity-50"
                        title="حذف"
                      >
                        {deleting === admin.id ? "⏳" : "🗑️"}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Detail Panel */}
        {selectedAdmin && (
          <div className="w-80 shrink-0 bg-[var(--color-card)] border border-white/5 rounded-3xl p-6 space-y-5 self-start sticky top-24 shadow-xl animate-fade-in-up">
            <div className="flex items-center justify-between">
              <h3 className="font-black text-white text-lg">تحليل الموظف</h3>
              <button onClick={() => { setSelectedAdmin(null); setAdminLogs([]); }} className="text-gray-500 hover:text-white text-2xl leading-none">×</button>
            </div>

            {/* Admin Info */}
            <div className="bg-[#0B0F19] rounded-2xl p-4 space-y-3">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-xl bg-[var(--color-brand-500)]/10 border border-[var(--color-brand-500)]/20 flex items-center justify-center font-black text-lg text-[var(--color-brand-500)]">
                  {selectedAdmin.full_name?.charAt(0)}
                </div>
                <div>
                  <p className="text-white font-bold">{selectedAdmin.full_name}</p>
                  <p className="text-gray-500 text-xs" dir="ltr">{selectedAdmin.email}</p>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-2 text-xs">
                <div className="bg-white/5 rounded-lg p-2 text-center">
                  <p className="text-gray-500">الصلاحية</p>
                  <p className="text-[var(--color-brand-500)] font-bold">{ROLE_LABELS[selectedAdmin.admin_role]}</p>
                </div>
                <div className="bg-white/5 rounded-lg p-2 text-center">
                  <p className="text-gray-500">الحالة</p>
                  <p className={`font-bold ${isOnline(selectedAdmin.last_seen) ? 'text-green-400' : 'text-gray-500'}`}>
                    {isOnline(selectedAdmin.last_seen) ? '🟢 متصل' : '🔴 غير متصل'}
                  </p>
                </div>
                <div className="bg-white/5 rounded-lg p-2 text-center">
                  <p className="text-gray-500">ساعات العمل</p>
                  <p className="text-white font-cy-bold">{selectedAdmin.total_hours || '0'} س</p>
                </div>
                <div className="bg-white/5 rounded-lg p-2 text-center">
                  <p className="text-gray-500">زيارات الصفحات</p>
                  <p className="text-white font-cy-bold">{selectedAdmin.total_visits || '0'}</p>
                </div>
              </div>
              <div className="text-xs space-y-1 pt-2 border-t border-white/5">
                <div className="flex justify-between">
                  <span className="text-gray-500">تاريخ التسجيل:</span>
                  <span className="text-gray-300">{new Date(selectedAdmin.created_at).toLocaleDateString("ar-EG-u-nu-latn")}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">آخر دخول:</span>
                  <span className="text-gray-300">{timeAgo(selectedAdmin.last_login_at)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">آخر نشاط:</span>
                  <span className={isOnline(selectedAdmin.last_seen) ? 'text-green-400 font-bold' : 'text-gray-300'}>
                    {isOnline(selectedAdmin.last_seen) ? '🟢 متصل الآن' : timeAgo(selectedAdmin.last_seen)}
                  </span>
                </div>
              </div>
            </div>

            {/* Actions Log */}
            <div>
              <p className="text-gray-400 text-xs font-bold mb-3">📋 آخر الإجراءات</p>
              {logsLoading ? (
                <div className="flex justify-center py-4">
                  <div className="w-5 h-5 border-2 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" />
                </div>
              ) : adminLogs.length === 0 ? (
                <p className="text-gray-600 text-xs text-center py-4">لا توجد إجراءات مسجلة بعد</p>
              ) : (
                <div className="space-y-2 max-h-60 overflow-y-auto custom-scrollbar">
                  {adminLogs.map((log: any) => (
                    <div key={log.id} className="bg-[#0B0F19] rounded-xl p-3 text-xs">
                      <div className="flex items-center justify-between mb-1">
                        <span className="text-[var(--color-brand-500)] font-bold">{log.action}</span>
                        <span className="text-gray-600">{timeAgo(log.created_at)}</span>
                      </div>
                      <p className="text-gray-400 truncate">
                        {log.target_type}: {typeof log.details === 'string' ? log.details.substring(0, 60) : JSON.stringify(log.details).substring(0, 60)}
                      </p>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Delete Button */}
            <button
              onClick={() => handleDelete(selectedAdmin.id, selectedAdmin.full_name)}
              disabled={deleting === selectedAdmin.id}
              className="w-full py-2.5 rounded-xl text-xs font-bold bg-red-500/10 text-red-400 border border-red-500/30 hover:bg-red-500/20 transition-colors disabled:opacity-50"
            >
              {deleting === selectedAdmin.id ? '⏳ جاري الحذف...' : '🗑️ حذف الموظف'}
            </button>
          </div>
        )}
        </div>
      )}
      </div>

      {showForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-[#0B0F19]/80 backdrop-blur-sm p-4">
          <div className="bg-[var(--color-card)] border border-white/10 rounded-3xl w-full max-w-md p-6 space-y-5 shadow-2xl">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-black text-white">إضافة موظف جديد</h2>
              <button onClick={() => setShowForm(false)} className="text-gray-500 hover:text-white transition-colors text-xl leading-none">×</button>
            </div>

            <form onSubmit={handleCreate} className="space-y-4">
              <div>
                <label className="block text-sm text-gray-400 mb-1.5 font-bold">الاسم الكامل</label>
                <input required type="text" value={form.fullName} onChange={e => setForm({...form, fullName: e.target.value})} className="w-full bg-[#0B0F19] border border-white/10 rounded-xl px-4 py-3 text-white focus:border-[var(--color-brand-500)] outline-none" />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1.5 font-bold">البريد الإلكتروني</label>
                <input required type="email" value={form.email} onChange={e => setForm({...form, email: e.target.value})} className="w-full bg-[#0B0F19] border border-white/10 rounded-xl px-4 py-3 text-white focus:border-[var(--color-brand-500)] outline-none" dir="ltr" />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1.5 font-bold">كلمة المرور</label>
                <input required type="password" value={form.password} onChange={e => setForm({...form, password: e.target.value})} className="w-full bg-[#0B0F19] border border-white/10 rounded-xl px-4 py-3 text-white focus:border-[var(--color-brand-500)] outline-none" dir="ltr" />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1.5 font-bold">رقم الهاتف (اختياري)</label>
                <input type="text" value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} className="w-full bg-[#0B0F19] border border-white/10 rounded-xl px-4 py-3 text-white focus:border-[var(--color-brand-500)] outline-none" dir="ltr" placeholder="07xxxxxxxx" />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1.5 font-bold">الصلاحية (Role)</label>
                <select value={form.adminRole} onChange={e => setForm({...form, adminRole: e.target.value})} className="w-full bg-[#0B0F19] border border-white/10 rounded-xl px-4 py-3 text-white focus:border-[var(--color-brand-500)] outline-none">
                  {Object.entries(ROLE_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                </select>
              </div>

              {message && <div className="text-red-400 text-sm font-bold bg-red-500/10 p-3 rounded-lg">{message}</div>}

              <button type="submit" disabled={formLoading} className="w-full bg-[var(--color-brand-500)] text-[#0B0F19] font-bold py-3 rounded-xl hover:bg-[var(--color-brand-600)] transition-colors">
                {formLoading ? "جاري الإضافة..." : "إضافة الحساب"}
              </button>
            </form>
          </div>
        </div>
      )}
    </>
  );
}

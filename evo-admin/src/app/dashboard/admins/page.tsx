"use client";

import { useEffect, useState, useCallback } from "react";

interface AdminUser {
  id: string;
  full_name: string;
  email: string;
  admin_role: string;
  created_at: string;
  status: string;
}

export default function AdminsPage() {
  const [admins, setAdmins] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ fullName: "", email: "", password: "", phone: "", adminRole: "support" });
  const [formLoading, setFormLoading] = useState(false);
  const [message, setMessage] = useState("");

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

  const ROLE_LABELS: Record<string, string> = {
    super_admin: "Super Admin (مدير عام)",
    operations: "Operations (عمليات)",
    finance: "Finance (مالية)",
    support: "Support (دعم فني)",
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
        <div className="bg-[var(--color-card)] border border-white/5 rounded-3xl overflow-hidden shadow-lg animate-fade-in-up delay-200">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-white/5 bg-[#0B0F19]/40">
                  <th className="px-5 py-3 text-right text-gray-500 font-bold">الاسم</th>
                  <th className="px-4 py-3 text-right text-gray-500 font-bold">البريد الإلكتروني</th>
                  <th className="px-4 py-3 text-right text-gray-500 font-bold">الصلاحية</th>
                  <th className="px-4 py-3 text-center text-gray-500 font-bold">تاريخ الإضافة</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {admins.map((admin) => (
                  <tr key={admin.id} className="hover:bg-white/5 transition-colors">
                    <td className="px-5 py-4 font-bold text-white">{admin.full_name}</td>
                    <td className="px-4 py-4 text-gray-300 font-cy-bold" dir="ltr">{admin.email}</td>
                    <td className="px-4 py-4">
                      <select 
                        value={admin.admin_role || "support"} 
                        onChange={(e) => updateRole(admin.id, e.target.value)}
                        className="bg-[#0B0F19] border border-white/10 rounded-lg px-2 py-1 text-white text-xs font-bold outline-none focus:border-[var(--color-brand-500)]"
                      >
                        {Object.entries(ROLE_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                      </select>
                    </td>
                    <td className="px-4 py-4 text-center text-gray-500 text-xs font-cy-bold">
                      {new Date(admin.created_at).toLocaleDateString("ar-EG-u-nu-latn")}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
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

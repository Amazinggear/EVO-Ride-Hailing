"use client";

import { useEffect, useState, useCallback } from "react";

interface Customer {
  id: string;
  full_name: string;
  phone: string;
  email: string;
  status: string;
  passenger_rating: number;
  cancellation_count: number;
  last_login_at: string;
  created_at: string;
}

export default function CustomersPage() {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  const getToken = () => localStorage.getItem("evo_admin_token") || "";

  const fetchCustomers = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ role: "passenger" });
      if (search) params.set("search", search);

      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/users?${params}`, {
        headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${getToken()}` },
      });
      const data = await res.json();
      if (data.users) {
        setCustomers(data.users);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [search]);

  useEffect(() => {
    const timer = setTimeout(() => fetchCustomers(), 500);
    return () => clearTimeout(timer);
  }, [fetchCustomers, search]);

  const toggleStatus = async (id: string, currentStatus: string) => {
    const newStatus = currentStatus === "active" ? "suspended" : "active";
    if (!confirm(`هل أنت متأكد من ${newStatus === "suspended" ? "حظر" : "تفعيل"} هذا العميل؟`)) return;

    setActionLoading(id);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/users/${id}/status`, {
        method: "PATCH",
        headers: {
          "Bypass-Tunnel-Reminder": "true",
          Authorization: `Bearer ${getToken()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ status: newStatus }),
      });
      if (res.ok) {
        setCustomers((prev) =>
          prev.map((c) => (c.id === id ? { ...c, status: newStatus } : c))
        );
      }
    } catch (err) {
      alert("حدث خطأ أثناء تغيير حالة العميل");
    } finally {
      setActionLoading(null);
    }
  };

  return (
    <div dir="rtl" className="space-y-6 animate-fade-in-up">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-black text-white flex items-center gap-2">
            إدارة العملاء <span className="animate-bounce inline-block">👥</span>
          </h1>
          <p className="text-gray-400 text-sm mt-1">عرض حالة الركاب، التقييم، وتاريخ الإلغاءات</p>
        </div>
      </div>

      {/* Search */}
      <div className="relative group w-full lg:w-96">
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="بحث بالاسم أو رقم الهاتف..."
          className="w-full bg-[#0B0F19] border border-white/10 rounded-xl px-4 py-3.5 text-white placeholder-gray-500 focus:outline-none focus:border-[var(--color-brand-500)] text-sm font-bold shadow-lg transition-all focus:shadow-[0_0_15px_rgba(0,200,83,0.1)]"
        />
        <span className="absolute left-4 top-1/2 -translate-y-1/2 opacity-50">🔍</span>
      </div>

      {/* Table */}
      {loading ? (
        <div className="flex items-center justify-center h-40">
          <div className="w-8 h-8 border-4 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" />
        </div>
      ) : customers.length === 0 ? (
        <div className="bg-[var(--color-card)] border border-white/5 rounded-3xl py-16 text-center shadow-lg">
          <p className="text-gray-400 font-bold">لا يوجد عملاء مطروقين للبحث</p>
        </div>
      ) : (
        <div className="bg-[var(--color-card)] border border-white/5 rounded-3xl overflow-hidden shadow-lg animate-fade-in-up delay-200">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-white/5 bg-[#0B0F19]/40">
                  <th className="px-5 py-3 text-right text-gray-500 font-bold">الاسم</th>
                  <th className="px-4 py-3 text-right text-gray-500 font-bold">الهاتف</th>
                  <th className="px-4 py-3 text-center text-gray-500 font-bold">التقييم</th>
                  <th className="px-4 py-3 text-center text-gray-500 font-bold">الإلغاءات</th>
                  <th className="px-4 py-3 text-right text-gray-500 font-bold">تاريخ التسجيل</th>
                  <th className="px-4 py-3 text-right text-gray-500 font-bold">آخر ظهور</th>
                  <th className="px-4 py-3 text-center text-gray-500 font-bold">الحالة</th>
                  <th className="px-4 py-3 text-center text-gray-500 font-bold">إجراء</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {customers.map((customer) => (
                  <tr key={customer.id} className="hover:bg-white/5 transition-colors">
                    <td className="px-5 py-4 font-bold text-white">{customer.full_name}</td>
                    <td className="px-4 py-4 text-gray-300 font-cy-bold" dir="ltr">{customer.phone}</td>
                    <td className="px-4 py-4 text-center">
                      <span className="text-yellow-400 font-cy-bold text-lg">★ {customer.passenger_rating || "—"}</span>
                    </td>
                    <td className="px-4 py-4 text-center">
                      <span className={`font-cy-bold ${customer.cancellation_count > 5 ? "text-red-400" : "text-gray-400"}`}>
                        {customer.cancellation_count || 0}
                      </span>
                    </td>
                    <td className="px-4 py-4 text-gray-500 text-xs font-cy-bold">
                      {new Date(customer.created_at).toLocaleDateString("ar-EG-u-nu-latn")}
                    </td>
                    <td className="px-4 py-4 text-gray-500 text-xs font-cy-bold">
                      {customer.last_login_at ? new Date(customer.last_login_at).toLocaleDateString("ar-EG-u-nu-latn") : "غير محدد"}
                    </td>
                    <td className="px-4 py-4 text-center">
                      <span className={`text-xs font-bold px-2.5 py-1 rounded-full border ${
                        customer.status === "active" 
                          ? "bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] border-[var(--color-brand-500)]/20" 
                          : "bg-red-500/10 text-red-400 border-red-500/20"
                      }`}>
                        {customer.status === "active" ? "نشط" : "محظور"}
                      </span>
                    </td>
                    <td className="px-4 py-4 text-center">
                      <button
                        onClick={() => toggleStatus(customer.id, customer.status)}
                        disabled={actionLoading === customer.id}
                        className={`text-xs font-bold px-3 py-1.5 rounded-lg transition-colors border disabled:opacity-50 ${
                          customer.status === "active"
                            ? "bg-red-500/10 text-red-400 hover:bg-red-500/20 border-red-500/20"
                            : "bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] hover:bg-[var(--color-brand-500)]/20 border-[var(--color-brand-500)]/20"
                        }`}
                      >
                        {actionLoading === customer.id ? "..." : customer.status === "active" ? "حظر العميل" : "إلغاء الحظر"}
                      </button>
                    </td>
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

"use client";

import { useEffect, useState, useCallback } from "react";

interface Complaint {
  id: string;
  complaint_type: string;
  description: string;
  status: "pending" | "in_progress" | "resolved" | "closed";
  created_at: string;
  assigned_to_name: string;
  reporter_name: string;
  reporter_role: string;
  target_name: string;
}

export default function ComplaintsPage() {
  const [complaints, setComplaints] = useState<Complaint[]>([]);
  const [loading, setLoading] = useState(true);

  const getToken = () => localStorage.getItem("evo_admin_token") || "";

  const fetchComplaints = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/complaints`, {
        headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${getToken()}` },
      });
      const data = await res.json();
      if (data.complaints) {
        setComplaints(data.complaints);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchComplaints();
  }, [fetchComplaints]);

  const updateStatus = async (id: string, status: string) => {
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/complaints/${id}/status`, {
        method: "PATCH",
        headers: {
          "Bypass-Tunnel-Reminder": "true",
          Authorization: `Bearer ${getToken()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ status }),
      });
      if (res.ok) {
        fetchComplaints();
      }
    } catch (err) {
      alert("حدث خطأ أثناء التحديث");
    }
  };

  const assignToMe = async (id: string) => {
    try {
      // Decode user from token or just send a request (the backend knows the user from token)
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/complaints/${id}/assign`, {
        method: "PATCH",
        headers: {
          "Bypass-Tunnel-Reminder": "true",
          Authorization: `Bearer ${getToken()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ assignTo: "me" }), // Backend should use req.user.id
      });
      if (res.ok) {
        fetchComplaints();
      }
    } catch (err) {
      alert("حدث خطأ أثناء التعيين");
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "pending": return "bg-yellow-500/10 text-yellow-500 border-yellow-500/20";
      case "in_progress": return "bg-blue-500/10 text-blue-400 border-blue-500/20";
      case "resolved": return "bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] border-[var(--color-brand-500)]/20";
      case "closed": return "bg-gray-500/10 text-gray-400 border-gray-500/20";
      default: return "bg-gray-500/10 text-gray-400";
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case "pending": return "قيد الانتظار";
      case "in_progress": return "قيد المعالجة";
      case "resolved": return "محلولة";
      case "closed": return "مغلقة";
      default: return status;
    }
  };

  return (
    <div dir="rtl" className="space-y-6 animate-fade-in-up">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-black text-white flex items-center gap-2">
            نظام الشكاوى والدعم <span className="animate-bounce inline-block">🚨</span>
          </h1>
          <p className="text-gray-400 text-sm mt-1">إدارة شكاوى العملاء والكباتن</p>
        </div>
      </div>

      {/* Table */}
      {loading ? (
        <div className="flex items-center justify-center h-40">
          <div className="w-8 h-8 border-4 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" />
        </div>
      ) : complaints.length === 0 ? (
        <div className="bg-[var(--color-card)] border border-white/5 rounded-3xl py-16 text-center shadow-lg">
          <p className="text-gray-400 font-bold">لا توجد شكاوى حالياً</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {complaints.map((c) => (
            <div key={c.id} className="bg-[var(--color-card)] border border-white/5 rounded-2xl p-5 shadow-lg flex flex-col gap-4 hover:border-white/10 transition-colors">
              <div className="flex justify-between items-start">
                <span className={`text-xs font-bold px-2 py-1 rounded border ${getStatusColor(c.status)}`}>
                  {getStatusLabel(c.status)}
                </span>
                <span className="text-xs text-gray-500 font-cy-bold">
                  {new Date(c.created_at).toLocaleDateString("ar-EG-u-nu-latn")}
                </span>
              </div>
              
              <div>
                <p className="text-gray-400 text-xs mb-1 font-bold">نوع الشكوى</p>
                <p className="text-white font-bold">{c.complaint_type === "driver_complaint" ? "شكوى على كابتن" : "شكوى عامة"}</p>
              </div>

              <div>
                <p className="text-gray-400 text-xs mb-1 font-bold">التفاصيل</p>
                <p className="text-sm text-gray-300 leading-relaxed">{c.description}</p>
              </div>

              <div className="bg-[#0B0F19] rounded-xl p-3 border border-white/5 space-y-2 text-xs">
                <div className="flex justify-between">
                  <span className="text-gray-500 font-bold">الشاكي:</span>
                  <span className="text-white font-bold">{c.reporter_name} ({c.reporter_role === "driver" ? "كابتن" : "عميل"})</span>
                </div>
                {c.target_name && (
                  <div className="flex justify-between">
                    <span className="text-gray-500 font-bold">المشتكى عليه:</span>
                    <span className="text-white font-bold">{c.target_name}</span>
                  </div>
                )}
                <div className="flex justify-between">
                  <span className="text-gray-500 font-bold">الموظف المسؤول:</span>
                  <span className={c.assigned_to_name ? "text-[var(--color-brand-500)] font-bold" : "text-gray-600"}>
                    {c.assigned_to_name || "غير معين"}
                  </span>
                </div>
              </div>

              <div className="pt-2 mt-auto grid grid-cols-2 gap-2 border-t border-white/5">
                {!c.assigned_to_name ? (
                  <button onClick={() => assignToMe(c.id)} className="col-span-2 bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] hover:bg-[var(--color-brand-500)]/20 py-2 rounded-lg text-xs font-bold transition-colors">
                    تعيين لي (Assign to Me)
                  </button>
                ) : (
                  <>
                    <button onClick={() => updateStatus(c.id, "resolved")} disabled={c.status === "resolved"} className="bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] hover:bg-[var(--color-brand-500)]/20 disabled:opacity-30 py-2 rounded-lg text-xs font-bold transition-colors">
                      تحديد كمحلولة
                    </button>
                    <button onClick={() => updateStatus(c.id, "closed")} disabled={c.status === "closed"} className="bg-gray-500/10 text-gray-400 hover:bg-gray-500/20 disabled:opacity-30 py-2 rounded-lg text-xs font-bold transition-colors">
                      إغلاق الشكوى
                    </button>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

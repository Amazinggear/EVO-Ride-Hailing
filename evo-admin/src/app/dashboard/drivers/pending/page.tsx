"use client";

import { useEffect, useState, useCallback } from "react";
import Image from "next/image";

interface PendingDriver {
  id: string;
  full_name: string;
  phone: string;
  date_of_birth: string;
  cliq_alias: string;
  national_id_number: string;
  national_id_front_url: string;
  national_id_back_url: string;
  personal_photo_url: string;
  license_number: string;
  license_photo_url: string;
  criminal_clearance_url: string;
  car_model: string;
  car_plate: string;
  car_type: string;
  submitted_at: string;
}

const CAR_TYPE_LABELS: Record<string, string> = {
  ev_mini: "EV MINI",
  ev_taxi: "EV TAXI",
  ev_sedan: "EV SEDAN",
  ev_suv: "EV SUV",
  ev_luxury: "EV Luxury",
};

export default function PendingDriversPage() {
  const [drivers, setDrivers] = useState<PendingDriver[]>([]);
  const [selectedDriver, setSelectedDriver] = useState<PendingDriver | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [adminNote, setAdminNote] = useState("");
  const [actionType, setActionType] = useState<"approve" | "reject" | "more_info" | null>(null);

  const getToken = () => localStorage.getItem("evo_admin_token") || "";

  const fetchPending = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/drivers/pending`,
        { headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${getToken()}` } }
      );
      const data = await res.json();
      setDrivers(data.drivers || []);
    } catch {
      console.error('Failed to fetch pending drivers');
      setDrivers([]); // No mock in production
    }
  }, []);

  useEffect(() => { fetchPending(); }, [fetchPending]);

  const handleAction = async () => {
    if (!selectedDriver || !actionType) return;
    setActionLoading(true);

    const endpoint = actionType === "approve"
      ? `/api/v1/admin/drivers/${selectedDriver.id}/approve`
      : actionType === "reject"
      ? `/api/v1/admin/drivers/${selectedDriver.id}/reject`
      : `/api/v1/admin/drivers/${selectedDriver.id}/request-info`;

    try {
      await fetch(`${process.env.NEXT_PUBLIC_API_URL}${endpoint}`, {
        method: "POST",
        headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${getToken()}`, "Content-Type": "application/json" },
        body: JSON.stringify({ adminNote }),
      });

      setSelectedDriver(null);
      setActionType(null);
      setAdminNote("");
      await fetchPending();
    } catch (err) {
      console.error(err);
    } finally {
      setActionLoading(false);
    }
  };

  const DocLink = ({ label, url }: { label: string; url: string }) => (
    <a
      href={url || "#"}
      target="_blank"
      rel="noopener noreferrer"
      className={`flex items-center gap-2 px-4 py-3 rounded-xl text-sm font-bold transition-colors shadow-sm ${
        url
          ? "bg-[var(--color-brand-500)]/5 text-[var(--color-brand-500)] hover:bg-[var(--color-brand-500)]/10 border border-[var(--color-brand-500)]/20"
          : "bg-white/5 text-gray-500 cursor-not-allowed border border-white/5"
      }`}
    >
      <span className={url ? "opacity-70" : "opacity-40"}>📄</span>
      {label}
    </a>
  );

  return (
    <div className="flex flex-col lg:flex-row gap-6 h-full animate-fade-in-up">
      {/* ═══ LEFT: Driver List ═══ */}
      <div className="w-full lg:w-80 shrink-0 space-y-3">
        <div className="flex items-center justify-between mb-4">
          <h1 className="text-xl font-black text-white">طلبات معلقة</h1>
          <span className="bg-amber-500/20 text-amber-400 text-xs font-cy-bold px-3 py-1.5 rounded-full border border-amber-500/30">
            {drivers.length} طلب
          </span>
        </div>

        {loading ? (
          <div className="flex items-center justify-center h-40">
            <div className="w-8 h-8 border-4 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" />
          </div>
        ) : drivers.length === 0 ? (
          <div className="text-center py-16 text-gray-500">
            <span className="text-5xl block mb-3 opacity-50">🎉</span>
            <p className="font-bold">لا توجد طلبات معلقة!</p>
          </div>
        ) : (
          drivers.map((driver) => (
            <div
              key={driver.id}
              onClick={() => setSelectedDriver(driver)}
              className={`bg-[var(--color-card)] border rounded-2xl p-4 cursor-pointer transition-all hover:border-[var(--color-brand-500)]/40 hover:bg-white/5 ${
                selectedDriver?.id === driver.id
                  ? "border-[var(--color-brand-500)]/50 bg-[var(--color-brand-500)]/5 shadow-[0_0_15px_rgba(0,200,83,0.05)]"
                  : "border-white/5 shadow-md"
              }`}
            >
              <div className="flex items-center gap-3">
                <div className={`w-12 h-12 rounded-full flex items-center justify-center border font-bold text-lg shrink-0 ${
                  selectedDriver?.id === driver.id 
                    ? "bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] border-[var(--color-brand-500)]/20"
                    : "bg-white/5 text-gray-300 border-white/10"
                }`}>
                  {driver.full_name.charAt(0)}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-bold text-white text-sm truncate">{driver.full_name}</p>
                  <p className="text-gray-400 text-xs font-cy-bold mt-0.5">{driver.phone}</p>
                </div>
              </div>
              <div className="flex items-center gap-2 mt-4">
                <span className="bg-white/5 text-gray-300 text-xs font-cy-bold px-2.5 py-1 rounded-md border border-white/10">
                  {CAR_TYPE_LABELS[driver.car_type] || driver.car_type}
                </span>
                <span className="bg-white/5 text-gray-300 text-xs font-cy-bold px-2.5 py-1 rounded-md border border-white/10">
                  {driver.car_plate}
                </span>
              </div>
              <p className="text-gray-500 text-[10px] font-cy-bold mt-3 border-t border-white/5 pt-2">
                {new Date(driver.submitted_at).toLocaleDateString("ar-JO-u-nu-latn")}
              </p>
            </div>
          ))
        )}
      </div>

      {/* ═══ RIGHT: Driver Details ═══ */}
      <div className="flex-1 overflow-y-auto">
        {!selectedDriver ? (
          <div className="flex items-center justify-center h-full text-gray-500">
            <div className="text-center">
              <span className="text-6xl block mb-4 opacity-50">👈</span>
              <p className="font-bold">اختر كابتن لمراجعة طلبه</p>
            </div>
          </div>
        ) : (
          <div className="space-y-6">
            {/* Header */}
            <div className="bg-[var(--color-card)] border border-white/5 rounded-3xl p-6 shadow-md relative overflow-hidden">
              <div className="absolute top-0 right-0 w-32 h-32 bg-[var(--color-brand-500)] opacity-5 blur-3xl rounded-full"></div>
              <div className="flex items-center gap-5 relative z-10">
                <div className="w-20 h-20 rounded-2xl bg-[var(--color-brand-500)]/10 flex items-center justify-center border border-[var(--color-brand-500)]/20 text-4xl font-black text-[var(--color-brand-500)]">
                  {selectedDriver.full_name.charAt(0)}
                </div>
                <div>
                  <h2 className="text-2xl font-black text-white">{selectedDriver.full_name}</h2>
                  <p className="text-gray-400 font-cy-bold mt-1 text-sm">{selectedDriver.phone}</p>
                  <p className="text-gray-500 text-xs mt-2 font-bold">
                    تاريخ الميلاد: <span className="font-cy-bold">{selectedDriver.date_of_birth}</span> <span className="mx-2 text-white/20">|</span> 
                    كليك: <span className="text-[var(--color-brand-500)] font-cy-bold px-2 py-0.5 bg-[var(--color-brand-500)]/10 rounded-md border border-[var(--color-brand-500)]/20 mr-1">{selectedDriver.cliq_alias}</span>
                  </p>
                </div>
              </div>
            </div>

            {/* Info Grid */}
            <div className="grid grid-cols-2 gap-4">
              <InfoBox label="رقم الهوية" value={selectedDriver.national_id_number} />
              <InfoBox label="رقم الرخصة" value={selectedDriver.license_number} />
              <InfoBox label="موديل السيارة" value={selectedDriver.car_model} />
              <InfoBox label="رقم اللوحة" value={selectedDriver.car_plate} />
              <InfoBox label="نوع السيارة" value={CAR_TYPE_LABELS[selectedDriver.car_type] || selectedDriver.car_type} />
              <InfoBox label="كليك (CliQ)" value={selectedDriver.cliq_alias} highlight />
            </div>

            {/* Documents */}
            <div className="bg-[var(--color-card)] border border-white/5 rounded-3xl p-6 shadow-md">
              <h3 className="font-black text-white mb-4 text-lg">📄 الوثائق</h3>
              <div className="grid grid-cols-2 gap-3">
                <DocLink label="هوية — الوجه الأمامي" url={selectedDriver.national_id_front_url} />
                <DocLink label="هوية — الوجه الخلفي" url={selectedDriver.national_id_back_url} />
                <DocLink label="صورة شخصية" url={selectedDriver.personal_photo_url} />
                <DocLink label="رخصة القيادة" url={selectedDriver.license_photo_url} />
                <DocLink label="شهادة عدم المحكومية" url={selectedDriver.criminal_clearance_url} />
              </div>
            </div>

            {/* Action Panel */}
            <div className="bg-[var(--color-card)] border border-white/5 rounded-3xl p-6 space-y-5 shadow-md">
              <h3 className="font-black text-white text-lg">⚡ اتخاذ القرار</h3>

              {/* Action Buttons */}
              <div className="flex gap-3">
                <button
                  onClick={() => setActionType("approve")}
                  className={`flex-1 py-3.5 rounded-xl font-bold transition-all text-sm ${
                    actionType === "approve"
                      ? "bg-[var(--color-brand-500)] text-black shadow-[0_0_15px_rgba(0,200,83,0.3)]"
                      : "bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] border border-[var(--color-brand-500)]/30 hover:bg-[var(--color-brand-500)]/20 shadow-md"
                  }`}
                >
                  ✅ موافقة
                </button>
                <button
                  onClick={() => setActionType("more_info")}
                  className={`flex-1 py-3.5 rounded-xl font-bold transition-all text-sm ${
                    actionType === "more_info"
                      ? "bg-amber-500 text-black shadow-[0_0_15px_rgba(245,158,11,0.3)]"
                      : "bg-amber-500/10 text-amber-400 border border-amber-500/30 hover:bg-amber-500/20 shadow-md"
                  }`}
                >
                  ℹ️ معلومات إضافية
                </button>
                <button
                  onClick={() => setActionType("reject")}
                  className={`flex-1 py-3.5 rounded-xl font-bold transition-all text-sm ${
                    actionType === "reject"
                      ? "bg-red-500 text-white shadow-[0_0_15px_rgba(239,68,68,0.3)]"
                      : "bg-red-500/10 text-red-400 border border-red-500/30 hover:bg-red-500/20 shadow-md"
                  }`}
                >
                  ❌ رفض
                </button>
              </div>

              {/* Admin Note */}
              {(actionType === "reject" || actionType === "more_info") && (
                <div className="animate-in fade-in slide-in-from-top-4 duration-300">
                  <label className="block text-sm font-bold text-gray-300 mb-2">
                    {actionType === "reject" ? "سبب الرفض (يُرسل للكابتن):" : "المعلومات المطلوبة:"}
                  </label>
                  <textarea
                    value={adminNote}
                    onChange={(e) => setAdminNote(e.target.value)}
                    rows={3}
                    placeholder="اكتب ملاحظتك هنا..."
                    className="w-full bg-[#0B0F19] border border-white/10 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:border-[var(--color-brand-500)] resize-none text-sm font-bold transition-colors shadow-inner"
                  />
                </div>
              )}

              {/* Confirm */}
              {actionType && (
                <button
                  onClick={handleAction}
                  disabled={actionLoading || ((actionType === "reject" || actionType === "more_info") && !adminNote.trim())}
                  className="w-full bg-[var(--color-brand-500)] hover:bg-[#00B047] disabled:opacity-40 disabled:hover:bg-[var(--color-brand-500)] disabled:cursor-not-allowed text-black font-black py-4 rounded-xl transition-all shadow-[0_0_15px_rgba(0,200,83,0.3)] text-base mt-2"
                >
                  {actionLoading ? "جاري الحفظ..." : "تأكيد القرار وإرسال الإشعار"}
                </button>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

const InfoBox = ({ label, value, highlight }: { label: string; value: string; highlight?: boolean }) => (
  <div className="bg-[var(--color-card)] border border-white/5 rounded-2xl px-5 py-4 shadow-sm flex flex-col justify-center">
    <p className="text-gray-500 text-xs font-bold mb-1.5">{label}</p>
    <p className={`font-cy-bold text-base ${highlight ? "text-[var(--color-brand-500)]" : "text-white"}`}>{value || "—"}</p>
  </div>
);


"use client";

import { useEffect, useState, use } from "react";
import EvoLogo from "@/components/EvoLogo";

const CAR_LABELS: Record<string, string> = {
  ev_mini: "ميني 🛵",
  ev_taxi: "تاكسي 🚕",
  ev_sedan: "سيدان 🚗",
  ev_suv: "SUV 🚙",
  ev_luxury: "فاخر 💎",
};

export default function OnboardingPage({ params }: { params: Promise<{ token: string }> }) {
  const { token } = use(params);
  const [driver, setDriver] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [message, setMessage] = useState("");
  const [success, setSuccess] = useState(false);

  const [files, setFiles] = useState<Record<string, string>>({
    national_id_front: "",
    national_id_back: "",
    personal_photo: "",
    license_photo: "",
    criminal_clearance: "",
  });

  useEffect(() => {
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/drivers/onboarding/${token}`)
      .then(r => r.json())
      .then(data => {
        if (data.driver) setDriver(data.driver);
        else setMessage("رابط غير صالح أو منتهي الصلاحية");
      })
      .catch(() => setMessage("تعذر الاتصال بالخادم"))
      .finally(() => setLoading(false));
  }, [token]);

  const handleFile = (field: string, file: File) => {
    const reader = new FileReader();
    reader.onload = () => {
      setFiles(prev => ({ ...prev, [field]: reader.result as string }));
    };
    reader.readAsDataURL(file);
  };

  const handleSubmit = async () => {
    setUploading(true);
    setMessage("");
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/drivers/onboarding/${token}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(files),
      });
      const data = await res.json();
      if (res.ok) {
        setSuccess(true);
        setMessage("✅ تم رفع جميع المستندات بنجاح!");
      } else {
        setMessage(`❌ ${data.error || "فشل الرفع"}`);
      }
    } catch {
      setMessage("❌ فشل الاتصال بالخادم");
    } finally {
      setUploading(false);
    }
  };

  if (loading) {
    return (
      <div dir="rtl" className="min-h-screen bg-[#0B0F19] flex items-center justify-center">
        <div className="w-10 h-10 border-4 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" />
      </div>
    );
  }

  if (!driver && !loading) {
    return (
      <div dir="rtl" className="min-h-screen bg-[#0B0F19] flex items-center justify-center p-4">
        <div className="bg-[var(--color-card)] border border-red-500/20 rounded-3xl p-8 text-center max-w-md">
          <div className="text-5xl mb-4">⚠️</div>
          <h2 className="text-white font-bold text-xl mb-2">الرابط غير صالح</h2>
          <p className="text-gray-400">{message || "هذا الرابط غير صالح أو تم استخدامه مسبقاً"}</p>
        </div>
      </div>
    );
  }

  return (
    <div dir="rtl" className="min-h-screen bg-[#0B0F19] p-4 sm:p-8 font-alexandria">
      <div className="max-w-2xl mx-auto">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="flex items-center justify-center gap-3 mb-4" dir="ltr">
            <EvoLogo className="h-16" />
            <span className="text-2xl font-bold text-white font-cy-bold">DRIVER</span>
          </div>
          <h1 className="text-2xl font-black text-white mb-2">أهلاً {driver.full_name} 👋</h1>
          <p className="text-gray-400">يرجى رفع المستندات المطلوبة لتفعيل حساب الكابتن</p>
          <p className="text-gray-500 text-xs mt-2">سيتم مراجعة المستندات من قبل فريق EVO</p>
        </div>

        {/* Driver Info Card */}
        <div className="bg-[var(--color-card)] border border-white/5 rounded-3xl p-6 mb-6">
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div><span className="text-gray-500">الاسم:</span> <span className="text-white font-bold">{driver.full_name}</span></div>
            <div><span className="text-gray-500">الهاتف:</span> <span className="text-white font-bold" dir="ltr">{driver.phone}</span></div>
            <div><span className="text-gray-500">السيارة:</span> <span className="text-white font-bold">{driver.car_model} ({driver.car_plate})</span></div>
            <div><span className="text-gray-500">النوع:</span> <span className="text-white font-bold">{CAR_LABELS[driver.car_type] || driver.car_type}</span></div>
          </div>
        </div>

        {success ? (
          <div className="bg-[var(--color-brand-500)]/10 border border-[var(--color-brand-500)]/30 rounded-3xl p-8 text-center">
            <div className="text-6xl mb-4">🎉</div>
            <h2 className="text-white font-bold text-xl mb-2">تم رفع المستندات بنجاح!</h2>
            <p className="text-gray-400">سيتم مراجعة مستنداتك من قبل فريق EVO والتواصل معك قريباً</p>
          </div>
        ) : (
          <div className="bg-[var(--color-card)] border border-white/5 rounded-3xl p-6 space-y-6">
            {[
              { field: "national_id_front", label: "🪪 صورة الهوية - الوجه الأمامي", hint: "يرجى تصوير الوجه الأمامي للهوية بوضوح" },
              { field: "national_id_back", label: "🪪 صورة الهوية - الوجه الخلفي", hint: "يرجى تصوير الوجه الخلفي للهوية بوضوح" },
              { field: "personal_photo", label: "📸 صورة شخصية", hint: "صورة شخصية حديثة وواضحة" },
              { field: "license_photo", label: "🚗 صورة رخصة القيادة", hint: "صورة واضحة لرخصة القيادة سارية المفعول" },
              { field: "criminal_clearance", label: "📄 شهادة عدم محكومية", hint: "شهادة صادرة عن المحكمة المختصة" },
            ].map(({ field, label, hint }) => (
              <div key={field} className="bg-[#0B0F19] border border-white/5 rounded-2xl p-4 hover:border-[var(--color-brand-500)]/30 transition-all">
                <label className="block text-sm font-bold text-white mb-1">{label}</label>
                <p className="text-gray-500 text-xs mb-3">{hint}</p>
                <div className="flex items-center gap-3">
                  <label className="cursor-pointer bg-[var(--color-brand-500)]/10 hover:bg-[var(--color-brand-500)]/20 text-[var(--color-brand-500)] border border-[var(--color-brand-500)]/30 font-bold px-4 py-2 rounded-xl text-sm transition-all inline-block">
                    📁 اختر ملف
                    <input
                      type="file"
                      accept="image/*"
                      onChange={e => e.target.files?.[0] && handleFile(field, e.target.files[0])}
                      className="hidden"
                    />
                  </label>
                  {files[field] ? (
                    <div className="flex items-center gap-2 text-green-400 text-xs font-bold">
                      <span>✅ تم رفع الملف</span>
                      <img src={files[field]} alt="preview" className="h-10 w-10 rounded-lg object-cover border border-white/10" />
                    </div>
                  ) : (
                    <span className="text-gray-600 text-xs">لم يتم الرفع بعد</span>
                  )}
                </div>
              </div>
            ))}

            {message && (
              <div className={`text-sm font-bold p-3 rounded-lg ${message.startsWith("✅") ? "bg-green-500/10 text-green-400" : "bg-red-500/10 text-red-400"}`}>
                {message}
              </div>
            )}

            <button
              onClick={handleSubmit}
              disabled={uploading}
              className="w-full bg-[var(--color-brand-500)] text-[#0B0F19] font-bold py-4 rounded-xl hover:bg-[var(--color-brand-600)] transition-all disabled:opacity-50 text-lg"
            >
              {uploading ? "⏳ جاري الرفع..." : "📤 رفع جميع المستندات"}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

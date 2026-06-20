'use client';

import { useEffect, useState, useCallback } from 'react';

interface PricingConfig {
  car_type: string;
  base_fare: number;
  per_km_rate: number;
  per_min_rate: number;
  min_fare: number;
  commission_pct: number;
}

interface EditableConfig {
  base_fare: string;
  per_km_rate: string;
  per_min_rate: string;
  min_fare: string;
}

const CAR_TYPES = [
  { key: 'ev_mini',   emoji: '🛵', name: 'ميني',  color: 'border-violet-500/30 shadow-[0_0_15px_rgba(139,92,246,0.1)]',  accent: 'text-violet-400',  glow: 'bg-violet-500/10 text-violet-400 border-violet-500/20' },
  { key: 'ev_taxi',   emoji: '🚕', name: 'تاكسي', color: 'border-amber-500/30 shadow-[0_0_15px_rgba(245,158,11,0.1)]',   accent: 'text-amber-400',   glow: 'bg-amber-500/10 text-amber-400 border-amber-500/20' },
  { key: 'ev_sedan',  emoji: '🚗', name: 'سيدان', color: 'border-blue-500/30 shadow-[0_0_15px_rgba(59,130,246,0.1)]',     accent: 'text-blue-400',    glow: 'bg-blue-500/10 text-blue-400 border-blue-500/20' },
  { key: 'ev_suv',    emoji: '🚙', name: 'SUV',   color: 'border-emerald-500/30 shadow-[0_0_15px_rgba(16,185,129,0.1)]', accent: 'text-emerald-400', glow: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' },
  { key: 'ev_luxury', emoji: '💎', name: 'فاخر',  color: 'border-[#00C853]/30 shadow-[0_0_15px_rgba(0,200,83,0.1)]',  accent: 'text-[#00C853]',  glow: 'bg-[#00C853]/10 text-[#00C853] border-[#00C853]/20' },
];

const MOCK_PRICING: PricingConfig[] = [
  { car_type: 'ev_mini',   base_fare: 0.50, per_km_rate: 0.25, per_min_rate: 0.04, min_fare: 1.00, commission_pct: 13 },
  { car_type: 'ev_taxi',   base_fare: 0.60, per_km_rate: 0.28, per_min_rate: 0.05, min_fare: 1.20, commission_pct: 13 },
  { car_type: 'ev_sedan',  base_fare: 0.70, per_km_rate: 0.30, per_min_rate: 0.05, min_fare: 1.50, commission_pct: 13 },
  { car_type: 'ev_suv',    base_fare: 0.90, per_km_rate: 0.35, per_min_rate: 0.06, min_fare: 2.00, commission_pct: 13 },
  { car_type: 'ev_luxury', base_fare: 1.20, per_km_rate: 0.45, per_min_rate: 0.08, min_fare: 2.50, commission_pct: 13 },
];

function calcFare(cfg: EditableConfig): string {
  const km = 10, min = 15;
  const base  = parseFloat(cfg.base_fare)   || 0;
  const perKm = parseFloat(cfg.per_km_rate) || 0;
  const perMin= parseFloat(cfg.per_min_rate)|| 0;
  const minF  = parseFloat(cfg.min_fare)    || 0;
  const total = Math.max(base + km * perKm + min * perMin, minF);
  return total.toFixed(3);
}

export default function PricingPage() {
  const [pricing, setPricing] = useState<Record<string, PricingConfig>>({});
  const [editable, setEditable] = useState<Record<string, EditableConfig>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState<Record<string, boolean>>({});
  const [saved, setSaved]   = useState<Record<string, boolean>>({});
  const [error, setError]   = useState('');

  const getToken = () => localStorage.getItem('evo_admin_token') || '';

  const fetchPricing = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/pricing`, {
        headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${getToken()}` },
      });
      if (!res.ok) throw new Error();
      const data: PricingConfig[] = await res.json();
      const map: Record<string, PricingConfig> = {};
      const editMap: Record<string, EditableConfig> = {};
      data.forEach(p => {
        map[p.car_type] = p;
        editMap[p.car_type] = {
          base_fare:   String(p.base_fare),
          per_km_rate: String(p.per_km_rate),
          per_min_rate:String(p.per_min_rate),
          min_fare:    String(p.min_fare),
        };
      });
      setPricing(map);
      setEditable(editMap);
    } catch {
      // Dev mock
      const map: Record<string, PricingConfig> = {};
      const editMap: Record<string, EditableConfig> = {};
      MOCK_PRICING.forEach(p => {
        map[p.car_type] = p;
        editMap[p.car_type] = {
          base_fare:   String(p.base_fare),
          per_km_rate: String(p.per_km_rate),
          per_min_rate:String(p.per_min_rate),
          min_fare:    String(p.min_fare),
        };
      });
      setPricing(map);
      setEditable(editMap);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchPricing(); }, [fetchPricing]);

  const handleChange = (carType: string, field: keyof EditableConfig, value: string) => {
    setEditable(prev => ({
      ...prev,
      [carType]: { ...prev[carType], [field]: value },
    }));
  };

  const handleSave = async (carType: string) => {
    setSaving(s => ({ ...s, [carType]: true }));
    setError('');
    const cfg = editable[carType];
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/pricing/${carType}`, {
        method: 'PATCH',
        headers: { "Bypass-Tunnel-Reminder": "true",
          Authorization: `Bearer ${getToken()}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          baseFare:    parseFloat(cfg.base_fare),
          perKmRate:   parseFloat(cfg.per_km_rate),
          perMinRate:  parseFloat(cfg.per_min_rate),
          minFare:     parseFloat(cfg.min_fare),
          commissionPct: 13,
        }),
      });
      if (!res.ok) {
        const d = await res.json().catch(() => ({}));
        throw new Error(d.error || 'فشل حفظ التسعيرة');
      }
      setSaved(s => ({ ...s, [carType]: true }));
      setTimeout(() => setSaved(s => ({ ...s, [carType]: false })), 2500);
    } catch (e: any) {
      setError(e.message || 'حدث خطأ أثناء الحفظ');
    } finally {
      setSaving(s => ({ ...s, [carType]: false }));
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="w-10 h-10 border-4 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div dir="rtl" className="space-y-6 animate-fade-in-up">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black text-white flex items-center gap-2">
            التسعيرة <span className="animate-bounce inline-block">💲</span>
          </h1>
          <p className="text-gray-400 text-sm mt-1">إدارة أسعار جميع أنواع المركبات بدقة وسهولة</p>
        </div>
        <div className="bg-[var(--color-brand-500)]/10 border border-[var(--color-brand-500)]/30 rounded-xl px-5 py-3 shadow-[0_0_15px_rgba(0,200,83,0.1)] self-start sm:self-auto">
          <p className="text-[var(--color-brand-500)] text-sm font-bold">العمولة الثابتة: <span className="text-white font-black font-cy-bold text-lg">13%</span></p>
        </div>
      </div>

      {error && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-xl px-5 py-4 flex items-center gap-3">
          <span>⚠️</span>
          <p className="text-red-400 text-sm">{error}</p>
          <button onClick={fetchPricing} className="mr-auto text-red-400 hover:text-red-300 text-sm underline font-bold">إعادة المحاولة</button>
        </div>
      )}

      {/* Info Banner */}
      <div className="bg-[var(--color-brand-500)]/5 border border-[var(--color-brand-500)]/20 rounded-xl px-5 py-4 flex gap-4 animate-fade-in-up delay-100 shadow-sm relative overflow-hidden">
        <div className="absolute top-0 right-0 w-32 h-32 bg-[var(--color-brand-500)] opacity-10 blur-3xl rounded-full"></div>
        <span className="text-2xl shrink-0 relative z-10 animate-pulse">ℹ️</span>
        <div className="text-sm text-gray-300 relative z-10">
          <p className="text-base"><span className="text-[var(--color-brand-500)] font-black">معادلة الأجرة:</span> الأجرة الأساسية + (المسافة × سعر الكم) + (الوقت × سعر الدقيقة)</p>
          <p className="text-gray-400 mt-1.5 font-bold">والنتيجة لا تقل عن الحد الأدنى. المعاينة محسوبة على رحلة 10 كم / 15 دقيقة.</p>
        </div>
      </div>

      {/* Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
        {CAR_TYPES.map((ct, idx) => {
          const edit = editable[ct.key];
          if (!edit) return null;
          const isSaving = saving[ct.key];
          const wasSaved = saved[ct.key];
          
          // Generate a delay class based on index (100, 150, 200, 250, 300)
          const delayClass = `delay-${Math.min((idx + 2) * 50, 300)}`;

          return (
            <div
              key={ct.key}
              className={`bg-[var(--color-card)] border ${ct.color} rounded-3xl p-6 space-y-5 transition-all duration-300 hover:border-white/20 hover:-translate-y-1 hover:shadow-xl animate-fade-in-up ${delayClass} relative overflow-hidden`}
            >
              {/* Card Header */}
              <div className="flex items-center gap-4 relative z-10">
                <div className="w-14 h-14 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center text-3xl shadow-inner group-hover:scale-110 transition-transform duration-300">
                  {ct.emoji}
                </div>
                <div>
                  <h3 className={`text-xl font-black ${ct.accent}`}>{ct.name}</h3>
                  <p className="text-gray-400 text-xs font-cy-bold uppercase tracking-wider mt-1">{ct.key}</p>
                </div>
                {wasSaved && (
                  <span className="mr-auto text-[var(--color-brand-500)] text-sm font-bold animate-pulse">✓ تم الحفظ</span>
                )}
              </div>

              {/* Live Preview */}
              <div className="bg-[#0B0F19] rounded-2xl px-5 py-4 border border-white/5 flex items-center justify-between shadow-inner relative z-10">
                <p className="text-gray-400 text-xs font-bold">معاينة: رحلة 10 كم / 15 دقيقة</p>
                <div className={`text-2xl font-cy-bold ${ct.accent} flex items-baseline gap-1.5`}>
                  <span>{calcFare(edit)}</span>
                  <span className="text-sm font-normal text-gray-500 font-alexandria">د.أ</span>
                </div>
              </div>

              {/* Inputs */}
              <div className="space-y-3.5 relative z-10">
                {([
                  { field: 'base_fare',    label: 'الأجرة الأساسية',    unit: 'د.أ' },
                  { field: 'per_km_rate',  label: 'سعر الكيلومتر',      unit: 'د.أ/كم' },
                  { field: 'per_min_rate', label: 'سعر الدقيقة',        unit: 'د.أ/د' },
                  { field: 'min_fare',     label: 'الحد الأدنى للأجرة', unit: 'د.أ' },
                ] as { field: keyof EditableConfig; label: string; unit: string }[]).map(({ field, label, unit }) => (
                  <div key={field} className="flex flex-col sm:flex-row sm:items-center gap-2">
                    <label className="text-gray-400 text-xs font-bold sm:w-36 shrink-0">{label}</label>
                    <div className="flex-1 relative group">
                      <input
                        type="number"
                        step="0.001"
                        min="0"
                        value={edit[field]}
                        onChange={e => handleChange(ct.key, field, e.target.value)}
                        className="w-full bg-[#0B0F19] border border-white/10 focus:border-[var(--color-brand-500)] rounded-xl pr-4 pl-14 py-2.5 text-white text-sm outline-none transition-all text-left font-cy-bold placeholder:text-gray-600 focus:shadow-[0_0_10px_rgba(0,200,83,0.1)]"
                        dir="ltr"
                      />
                      <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 text-xs pointer-events-none font-bold opacity-80 group-focus-within:text-[var(--color-brand-500)] transition-colors">{unit}</span>
                    </div>
                  </div>
                ))}

                {/* Commission — locked */}
                <div className="flex flex-col sm:flex-row sm:items-center gap-2">
                  <label className="text-gray-400 text-xs font-bold sm:w-36 shrink-0">العمولة</label>
                  <div className="flex-1 bg-[#0B0F19] border border-white/5 rounded-xl px-4 py-2.5 flex items-center justify-between cursor-not-allowed opacity-80">
                    <span className="text-[var(--color-brand-500)] font-cy-bold text-sm">13%</span>
                    <span className="text-gray-500 text-xs font-bold">🔒 ثابتة</span>
                  </div>
                </div>
              </div>

              {/* Save Button */}
              <button
                onClick={() => handleSave(ct.key)}
                disabled={isSaving}
                className={`w-full py-3.5 rounded-xl font-bold text-sm transition-all relative z-10 ${
                  wasSaved
                    ? 'bg-[var(--color-brand-500)] text-[#0B0F19] shadow-[0_0_20px_rgba(0,200,83,0.4)]'
                    : `${ct.glow} hover:brightness-125 border hover:shadow-lg`
                } disabled:opacity-50`}
              >
                {isSaving ? (
                  <span className="flex items-center justify-center gap-2">
                    <span className={`w-5 h-5 border-2 ${ct.accent} border-t-transparent rounded-full animate-spin inline-block`} />
                    جاري الحفظ...
                  </span>
                ) : wasSaved ? '✓ تم الحفظ بنجاح' : 'حفظ التسعيرة'}
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
}


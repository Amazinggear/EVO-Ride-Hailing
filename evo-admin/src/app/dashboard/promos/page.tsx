'use client';

import { useEffect, useState, useCallback } from 'react';

interface PromoCode {
  id: string;
  code: string;
  discount_type: 'percentage' | 'fixed';
  discount_value: number;
  valid_from: string;
  valid_until: string;
  max_uses: number | null;
  max_per_user: number;
  used_count: number;
  car_types: string[];
  is_active: boolean;
}

interface NewPromoForm {
  code: string;
  discount_type: 'percentage' | 'fixed';
  discount_value: string;
  valid_from: string;
  valid_until: string;
  max_uses: string;
  max_per_user: string;
  car_types: string[];
}

const ALL_CAR_TYPES = [
  { key: 'ev_mini',   emoji: '🛵', name: 'ميني' },
  { key: 'ev_taxi',   emoji: '🚕', name: 'تاكسي' },
  { key: 'ev_sedan',  emoji: '🚗', name: 'سيدان' },
  { key: 'ev_suv',    emoji: '🚙', name: 'SUV' },
  { key: 'ev_luxury', emoji: '💎', name: 'فاخر' },
];

const MOCK_PROMOS: PromoCode[] = [
  {
    id: 'p1', code: 'EVO2026', discount_type: 'percentage', discount_value: 20,
    valid_from: '2026-01-01', valid_until: '2026-12-31', max_uses: 500,
    max_per_user: 1, used_count: 142, car_types: ['ev_mini','ev_taxi','ev_sedan','ev_suv','ev_luxury'], is_active: true,
  },
  {
    id: 'p2', code: 'WELCOME5', discount_type: 'fixed', discount_value: 0.5,
    valid_from: '2026-01-01', valid_until: '2026-06-01', max_uses: 200,
    max_per_user: 1, used_count: 200, car_types: ['ev_sedan','ev_suv'], is_active: false,
  },
  {
    id: 'p3', code: 'LUXRIDE', discount_type: 'percentage', discount_value: 15,
    valid_from: '2026-06-01', valid_until: '2026-09-30', max_uses: null,
    max_per_user: 3, used_count: 8, car_types: ['ev_luxury'], is_active: true,
  },
];

const TODAY = new Date().toISOString().split('T')[0];

function getPromoStatus(promo: PromoCode): { label: string; color: string; bg: string; border: string } {
  if (!promo.is_active || promo.valid_until < TODAY) {
    return { label: 'منتهي', color: 'text-red-400', bg: 'bg-red-500/10', border: 'border-red-500/20' };
  }
  if (promo.max_uses !== null && promo.used_count >= promo.max_uses) {
    return { label: 'مستخدم بالكامل', color: 'text-gray-400', bg: 'bg-white/5', border: 'border-white/10' };
  }
  return { label: 'الكود نشط', color: 'text-[var(--color-brand-500)]', bg: 'bg-[var(--color-brand-500)]/10', border: 'border-[var(--color-brand-500)]/20' };
}

const EMPTY_FORM: NewPromoForm = {
  code: '', discount_type: 'percentage', discount_value: '',
  valid_from: TODAY, valid_until: '', max_uses: '', max_per_user: '1',
  car_types: ['ev_mini','ev_taxi','ev_sedan','ev_suv','ev_luxury'],
};

export default function PromosPage() {
  const [promos, setPromos] = useState<PromoCode[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState<NewPromoForm>(EMPTY_FORM);
  const [submitting, setSubmitting] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [formError, setFormError] = useState('');

  const getToken = () => localStorage.getItem('evo_admin_token') || '';

  const fetchPromos = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/promo-codes`, {
        headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${getToken()}` },
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      const list = data.promoCodes || [];
      setPromos(list.map((p: any) => ({
        ...p,
        car_types: p.applicable_car_types || [],
        discount_value: parseFloat(p.discount_value) || 0
      })));
    } catch (err: any) {
      console.error('Fetch promos error:', err);
      // 🚫 NEVER use mock data in production
      if (process.env.NODE_ENV === 'development' && !process.env.NEXT_PUBLIC_API_URL?.includes('onrender.com')) {
        console.warn('⚠️ Using MOCK_PROMOS fallback (dev mode only)');
        setPromos(MOCK_PROMOS);
      }
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchPromos(); }, [fetchPromos]);

  const handleCreate = async () => {
    setFormError('');
    if (!form.code || !form.discount_value || !form.valid_until || form.car_types.length === 0) {
      setFormError('الرجاء تعبئة جميع الحقول المطلوبة');
      return;
    }
    setSubmitting(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/promo-codes`, {
        method: 'POST',
        headers: { "Bypass-Tunnel-Reminder": "true",
          Authorization: `Bearer ${getToken()}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          code: form.code,
          discountType: form.discount_type,
          discountValue: parseFloat(form.discount_value),
          validFrom: form.valid_from,
          validUntil: form.valid_until,
          maxTotalUses: form.max_uses ? parseInt(form.max_uses) : null,
          maxPerUser: parseInt(form.max_per_user),
          applicableCarTypes: form.car_types,
        }),
      });
      if (!res.ok) {
        const d = await res.json();
        throw new Error(d.error || 'فشل إضافة الكود');
      }
      setShowForm(false);
      fetchPromos();
    } catch (e: any) {
      setFormError(e.message);
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('هل أنت متأكد من إلغاء هذا الكود؟')) return;
    setDeletingId(id);
    try {
      await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/promo-codes/${id}`, {
        method: 'DELETE',
        headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${getToken()}` },
      });
      setPromos(prev => prev.filter(p => p.id !== id));
    } catch {}
    setDeletingId(null);
  };

  const toggleCarType = (ct: string) => {
    setForm(f => ({
      ...f,
      car_types: f.car_types.includes(ct)
        ? f.car_types.filter(x => x !== ct)
        : [...f.car_types, ct],
    }));
  };

  return (
    <>
      <div dir="rtl" className="space-y-6 animate-fade-in-up">
        {/* Header */}
        <div className="flex items-center justify-between flex-wrap gap-4">
          <div>
            <h1 className="text-2xl font-black text-white flex items-center gap-2">
              أكواد الخصم <span className="animate-bounce inline-block">🎟️</span>
            </h1>
            <p className="text-gray-400 text-sm mt-1">إدارة الرموز الترويجية للتطبيق</p>
          </div>
          <button
            onClick={() => { setShowForm(true); setForm(EMPTY_FORM); }}
            className="bg-[var(--color-brand-500)] hover:bg-[var(--color-brand-600)] text-[#0B0F19] font-bold px-5 py-2.5 rounded-xl transition-all active:scale-95 flex items-center gap-2 shadow-[0_0_15px_rgba(0,200,83,0.3)]"
          >
            <span>+</span> إضافة كود
          </button>
        </div>

        {/* Commission Info Banner */}
        <div className="bg-blue-500/5 border border-blue-500/20 rounded-xl px-5 py-4 flex gap-4 shadow-sm animate-fade-in-up delay-100 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-32 h-32 bg-blue-500 opacity-10 blur-3xl rounded-full"></div>
          <span className="text-2xl shrink-0 relative z-10 animate-pulse">💡</span>
          <div className="text-sm text-gray-300 relative z-10">
            <p className="font-bold text-blue-400 text-base">كيف تعمل أكواد الخصم؟</p>
            <p className="text-gray-400 mt-1.5 font-bold">
              عمولة EVO الإجمالية <span className="text-white font-black font-cy-bold text-[15px]">13%</span> من قيمة الرحلة.
              منها <span className="text-white font-black font-cy-bold text-[15px]">10%</span> إيراد صافٍ للمنصة،
              و<span className="text-white font-black font-cy-bold text-[15px]">3%</span> مخصصة للتسويق وأكواد الخصم.
              الخصم يُحسم من حصة المنصة فقط، وحق الكابتن (<span className="text-[var(--color-brand-500)] font-black font-cy-bold text-[15px]">87%</span>) لا يتأثر.
            </p>
          </div>
        </div>


      {/* Table */}
      {loading ? (
        <div className="flex items-center justify-center h-40">
          <div className="w-8 h-8 border-4 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" />
        </div>
      ) : promos.length === 0 ? (
        <div className="bg-[var(--color-card)] border border-white/5 rounded-3xl py-16 text-center shadow-lg">
          <span className="text-5xl block mb-4">🎟️</span>
          <p className="text-gray-400 font-bold">لا توجد أكواد خصم بعد</p>
          <button onClick={() => setShowForm(true)} className="mt-4 text-[var(--color-brand-500)] hover:underline text-sm font-bold">أضف أول كود</button>
        </div>
      ) : (
        <div className="bg-[var(--color-card)] border border-white/5 rounded-3xl overflow-hidden shadow-lg animate-fade-in-up delay-200 hover:border-white/10 transition-colors">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-white/5 bg-[#0B0F19]/40">
                  <th className="px-5 py-3 text-right text-gray-500 font-bold">الكود</th>
                  <th className="px-4 py-3 text-right text-gray-500 font-bold">الخصم</th>
                  <th className="px-4 py-3 text-right text-gray-500 font-bold">الصلاحية</th>
                  <th className="px-4 py-3 text-right text-gray-500 font-bold">الاستخدام</th>
                  <th className="px-4 py-3 text-right text-gray-500 font-bold">المركبات</th>
                  <th className="px-4 py-3 text-right text-gray-500 font-bold">الحالة</th>
                  <th className="px-4 py-3 text-right text-gray-500 font-bold">إجراء</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {promos.map(promo => {
                  const status = getPromoStatus(promo);
                  return (
                    <tr key={promo.id} className="hover:bg-white/5 transition-colors">
                      <td className="px-5 py-4">
                        <code className="text-[var(--color-brand-500)] font-cy-bold tracking-widest bg-[var(--color-brand-500)]/10 border border-[var(--color-brand-500)]/20 px-2 py-1 rounded-lg text-xs">
                          {promo.code}
                        </code>
                      </td>
                      <td className="px-4 py-4 text-white font-cy-bold">
                        {promo.discount_type === 'percentage'
                          ? `${promo.discount_value}%`
                          : `${promo.discount_value} د.أ`}
                      </td>
                      <td className="px-4 py-4 text-gray-400 text-xs whitespace-nowrap font-cy-bold">
                        <div>{promo.valid_from}</div>
                        <div className="text-gray-500">→ {promo.valid_until}</div>
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex items-center gap-1.5 font-cy-bold">
                          <span className="text-white">{promo.used_count}</span>
                          <span className="text-gray-600">/</span>
                          <span className="text-gray-400">{promo.max_uses ?? '∞'}</span>
                        </div>
                        {promo.max_uses && (
                          <div className="w-16 h-1.5 bg-white/5 rounded-full mt-1.5 overflow-hidden">
                            <div
                              className="h-full bg-[var(--color-brand-500)] rounded-full"
                              style={{ width: `${Math.min((promo.used_count / promo.max_uses) * 100, 100)}%` }}
                            />
                          </div>
                        )}
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex flex-wrap gap-1">
                          {promo.car_types.length === 5
                            ? <span className="text-gray-500 text-xs font-bold bg-white/5 px-2 py-0.5 rounded-full border border-white/5">الكل</span>
                            : promo.car_types.map(ct => {
                                const info = ALL_CAR_TYPES.find(x => x.key === ct);
                                return <span key={ct} className="text-xs">{info?.emoji}</span>;
                              })
                          }
                        </div>
                      </td>
                      <td className="px-4 py-4">
                        <span className={`${status.bg} ${status.border} border ${status.color} text-xs font-bold px-2.5 py-1 rounded-full`}>
                          {status.label}
                        </span>
                      </td>
                      <td className="px-4 py-4">
                        <button
                          onClick={() => handleDelete(promo.id)}
                          disabled={deletingId === promo.id}
                          className="text-red-400 hover:text-red-300 hover:bg-red-500/10 transition-colors px-2.5 py-1.5 rounded-lg text-xs font-bold disabled:opacity-40"
                        >
                          {deletingId === promo.id ? '...' : 'إلغاء'}
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
      </div>

      {/* Create Form Modal */}
      {showForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-[#0B0F19]/80 backdrop-blur-sm p-4">
          <div className="bg-[var(--color-card)] border border-white/10 rounded-3xl w-full max-w-lg max-h-[90vh] overflow-y-auto p-6 space-y-5 shadow-2xl">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-black text-white">إضافة كود خصم جديد</h2>
              <button onClick={() => setShowForm(false)} className="text-gray-500 hover:text-white transition-colors text-xl leading-none">×</button>
            </div>

            {formError && (
              <div className="bg-red-500/10 border border-red-500/30 rounded-xl px-4 py-3 text-red-400 text-sm font-bold">{formError}</div>
            )}

            <div className="space-y-4">
              {/* Code */}
              <div>
                <label className="block text-sm text-gray-400 mb-1.5 font-bold">الكود <span className="text-red-400">*</span></label>
                <div className="relative group">
                  <input
                    type="text"
                    value={form.code}
                    onChange={e => setForm(f => ({ ...f, code: e.target.value.toUpperCase() }))}
                    placeholder="EVO2026"
                    className="w-full bg-[#0B0F19] border border-white/10 focus:border-[var(--color-brand-500)] rounded-xl pl-4 pr-12 py-3 text-white placeholder-gray-600 outline-none transition-all font-cy-bold tracking-widest uppercase focus:shadow-[0_0_10px_rgba(0,200,83,0.1)] text-left"
                    dir="ltr"
                  />
                  <span className="absolute right-4 top-1/2 -translate-y-1/2 text-xl pointer-events-none group-focus-within:animate-bounce">🎟️</span>
                </div>
              </div>

              {/* Discount Type + Value */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm text-gray-400 mb-1.5 font-bold">نوع الخصم</label>
                  <select
                    value={form.discount_type}
                    onChange={e => setForm(f => ({ ...f, discount_type: e.target.value as 'percentage' | 'fixed' }))}
                    className="w-full bg-[#0B0F19] border border-white/10 focus:border-[var(--color-brand-500)] rounded-xl px-4 py-3 text-white outline-none transition-all font-bold focus:shadow-[0_0_10px_rgba(0,200,83,0.1)]"
                  >
                    <option value="percentage">نسبة مئوية (%)</option>
                    <option value="fixed">مبلغ ثابت (د.أ)</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm text-gray-400 mb-1.5 font-bold">قيمة الخصم <span className="text-red-400">*</span></label>
                  <div className="relative group">
                    <input
                      type="number"
                      min="0"
                      step={form.discount_type === 'percentage' ? '1' : '0.01'}
                      value={form.discount_value}
                      onChange={e => setForm(f => ({ ...f, discount_value: e.target.value }))}
                      placeholder={form.discount_type === 'percentage' ? '20' : '0.50'}
                      className="w-full bg-[#0B0F19] border border-white/10 focus:border-[var(--color-brand-500)] rounded-xl pl-12 pr-4 py-3 text-white placeholder-gray-600 outline-none transition-all font-cy-bold text-left focus:shadow-[0_0_10px_rgba(0,200,83,0.1)]"
                      dir="ltr"
                    />
                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 text-sm pointer-events-none font-bold opacity-80 group-focus-within:text-[var(--color-brand-500)] transition-colors">
                      {form.discount_type === 'percentage' ? '%' : 'د.أ'}
                    </span>
                  </div>
                </div>
              </div>

              {/* Dates */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm text-gray-400 mb-1.5 font-bold">صالح من</label>
                  <input type="date" value={form.valid_from}
                    onChange={e => setForm(f => ({ ...f, valid_from: e.target.value }))}
                    className="w-full bg-[#0B0F19] border border-white/5 focus:border-[var(--color-brand-500)] rounded-xl px-4 py-3 text-white outline-none transition-colors font-cy-bold"
                    dir="ltr"
                  />
                </div>
                <div>
                  <label className="block text-sm text-gray-400 mb-1.5 font-bold">صالح حتى <span className="text-red-400">*</span></label>
                  <input type="date" value={form.valid_until}
                    onChange={e => setForm(f => ({ ...f, valid_until: e.target.value }))}
                    className="w-full bg-[#0B0F19] border border-white/5 focus:border-[var(--color-brand-500)] rounded-xl px-4 py-3 text-white outline-none transition-colors font-cy-bold"
                    dir="ltr"
                  />
                </div>
              </div>

              {/* Uses */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm text-gray-400 mb-1.5 font-bold">استخدام كلي <span className="text-gray-600 font-normal">(اختياري)</span></label>
                  <input type="number" min="1" value={form.max_uses}
                    onChange={e => setForm(f => ({ ...f, max_uses: e.target.value }))}
                    placeholder="بدون حد"
                    className="w-full bg-[#0B0F19] border border-white/5 focus:border-[var(--color-brand-500)] rounded-xl px-4 py-3 text-white placeholder-gray-600 outline-none transition-colors font-cy-bold"
                    dir="ltr"
                  />
                </div>
                <div>
                  <label className="block text-sm text-gray-400 mb-1.5 font-bold">الحد لكل مستخدم</label>
                  <input type="number" min="1" value={form.max_per_user}
                    onChange={e => setForm(f => ({ ...f, max_per_user: e.target.value }))}
                    className="w-full bg-[#0B0F19] border border-white/5 focus:border-[var(--color-brand-500)] rounded-xl px-4 py-3 text-white outline-none transition-colors font-cy-bold"
                    dir="ltr"
                  />
                </div>
              </div>

              {/* Car Types */}
              <div>
                <label className="block text-sm text-gray-400 mb-2 font-bold">أنواع المركبات المشمولة</label>
                <div className="flex flex-wrap gap-2">
                  {ALL_CAR_TYPES.map(ct => (
                    <button
                      key={ct.key}
                      type="button"
                      onClick={() => toggleCarType(ct.key)}
                      className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-sm font-bold transition-all ${
                        form.car_types.includes(ct.key)
                          ? 'bg-[var(--color-brand-500)]/20 text-[var(--color-brand-500)] border border-[var(--color-brand-500)]/40'
                          : 'bg-white/5 text-gray-400 border border-white/5 hover:border-white/20'
                      }`}
                    >
                      <span>{ct.emoji}</span> {ct.name}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Actions */}
            <div className="flex gap-3 pt-2">
              <button
                onClick={handleCreate}
                disabled={submitting}
                className="flex-1 bg-[var(--color-brand-500)] hover:bg-[var(--color-brand-600)] disabled:opacity-50 text-[#0B0F19] font-bold py-3 rounded-xl transition-all active:scale-95 shadow-[0_0_15px_rgba(0,200,83,0.3)]"
              >
                {submitting ? 'جاري الإنشاء...' : 'إنشاء الكود'}
              </button>
              <button
                onClick={() => setShowForm(false)}
                className="px-6 bg-white/5 hover:bg-white/10 text-white font-bold py-3 rounded-xl transition-colors border border-white/10"
              >
                إلغاء
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}


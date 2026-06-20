'use client';

import { useEffect, useState, useCallback } from 'react';

interface Driver {
  id: string;
  full_name: string;
  phone: string;
  car_type: string;
  car_plate: string;
  car_model?: string;
  approval_status: 'pending' | 'approved' | 'rejected';
  rating: number;
  wallet_balance: number;
  total_rides: number;
  created_at: string;
  cliq_alias?: string;
  national_id_number?: string;
  license_number?: string;
  national_id_front_url?: string;
  national_id_back_url?: string;
  personal_photo_url?: string;
  license_photo_url?: string;
  criminal_clearance_url?: string;
}

interface NewCaptainForm {
  fullName: string;
  phone: string;
  email: string;
  carType: string;
  carModel: string;
  carPlate: string;
  cliqAlias: string;
}

type StatusFilter = 'all' | 'pending' | 'approved' | 'rejected';

const CAR_TYPE_META: Record<string, { emoji: string; name: string }> = {
  ev_mini:   { emoji: '🛵', name: 'ميني' },
  ev_taxi:   { emoji: '🚕', name: 'تاكسي' },
  ev_sedan:  { emoji: '🚗', name: 'سيدان' },
  ev_suv:    { emoji: '🚙', name: 'SUV' },
  ev_luxury: { emoji: '💎', name: 'فاخر' },
};

const STATUS_META = {
  pending:  { label: 'معلق',   color: 'text-amber-400',   bg: 'bg-amber-500/10',  border: 'border-amber-500/20' },
  approved: { label: 'موافق',  color: 'text-[var(--color-brand-500)]', bg: 'bg-[var(--color-brand-500)]/10', border: 'border-[var(--color-brand-500)]/20' },
  rejected: { label: 'مرفوض', color: 'text-red-400',    bg: 'bg-red-500/10',   border: 'border-red-500/20' },
};

const MOCK_DRIVERS: Driver[] = [
  { id: 'd1', full_name: 'أحمد محمد الخالدي', phone: '+962791234567', car_type: 'ev_sedan', car_model: 'Tesla Model 3 2023', car_plate: '87-12345', approval_status: 'approved', rating: 4.9, wallet_balance: 12.50, total_rides: 234, created_at: '2025-12-01', cliq_alias: '0791234567', national_id_number: '9912345678', license_number: 'D-1234567' },
  { id: 'd2', full_name: 'سامر إبراهيم النعيمي', phone: '+962790987654', car_type: 'ev_suv', car_model: 'BYD Atto 3 2024', car_plate: '23-45678', approval_status: 'pending', rating: 0, wallet_balance: 0, total_rides: 0, created_at: '2026-06-12', cliq_alias: '0790987654', national_id_number: '8898765432', license_number: 'D-7654321' },
  { id: 'd3', full_name: 'خالد يوسف الشمري', phone: '+962795551234', car_type: 'ev_luxury', car_model: 'Mercedes EQS 2024', car_plate: '11-98765', approval_status: 'approved', rating: 5.0, wallet_balance: 45.00, total_rides: 512, created_at: '2025-11-15', cliq_alias: '0795551234', national_id_number: '8765432190', license_number: 'D-9876543' },
  { id: 'd4', full_name: 'رامي عبدالله حسين', phone: '+962799001122', car_type: 'ev_mini', car_model: 'NETA V 2024', car_plate: '55-33221', approval_status: 'rejected', rating: 0, wallet_balance: 0, total_rides: 0, created_at: '2026-05-20', cliq_alias: '0799001122', national_id_number: '9001122334', license_number: 'D-1122334' },
  { id: 'd5', full_name: 'محمد علي القاسم', phone: '+962786543210', car_type: 'ev_taxi', car_model: 'BYD Han 2023', car_plate: '34-56789', approval_status: 'approved', rating: 4.7, wallet_balance: 2.30, total_rides: 89, created_at: '2026-01-10', cliq_alias: '0786543210', national_id_number: '7654321098', license_number: 'D-6543210' },
];

function StarRating({ value }: { value: number }) {
  if (!value) return <span className="text-gray-600 text-xs font-bold">—</span>;
  return (
    <div className="flex items-center gap-1">
      <span className="text-amber-400 text-xs">★</span>
      <span className="text-white text-sm font-bold">{value.toFixed(1)}</span>
    </div>
  );
}

export default function DriversPage() {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [filtered, setFiltered] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [search, setSearch] = useState('');
  const [selectedDriver, setSelectedDriver] = useState<Driver | null>(null);

  const getToken = () => localStorage.getItem('evo_admin_token') || '';
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [actionMsg, setActionMsg] = useState('');

  // ── Add Captain Modal ──
  const [showAddModal, setShowAddModal] = useState(false);
  const [addForm, setAddForm] = useState<NewCaptainForm>({
    fullName: '', phone: '', email: '', carType: 'ev_sedan', carModel: '', carPlate: '', cliqAlias: '',
  });
  const [addSubmitting, setAddSubmitting] = useState(false);
  const [addError, setAddError] = useState('');
  const [addSuccess, setAddSuccess] = useState('');
  const [deletingDriver, setDeletingDriver] = useState(false);

  const fetchDrivers = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/drivers`, {
        headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${getToken()}` },
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      setDrivers(data.drivers || data || []);
    } catch (err: any) {
      console.error('Fetch drivers error:', err);
      // 🚫 NEVER use mock data in production — only in local dev
      if (process.env.NODE_ENV === 'development' && !process.env.NEXT_PUBLIC_API_URL?.includes('onrender.com')) {
        console.warn('⚠️ Using MOCK_DRIVERS fallback (dev mode only)');
        setDrivers(MOCK_DRIVERS);
      } else {
        setError('تعذر الاتصال بالخادم. تأكد أن السيرفر يعمل على الرابط: ' + (process.env.NEXT_PUBLIC_API_URL || 'localhost:5000'));
      }
      setLoading(false);
    }
  }, []);

  const handleStatusChange = async (driverId: string, newStatus: 'active' | 'suspended') => {
    setActionLoading(driverId);
    setActionMsg('');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/users/${driverId}/status`, {
        method: 'PATCH',
        headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${getToken()}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus }),
      });
      if (!res.ok) throw new Error();
      setActionMsg(newStatus === 'suspended' ? 'تم تعليق الكابتن بنجاح ✅' : 'تم تفعيل الكابتن بنجاح ✅');
      await fetchDrivers();
    } catch {
      setActionMsg('حدث خطأ — تأكد من تشغيل السيرفر');
    } finally {
      setActionLoading(null);
      setTimeout(() => setActionMsg(''), 3000);
    }
  };

  const handleCreateCaptain = async () => {
    setAddError('');
    setAddSuccess('');
    if (!addForm.fullName || !addForm.phone || !addForm.email || !addForm.carPlate || !addForm.cliqAlias) {
      setAddError('الرجاء تعبئة جميع الحقول المطلوبة');
      return;
    }
    setAddSubmitting(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/drivers`, {
        method: 'POST',
        headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${getToken()}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(addForm),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || data.details || 'فشل إضافة الكابتن');
      setAddSuccess(`✅ تم إضافة الكابتن ${data.driver?.fullName || addForm.fullName} بنجاح!`);
      setTimeout(() => { setShowAddModal(false); setAddSuccess(''); setAddForm({ fullName: '', phone: '', email: '', carType: 'ev_sedan', carModel: '', carPlate: '', cliqAlias: '' }); }, 1500);
      await fetchDrivers();
    } catch (e: any) {
      setAddError(e.message);
    } finally {
      setAddSubmitting(false);
    }
  };

  const handleDeleteCaptain = async () => {
    if (!selectedDriver) return;
    if (!confirm(`⚠️ هل أنت متأكد من حذف الكابتن "${selectedDriver.full_name}" (${selectedDriver.car_plate})؟\n\nلا يمكن التراجع عن هذا الإجراء.`)) return;
    setDeletingDriver(true);
    setActionMsg('');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/drivers/${selectedDriver.id}`, {
        method: 'DELETE',
        headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${getToken()}` },
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'فشل حذف الكابتن');
      setActionMsg(data.message || 'تم حذف الكابتن بنجاح ✅');
      setSelectedDriver(null);
      await fetchDrivers();
    } catch (e: any) {
      setActionMsg(`❌ ${e.message}`);
    } finally {
      setDeletingDriver(false);
      setTimeout(() => setActionMsg(''), 4000);
    }
  };

  useEffect(() => { fetchDrivers(); }, [fetchDrivers]);

  useEffect(() => {
    let result = drivers;
    if (statusFilter !== 'all') result = result.filter(d => d.approval_status === statusFilter);
    if (search.trim()) {
      const q = search.toLowerCase();
      result = result.filter(d =>
        d.full_name.includes(q) || d.phone.includes(q) || d.car_plate.toLowerCase().includes(q)
      );
    }
    setFiltered(result);
  }, [drivers, statusFilter, search]);

  const statusCounts = {
    all: drivers.length,
    pending: drivers.filter(d => d.approval_status === 'pending').length,
    approved: drivers.filter(d => d.approval_status === 'approved').length,
    rejected: drivers.filter(d => d.approval_status === 'rejected').length,
  };

  return (
    <div dir="rtl" className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-black text-white">الكباتن 👥</h1>
          <p className="text-gray-400 text-sm mt-1">جميع السائقين المسجلين في المنصة</p>
        </div>
        <button
          onClick={() => { setShowAddModal(true); setAddError(''); setAddSuccess(''); }}
          className="bg-[var(--color-brand-500)] hover:bg-[var(--color-brand-600)] text-[#0B0F19] font-bold px-5 py-2.5 rounded-xl transition-all active:scale-95 flex items-center gap-2 shadow-[0_0_15px_rgba(0,200,83,0.3)]"
        >
          <span className="text-lg">+</span> إضافة كابتن
        </button>
      </div>

      {error && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-2xl px-5 py-4 flex items-center gap-3 font-bold">
          <span>⚠️</span>
          <p className="text-red-400 text-sm">{error}</p>
          <button onClick={fetchDrivers} className="mr-auto text-red-400 hover:text-red-300 text-sm underline">إعادة المحاولة</button>
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-wrap gap-3 items-center">
        {/* Status Tabs */}
        <div className="flex gap-1 bg-[var(--color-card)] border border-white/5 rounded-xl p-1 shadow-md">
          {(['all', 'pending', 'approved', 'rejected'] as StatusFilter[]).map(s => (
            <button
              key={s}
              onClick={() => setStatusFilter(s)}
              className={`px-4 py-2 rounded-lg text-sm font-bold transition-all flex items-center gap-1.5 ${
                statusFilter === s
                  ? 'bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] border border-[var(--color-brand-500)]/20'
                  : 'text-gray-400 hover:text-white border border-transparent'
              }`}
            >
              {s === 'all' ? 'الكل' : STATUS_META[s].label}
              <span className={`text-xs px-2 py-0.5 rounded-full font-cy-bold ${
                statusFilter === s ? 'bg-[var(--color-brand-500)]/20 text-[var(--color-brand-500)]' : 'bg-white/5 text-gray-400'
              }`}>{statusCounts[s]}</span>
            </button>
          ))}
        </div>

        {/* Search */}
        <div className="flex-1 min-w-[200px]">
          <div className="relative shadow-md rounded-xl">
            <span className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-500">🔍</span>
            <input
              type="text"
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="بحث بالاسم، الهاتف، أو رقم اللوحة..."
              className="w-full bg-[var(--color-card)] border border-white/5 focus:border-[var(--color-brand-500)] rounded-xl pr-12 pl-4 py-3 text-white placeholder-gray-500 outline-none transition-colors text-sm font-bold"
            />
          </div>
        </div>

        <button
          onClick={fetchDrivers}
          className="px-5 py-3 bg-[var(--color-card)] border border-white/5 hover:border-[var(--color-brand-500)]/40 text-gray-300 hover:text-white rounded-xl transition-all text-sm font-bold shadow-md"
        >
          🔄 تحديث
        </button>
      </div>

      {/* Main Layout: Table + Detail Panel */}
      <div className="flex gap-4">
        {/* Table */}
        <div className={`bg-[var(--color-card)] border border-white/5 rounded-3xl overflow-hidden flex-1 transition-all shadow-lg`}>
          {loading ? (
            <div className="flex items-center justify-center h-48">
              <div className="w-8 h-8 border-4 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" />
            </div>
          ) : filtered.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-48 text-gray-500">
              <span className="text-5xl mb-3 opacity-50">🔍</span>
              <p className="font-bold">لا توجد نتائج</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-white/5 bg-[#0B0F19]/40">
                    <th className="px-5 py-4 text-right text-gray-400 font-bold">الكابتن</th>
                    <th className="px-4 py-4 text-right text-gray-400 font-bold">الهاتف</th>
                    <th className="px-4 py-4 text-right text-gray-400 font-bold">نوع السيارة</th>
                    <th className="px-4 py-4 text-right text-gray-400 font-bold">اللوحة</th>
                    <th className="px-4 py-4 text-right text-gray-400 font-bold">الحالة</th>
                    <th className="px-4 py-4 text-right text-gray-400 font-bold">التقييم</th>
                    <th className="px-4 py-4 text-right text-gray-400 font-bold">الرصيد</th>
                    <th className="px-4 py-4 text-right text-gray-400 font-bold">الرحلات</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-white/5">
                  {filtered.map(driver => {
                    const statusMeta = STATUS_META[driver.approval_status];
                    const carMeta = CAR_TYPE_META[driver.car_type];
                    const isSelected = selectedDriver?.id === driver.id;
                    return (
                      <tr
                        key={driver.id}
                        onClick={() => setSelectedDriver(isSelected ? null : driver)}
                        className={`cursor-pointer transition-colors ${
                          isSelected ? 'bg-[var(--color-brand-500)]/5 border-r-2 border-r-[var(--color-brand-500)]' : 'hover:bg-white/5'
                        }`}
                      >
                        <td className="px-5 py-4">
                          <div className="flex items-center gap-3">
                            <div className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-sm shrink-0 border ${
                              driver.approval_status === 'approved' 
                                ? 'bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] border-[var(--color-brand-500)]/20'
                                : driver.approval_status === 'pending'
                                ? 'bg-amber-500/10 text-amber-400 border-amber-500/20'
                                : 'bg-red-500/10 text-red-400 border-red-500/20'
                            }`}>
                              {driver.full_name.charAt(0)}
                            </div>
                            <div>
                              <p className="font-bold text-white mb-0.5">{driver.full_name}</p>
                              <p className="text-gray-500 text-xs font-cy-bold">{new Date(driver.created_at).toLocaleDateString('ar-JO-u-nu-latn')}</p>
                            </div>
                          </div>
                        </td>
                        <td className="px-4 py-4 text-gray-300 font-cy-bold text-xs">{driver.phone}</td>
                        <td className="px-4 py-4">
                          <span className="flex items-center gap-1.5 text-white font-bold">
                            <span>{carMeta?.emoji}</span>
                            <span className="text-gray-300 text-xs">{carMeta?.name || driver.car_type}</span>
                          </span>
                        </td>
                        <td className="px-4 py-4">
                          <code className="bg-white/5 border border-white/10 text-gray-300 font-cy-bold text-xs px-2 py-1.5 rounded-lg">{driver.car_plate}</code>
                        </td>
                        <td className="px-4 py-4">
                          <span className={`${statusMeta.bg} ${statusMeta.border} border ${statusMeta.color} text-xs font-bold px-2.5 py-1 rounded-full`}>
                            {statusMeta.label}
                          </span>
                        </td>
                        <td className="px-4 py-4"><StarRating value={driver.rating} /></td>
                        <td className="px-4 py-4">
                          <span className={`font-cy-bold text-sm ${driver.wallet_balance < 3 && driver.approval_status === 'approved' ? 'text-red-400' : 'text-white'}`}>
                            {driver.wallet_balance.toFixed(2)} <span className="text-gray-500 text-[10px] font-bold">د.أ</span>
                          </span>
                        </td>
                        <td className="px-4 py-4 text-white font-cy-bold">{driver.total_rides.toLocaleString('en-US')}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Detail Panel */}
        {selectedDriver && (
          <div className="w-80 shrink-0 bg-[var(--color-card)] border border-white/5 rounded-3xl p-6 space-y-5 self-start sticky top-24 shadow-xl">
            <div className="flex items-center justify-between">
              <h3 className="font-black text-white text-lg">تفاصيل الكابتن</h3>
              <button onClick={() => setSelectedDriver(null)} className="text-gray-500 hover:text-white text-2xl leading-none">×</button>
            </div>

            {/* Avatar */}
            <div className="flex items-center gap-4">
              <div className={`w-16 h-16 rounded-2xl flex items-center justify-center font-black text-2xl border ${
                  selectedDriver.approval_status === 'approved' 
                    ? 'bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] border-[var(--color-brand-500)]/20'
                    : selectedDriver.approval_status === 'pending'
                    ? 'bg-amber-500/10 text-amber-400 border-amber-500/20'
                    : 'bg-red-500/10 text-red-400 border-red-500/20'
              }`}>
                {selectedDriver.full_name.charAt(0)}
              </div>
              <div>
                <p className="font-black text-white text-lg leading-tight">{selectedDriver.full_name}</p>
                <p className="text-gray-400 text-sm font-cy-bold mt-1">{selectedDriver.phone}</p>
                <span className={`${STATUS_META[selectedDriver.approval_status].bg} ${STATUS_META[selectedDriver.approval_status].color} border ${STATUS_META[selectedDriver.approval_status].border} text-xs font-bold px-2.5 py-0.5 rounded-full mt-2 inline-block`}>
                  {STATUS_META[selectedDriver.approval_status].label}
                </span>
              </div>
            </div>

            {/* Info */}
            <div className="space-y-2">
              {[
                { label: 'رقم الهوية',  value: selectedDriver.national_id_number },
                { label: 'رقم الرخصة', value: selectedDriver.license_number },
                { label: 'كليك (CliQ)', value: selectedDriver.cliq_alias },
                { label: 'نوع السيارة', value: `${CAR_TYPE_META[selectedDriver.car_type]?.emoji} ${CAR_TYPE_META[selectedDriver.car_type]?.name}` },
                { label: 'موديل السيارة', value: selectedDriver.car_model },
                { label: 'رقم اللوحة',  value: selectedDriver.car_plate },
              ].filter(i => i.value).map(({ label, value }) => (
                <div key={label} className="bg-[#0B0F19] rounded-xl px-4 py-3 flex justify-between items-center border border-white/5">
                  <p className="text-gray-500 text-xs font-bold">{label}</p>
                  <p className="text-white text-sm font-cy-bold">{value}</p>
                </div>
              ))}
            </div>

            {/* Stats */}
            <div className="grid grid-cols-3 gap-3">
              <div className="bg-[#0B0F19] rounded-2xl p-3 text-center border border-white/5">
                <p className="text-gray-500 text-xs font-bold mb-1">رحلات</p>
                <p className="text-white font-cy-bold text-lg">{selectedDriver.total_rides}</p>
              </div>
              <div className="bg-[#0B0F19] rounded-2xl p-3 text-center border border-white/5">
                <p className="text-gray-500 text-xs font-bold mb-1">تقييم</p>
                <p className="text-amber-400 font-cy-bold text-lg">{selectedDriver.rating || '—'}</p>
              </div>
              <div className="bg-[#0B0F19] rounded-2xl p-3 text-center border border-white/5">
                <p className="text-gray-500 text-xs font-bold mb-1">رصيد</p>
                <p className={`font-cy-bold text-lg ${selectedDriver.wallet_balance < 3 ? 'text-red-400' : 'text-[var(--color-brand-500)]'}`}>
                  {selectedDriver.wallet_balance.toFixed(1)}
                </p>
              </div>
            </div>

            {/* Document Links */}
            {(selectedDriver.national_id_front_url || selectedDriver.license_photo_url) && (
              <div>
                <p className="text-gray-500 text-xs mb-3 font-bold">الوثائق</p>
                <div className="space-y-2">
                  {[
                    { label: 'هوية أمامية', url: selectedDriver.national_id_front_url },
                    { label: 'هوية خلفية',  url: selectedDriver.national_id_back_url },
                    { label: 'رخصة القيادة', url: selectedDriver.license_photo_url },
                    { label: 'عدم محكومية', url: selectedDriver.criminal_clearance_url },
                  ].filter(d => d.url).map(({ label, url }) => (
                    <a key={label} href={url} target="_blank" rel="noopener noreferrer"
                      className="flex items-center gap-2 bg-[var(--color-brand-500)]/5 hover:bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] text-sm font-bold px-4 py-3 rounded-xl border border-[var(--color-brand-500)]/20 transition-colors">
                      <span className="opacity-70">📄</span> {label}
                    </a>
                  ))}
                </div>
              </div>
            )}
            {/* Actions */}
            <div className="space-y-2 pt-2 border-t border-white/5">
              <p className="text-gray-500 text-xs font-bold mb-2">الإجراءات</p>
              {actionMsg && (
                <div className="bg-[var(--color-brand-500)]/10 border border-[var(--color-brand-500)]/30 rounded-xl px-4 py-2 text-xs font-bold text-[var(--color-brand-500)]">
                  {actionMsg}
                </div>
              )}
              <div className="flex gap-2">
                <button
                  onClick={() => handleStatusChange(selectedDriver.id, 'active')}
                  disabled={actionLoading === selectedDriver.id}
                  className="flex-1 py-2.5 rounded-xl text-xs font-bold bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] border border-[var(--color-brand-500)]/30 hover:bg-[var(--color-brand-500)]/20 transition-colors disabled:opacity-40"
                >
                  {actionLoading === selectedDriver.id ? '...' : '✅ تفعيل'}
                </button>
                <button
                  onClick={() => handleStatusChange(selectedDriver.id, 'suspended')}
                  disabled={actionLoading === selectedDriver.id}
                  className="flex-1 py-2.5 rounded-xl text-xs font-bold bg-red-500/10 text-red-400 border border-red-500/30 hover:bg-red-500/20 transition-colors disabled:opacity-40"
                >
                  {actionLoading === selectedDriver.id ? '...' : '🚫 تعليق'}
                </button>
              </div>
              <a
                href={`/dashboard/wallets?driver=${selectedDriver.id}`}
                className="flex items-center justify-center gap-2 w-full py-2.5 rounded-xl text-xs font-bold bg-blue-500/10 text-blue-400 border border-blue-500/30 hover:bg-blue-500/20 transition-colors"
              >
                💰 شحن المحفظة
              </a>
              <button
                onClick={handleDeleteCaptain}
                disabled={deletingDriver}
                className="flex items-center justify-center gap-2 w-full py-2.5 rounded-xl text-xs font-bold bg-red-500/10 text-red-400 border border-red-500/30 hover:bg-red-500/20 transition-colors disabled:opacity-40"
              >
                {deletingDriver ? '⏳ جاري الحذف...' : '🗑️ حذف الكابتن'}
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Add Captain Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm" onClick={() => setShowAddModal(false)}>
          <div dir="rtl" className="bg-[#0F1525] border border-white/10 rounded-3xl p-6 w-full max-w-lg mx-4 shadow-2xl animate-fade-in-up" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-xl font-black text-white">🧑‍✈️ إضافة كابتن جديد</h2>
              <button onClick={() => setShowAddModal(false)} className="text-gray-500 hover:text-white text-2xl leading-none">×</button>
            </div>

            {addError && (
              <div className="bg-red-500/10 border border-red-500/30 rounded-xl px-4 py-3 mb-4 text-red-400 text-sm font-bold">{addError}</div>
            )}
            {addSuccess && (
              <div className="bg-[var(--color-brand-500)]/10 border border-[var(--color-brand-500)]/30 rounded-xl px-4 py-3 mb-4 text-[var(--color-brand-500)] text-sm font-bold">{addSuccess}</div>
            )}

            <div className="space-y-4">
              <div>
                <label className="text-gray-400 text-xs font-bold block mb-1.5">الاسم الكامل *</label>
                <input type="text" value={addForm.fullName} onChange={e => setAddForm(f => ({ ...f, fullName: e.target.value }))}
                  placeholder="مثال: أحمد محمد الخالدي"
                  className="w-full bg-[#0B0F19] border border-white/10 focus:border-[var(--color-brand-500)] rounded-xl px-4 py-3 text-white placeholder-gray-600 outline-none text-sm font-bold" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-gray-400 text-xs font-bold block mb-1.5">رقم الهاتف *</label>
                  <input type="text" value={addForm.phone} onChange={e => setAddForm(f => ({ ...f, phone: e.target.value }))}
                    placeholder="+962791234567"
                    className="w-full bg-[#0B0F19] border border-white/10 focus:border-[var(--color-brand-500)] rounded-xl px-4 py-3 text-white placeholder-gray-600 outline-none text-sm font-cy-bold" />
                </div>
                <div>
                  <label className="text-gray-400 text-xs font-bold block mb-1.5">البريد الإلكتروني *</label>
                  <input type="email" value={addForm.email} onChange={e => setAddForm(f => ({ ...f, email: e.target.value }))}
                    placeholder="driver@evo.jo"
                    className="w-full bg-[#0B0F19] border border-white/10 focus:border-[var(--color-brand-500)] rounded-xl px-4 py-3 text-white placeholder-gray-600 outline-none text-sm font-cy-bold" />
                </div>
              </div>
              <div>
                <label className="text-gray-400 text-xs font-bold block mb-1.5">نوع السيارة *</label>
                <select value={addForm.carType} onChange={e => setAddForm(f => ({ ...f, carType: e.target.value }))}
                  className="w-full bg-[#0B0F19] border border-white/10 focus:border-[var(--color-brand-500)] rounded-xl px-4 py-3 text-white outline-none text-sm font-bold">
                  {Object.entries(CAR_TYPE_META).map(([key, meta]) => (
                    <option key={key} value={key}>{meta.emoji} {meta.name}</option>
                  ))}
                </select>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-gray-400 text-xs font-bold block mb-1.5">موديل السيارة</label>
                  <input type="text" value={addForm.carModel} onChange={e => setAddForm(f => ({ ...f, carModel: e.target.value }))}
                    placeholder="Tesla Model 3"
                    className="w-full bg-[#0B0F19] border border-white/10 focus:border-[var(--color-brand-500)] rounded-xl px-4 py-3 text-white placeholder-gray-600 outline-none text-sm font-bold" />
                </div>
                <div>
                  <label className="text-gray-400 text-xs font-bold block mb-1.5">رقم اللوحة *</label>
                  <input type="text" value={addForm.carPlate} onChange={e => setAddForm(f => ({ ...f, carPlate: e.target.value }))}
                    placeholder="87-12345"
                    className="w-full bg-[#0B0F19] border border-white/10 focus:border-[var(--color-brand-500)] rounded-xl px-4 py-3 text-white placeholder-gray-600 outline-none text-sm font-cy-bold" />
                </div>
              </div>
              <div>
                <label className="text-gray-400 text-xs font-bold block mb-1.5">معرف CliQ (للدفعات) *</label>
                <input type="text" value={addForm.cliqAlias} onChange={e => setAddForm(f => ({ ...f, cliqAlias: e.target.value }))}
                  placeholder="ahmad_cliq"
                  className="w-full bg-[#0B0F19] border border-white/10 focus:border-[var(--color-brand-500)] rounded-xl px-4 py-3 text-white placeholder-gray-600 outline-none text-sm font-bold" />
              </div>
            </div>

            <div className="flex gap-3 mt-6">
              <button onClick={() => setShowAddModal(false)}
                className="flex-1 py-3 rounded-xl text-sm font-bold bg-white/5 text-gray-400 border border-white/10 hover:bg-white/10 transition-colors">
                إلغاء
              </button>
              <button onClick={handleCreateCaptain} disabled={addSubmitting}
                className="flex-1 py-3 rounded-xl text-sm font-bold bg-[var(--color-brand-500)] hover:bg-[var(--color-brand-600)] text-[#0B0F19] transition-all disabled:opacity-50">
                {addSubmitting ? '⏳ جاري الإضافة...' : '✅ إضافة الكابتن'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}


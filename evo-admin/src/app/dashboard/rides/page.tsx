'use client';

import { useEffect, useState, useCallback } from 'react';

interface Ride {
  id: string;
  ride_number?: string;
  driver_name: string;
  passenger_name: string;
  pickup_area: string;
  dropoff_area: string;
  distance_km: number;
  fare: number;
  commission: number;
  status: 'completed' | 'cancelled' | 'in_progress';
  car_type: string;
  created_at: string;
}

interface RidesResponse {
  rides: Ride[];
  total: number;
  page: number;
  total_pages: number;
  summary: {
    total_revenue: number;
    total_commission: number;
    total_rides: number;
  };
}

type StatusFilter = 'all' | 'completed' | 'cancelled' | 'in_progress';

const STATUS_META = {
  completed:   { label: 'مكتملة',     color: 'text-[var(--color-brand-500)]', bg: 'bg-[var(--color-brand-500)]/10', border: 'border-[var(--color-brand-500)]/20' },
  cancelled:   { label: 'ملغاة',       color: 'text-red-400',   bg: 'bg-red-500/10',   border: 'border-red-500/20' },
  in_progress: { label: 'جارية الآن', color: 'text-blue-400',  bg: 'bg-blue-500/10',  border: 'border-blue-500/20' },
};

const CAR_EMOJIS: Record<string, string> = {
  ev_mini: '🛵', ev_taxi: '🚕', ev_sedan: '🚗', ev_suv: '🚙', ev_luxury: '💎',
};

function genMockRides(): Ride[] {
  const drivers = ['أحمد الخالدي', 'سامر النعيمي', 'خالد الشمري', 'محمد القاسم', 'رامي حسين'];
  const passengers = ['يوسف العمري', 'ليلى منصور', 'كريم صالح', 'نور الحمدان', 'سارة البكر', 'هاني الشريف'];
  const areas = ['العبدلي', 'الدوار السابع', 'الجبيهة', 'صويلح', 'مرج الحمام', 'الرابية', 'خلدا', 'عبدون'];
  const statuses: Ride['status'][] = ['completed', 'completed', 'completed', 'cancelled', 'in_progress'];
  const carTypes = ['ev_mini', 'ev_taxi', 'ev_sedan', 'ev_suv', 'ev_luxury'];

  return Array.from({ length: 25 }, (_, i) => {
    const fare = parseFloat((1.5 + Math.random() * 8).toFixed(3));
    const status = statuses[Math.floor(Math.random() * statuses.length)];
    return {
      id: `r${i + 1}`,
      ride_number: `EVO-${String(10000 + i).padStart(5, '0')}`,
      driver_name: drivers[Math.floor(Math.random() * drivers.length)],
      passenger_name: passengers[Math.floor(Math.random() * passengers.length)],
      pickup_area: areas[Math.floor(Math.random() * areas.length)],
      dropoff_area: areas[Math.floor(Math.random() * areas.length)],
      distance_km: parseFloat((2 + Math.random() * 18).toFixed(1)),
      fare,
      commission: parseFloat((fare * 0.13).toFixed(3)),
      status,
      car_type: carTypes[Math.floor(Math.random() * carTypes.length)],
      created_at: new Date(Date.now() - Math.random() * 86400000 * 7).toISOString(),
    };
  });
}

const PAGE_LIMIT = 20;

export default function RidesPage() {
  const [data, setData] = useState<RidesResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');

  const getToken = () => localStorage.getItem('evo_admin_token') || '';

  const fetchRides = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const params = new URLSearchParams({ page: String(page), limit: String(PAGE_LIMIT) });
      if (statusFilter !== 'all') params.set('status', statusFilter);
      if (dateFrom) params.set('from', dateFrom);
      if (dateTo) params.set('to', dateTo);

      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/rides?${params}`, {
        headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${getToken()}` },
      });
      if (!res.ok) throw new Error();
      const json = await res.json();
      setData(json);
    } catch {
      console.error('Failed to fetch rides');
      setData({ rides: [], total: 0, page: 1, total_pages: 0, summary: { total_rides: 0, total_revenue: 0, total_commission: 0 } });
    } finally {
      setLoading(false);
    }
  }, [page, statusFilter, dateFrom, dateTo]);

  useEffect(() => { fetchRides(); }, [fetchRides]);
  useEffect(() => { setPage(1); }, [statusFilter, dateFrom, dateTo]);

  return (
    <div dir="rtl" className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-black text-white">الرحلات 🛣️</h1>
        <p className="text-gray-400 text-sm mt-1">سجل جميع الرحلات والإيرادات</p>
      </div>

      {error && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-2xl px-5 py-4 flex items-center gap-3 font-bold">
          <span>⚠️</span>
          <p className="text-red-400 text-sm">{error}</p>
          <button onClick={fetchRides} className="mr-auto text-red-400 hover:text-red-300 text-sm underline">إعادة المحاولة</button>
        </div>
      )}

      {/* Summary Cards */}
      {data?.summary && (
        <div className="grid grid-cols-3 gap-4">
          <div className="bg-[var(--color-card)] border border-white/5 shadow-md rounded-3xl p-6 hover:border-[var(--color-brand-500)]/20 transition-all">
            <p className="text-gray-400 text-sm font-bold">إجمالي الرحلات</p>
            <p className="text-3xl font-cy-bold text-white mt-1">{data.summary.total_rides.toLocaleString('en-US')}</p>
          </div>
          <div className="bg-[var(--color-card)] border border-[var(--color-brand-500)]/20 shadow-[0_0_15px_rgba(0,200,83,0.05)] rounded-3xl p-6 relative overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-[var(--color-brand-500)] opacity-10 blur-3xl rounded-full"></div>
            <p className="text-gray-400 text-sm font-bold">إجمالي الإيرادات</p>
            <p className="text-3xl font-cy-bold text-[var(--color-brand-500)] mt-1 relative z-10">
              {data.summary.total_revenue.toFixed(3)} <span className="text-sm text-gray-500 font-bold">د.أ</span>
            </p>
          </div>
          <div className="bg-[var(--color-card)] border border-blue-500/20 shadow-[0_0_15px_rgba(59,130,246,0.05)] rounded-3xl p-6 relative overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-blue-500 opacity-10 blur-3xl rounded-full"></div>
            <p className="text-gray-400 text-sm font-bold">إجمالي العمولات (13%)</p>
            <p className="text-3xl font-cy-bold text-blue-400 mt-1 relative z-10">
              {data.summary.total_commission.toFixed(3)} <span className="text-sm text-gray-500 font-bold">د.أ</span>
            </p>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-wrap gap-3 items-center">
        {/* Status Tabs */}
        <div className="flex gap-1 bg-[var(--color-card)] border border-white/5 rounded-xl p-1 shadow-md">
          {(['all', 'completed', 'cancelled', 'in_progress'] as StatusFilter[]).map(s => (
            <button
              key={s}
              onClick={() => setStatusFilter(s)}
              className={`px-4 py-2 rounded-lg text-sm font-bold transition-all whitespace-nowrap ${
                statusFilter === s
                  ? 'bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] border border-[var(--color-brand-500)]/20'
                  : 'text-gray-400 hover:text-white border border-transparent'
              }`}
            >
              {s === 'all' ? 'الكل' : STATUS_META[s].label}
            </button>
          ))}
        </div>

        {/* Date Range */}
        <div className="flex items-center gap-2">
          <input type="date" value={dateFrom} onChange={e => setDateFrom(e.target.value)}
            className="bg-[var(--color-card)] border border-white/5 focus:border-[var(--color-brand-500)] shadow-md rounded-xl px-4 py-2 text-white text-sm outline-none transition-colors font-cy-bold"
            dir="ltr"
          />
          <span className="text-gray-600 text-sm">→</span>
          <input type="date" value={dateTo} onChange={e => setDateTo(e.target.value)}
            className="bg-[var(--color-card)] border border-white/5 focus:border-[var(--color-brand-500)] shadow-md rounded-xl px-4 py-2 text-white text-sm outline-none transition-colors font-cy-bold"
            dir="ltr"
          />
          {(dateFrom || dateTo) && (
            <button onClick={() => { setDateFrom(''); setDateTo(''); }} className="text-gray-500 hover:text-white text-sm font-bold">✕ مسح</button>
          )}
        </div>

        <button onClick={fetchRides} className="px-5 py-2.5 bg-[var(--color-card)] border border-white/5 hover:border-[var(--color-brand-500)]/40 text-gray-300 hover:text-white rounded-xl transition-all text-sm shadow-md font-bold">
          🔄
        </button>
      </div>

      {/* Table */}
      <div className="bg-[var(--color-card)] border border-white/5 rounded-3xl shadow-lg overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center h-48">
            <div className="w-8 h-8 border-4 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" />
          </div>
        ) : !data || data.rides.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-48 text-gray-500">
            <span className="text-5xl mb-3 opacity-50">🛣️</span>
            <p className="font-bold">لا توجد رحلات</p>
          </div>
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-white/5 bg-[#0B0F19]/40">
                    <th className="px-4 py-4 text-right text-gray-400 font-bold whitespace-nowrap">رقم الرحلة</th>
                    <th className="px-4 py-4 text-right text-gray-400 font-bold">الكابتن</th>
                    <th className="px-4 py-4 text-right text-gray-400 font-bold">الراكب</th>
                    <th className="px-4 py-4 text-right text-gray-400 font-bold">المسار</th>
                    <th className="px-4 py-4 text-right text-gray-400 font-bold">المسافة</th>
                    <th className="px-4 py-4 text-right text-gray-400 font-bold">القيمة</th>
                    <th className="px-4 py-4 text-right text-gray-400 font-bold">العمولة</th>
                    <th className="px-4 py-4 text-right text-gray-400 font-bold">الحالة</th>
                    <th className="px-4 py-4 text-right text-gray-400 font-bold">التاريخ</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-white/5">
                  {data.rides.map(ride => {
                    const sm = STATUS_META[ride.status];
                    return (
                      <tr key={ride.id} className="hover:bg-white/5 transition-colors">
                        <td className="px-4 py-4">
                          <code className="text-[var(--color-brand-500)] bg-[var(--color-brand-500)]/10 px-2 py-1 rounded-md text-xs font-cy-bold border border-[var(--color-brand-500)]/20">{ride.ride_number || ride.id}</code>
                        </td>
                        <td className="px-4 py-4">
                          <div className="flex items-center gap-2">
                            <span className="text-lg">{CAR_EMOJIS[ride.car_type] || '🚗'}</span>
                            <span className="text-white font-bold">{ride.driver_name}</span>
                          </div>
                        </td>
                        <td className="px-4 py-4 text-gray-300 font-bold">{ride.passenger_name}</td>
                        <td className="px-4 py-4">
                          <div className="text-xs text-gray-400 whitespace-nowrap font-bold flex items-center gap-1.5">
                            <span className="bg-[#0B0F19] px-2 py-1 rounded-md border border-white/5">{ride.pickup_area}</span>
                            <span className="text-gray-600">→</span>
                            <span className="bg-[#0B0F19] px-2 py-1 rounded-md border border-white/5">{ride.dropoff_area}</span>
                          </div>
                        </td>
                        <td className="px-4 py-4 text-gray-300 text-sm whitespace-nowrap font-cy-bold">
                          {ride.distance_km} <span className="text-[10px] text-gray-500 font-bold">كم</span>
                        </td>
                        <td className="px-4 py-4">
                          <span className="text-white font-cy-bold">{ride.fare.toFixed(3)}</span>
                          <span className="text-gray-500 text-[10px] font-bold"> د.أ</span>
                        </td>
                        <td className="px-4 py-4">
                          <span className="text-blue-400 font-cy-bold">{ride.commission.toFixed(3)}</span>
                          <span className="text-gray-500 text-[10px] font-bold"> د.أ</span>
                        </td>
                        <td className="px-4 py-4">
                          <span className={`${sm.bg} ${sm.border} border ${sm.color} text-xs font-bold px-2.5 py-1 rounded-full whitespace-nowrap`}>
                            {sm.label}
                          </span>
                        </td>
                        <td className="px-4 py-4 text-gray-500 text-xs whitespace-nowrap font-cy-bold">
                          {new Date(ride.created_at).toLocaleDateString('ar-JO-u-nu-latn', { month: 'short', day: 'numeric' })}
                          <br />
                          <span className="text-gray-600 mt-1 inline-block">{new Date(ride.created_at).toLocaleTimeString('ar-JO-u-nu-latn', { hour: '2-digit', minute: '2-digit' })}</span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
                {/* Summary Footer */}
                <tfoot>
                  <tr className="border-t border-white/10 bg-[#0B0F19]/80">
                    <td colSpan={5} className="px-4 py-4 text-gray-400 text-sm font-bold text-right">
                      المجموع ({data.summary.total_rides} رحلة)
                    </td>
                    <td className="px-4 py-4">
                      <span className="text-[var(--color-brand-500)] font-cy-bold text-base">{data.summary.total_revenue.toFixed(3)}</span>
                      <span className="text-gray-500 text-[10px] font-bold"> د.أ</span>
                    </td>
                    <td className="px-4 py-4">
                      <span className="text-blue-400 font-cy-bold text-base">{data.summary.total_commission.toFixed(3)}</span>
                      <span className="text-gray-500 text-[10px] font-bold"> د.أ</span>
                    </td>
                    <td colSpan={2} />
                  </tr>
                </tfoot>
              </table>
            </div>

            {/* Pagination */}
            {data.total_pages > 1 && (
              <div className="flex items-center justify-between px-5 py-4 border-t border-white/5 bg-[#0B0F19]/40">
                <p className="text-gray-500 text-xs font-bold">
                  صفحة <span className="font-cy-bold">{data.page}</span> من <span className="font-cy-bold">{data.total_pages}</span> · <span className="font-cy-bold">{data.total}</span> رحلة
                </p>
                <div className="flex gap-2">
                  <button
                    onClick={() => setPage(p => Math.max(1, p - 1))}
                    disabled={page === 1}
                    className="px-3 py-1.5 text-xs bg-white/5 hover:bg-white/10 text-white rounded-lg transition-colors disabled:opacity-40 disabled:cursor-not-allowed font-bold"
                  >
                    السابق
                  </button>
                  {Array.from({ length: Math.min(data.total_pages, 5) }, (_, i) => {
                    const p = i + Math.max(1, page - 2);
                    if (p > data.total_pages) return null;
                    return (
                      <button
                        key={p}
                        onClick={() => setPage(p)}
                        className={`w-8 h-8 text-xs rounded-lg transition-colors font-cy-bold ${
                          p === page ? 'bg-[var(--color-brand-500)] text-black font-black' : 'bg-white/5 hover:bg-white/10 text-white'
                        }`}
                      >
                        {p}
                      </button>
                    );
                  })}
                  <button
                    onClick={() => setPage(p => Math.min(data.total_pages, p + 1))}
                    disabled={page === data.total_pages}
                    className="px-3 py-1.5 text-xs bg-white/5 hover:bg-white/10 text-white rounded-lg transition-colors disabled:opacity-40 disabled:cursor-not-allowed font-bold"
                  >
                    التالي
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}


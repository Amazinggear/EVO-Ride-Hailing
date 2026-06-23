"use client";

import { useEffect, useState } from "react";
import dynamic from "next/dynamic";

const MapPicker = dynamic(() => import("@/components/MapPickerComponent"), {
  ssr: false,
  loading: () => (
    <div className="h-[240px] w-full bg-white/5 animate-pulse rounded-xl flex items-center justify-center text-xs text-gray-500 border border-white/5">
      جاري تحميل الخريطة المباشرة...
    </div>
  ),
});

interface ChargingStation {
  id: string;
  name: string;
  nameAr: string;
  lat: number;
  lng: number;
  address: string;
  chargerTypes: string[];
  totalChargers: number;
  availableChargers: number;
  operator: string;
  source: "opencharge_map" | "manual";
  isVisible: boolean;
  isVerified: boolean;
  lastSynced?: string;
}

const CHARGER_COLORS: Record<string, string> = {
  "Type2": "bg-blue-500/20 text-blue-400 border-blue-500/30",
  "CCS": "bg-emerald-500/20 text-emerald-400 border-emerald-500/30",
  "CHAdeMO": "bg-amber-500/20 text-amber-400 border-amber-500/30",
};

interface AddStationModal {
  isOpen: boolean;
  name: string;
  nameAr: string;
  address: string;
  lat: string;
  lng: string;
  operator: string;
  totalChargers: string;
  chargerTypes: string[];
}

const INITIAL_MODAL: AddStationModal = {
  isOpen: false, name: "", nameAr: "", address: "", lat: "", lng: "", operator: "", totalChargers: "1", chargerTypes: [],
};

export default function ChargingStationsPage() {
  const [stations, setStations] = useState<ChargingStation[]>([]);
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState<"all" | "verified" | "unverified" | "hidden">("all");
  const [modal, setModal] = useState<AddStationModal>(INITIAL_MODAL);
  const [syncing, setSyncing] = useState(false);

  const mapBackendStation = (s: any): ChargingStation => ({
    id: s.id.toString(),
    name: s.name,
    nameAr: s.name_ar || s.name,
    lat: parseFloat(s.lat),
    lng: parseFloat(s.lng),
    address: s.address || "",
    chargerTypes: s.charger_types || [],
    totalChargers: parseInt(s.total_chargers) || 0,
    availableChargers: (s.available_chargers !== null && s.available_chargers !== undefined && s.available_chargers !== "") ? (parseInt(s.available_chargers) || 0) : (parseInt(s.total_chargers) || 0),
    operator: s.operator || "",
    source: s.source || "manual",
    isVisible: s.is_visible !== undefined ? s.is_visible : true,
    isVerified: s.is_verified !== undefined ? s.is_verified : false,
    lastSynced: s.last_synced_at,
  });

  const fetchStations = async () => {
    const token = localStorage.getItem("evo_admin_token");
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/charging-stations`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const data = await res.json();
        if (data.stations) {
          setStations(data.stations.map(mapBackendStation));
        }
      }
    } catch (err) {
      console.error("Failed to fetch stations:", err);
    }
  };

  useEffect(() => {
    fetchStations();
  }, []);

  const filtered = stations.filter(s => {
    const matchSearch = !search || s.nameAr.includes(search) || s.name.toLowerCase().includes(search.toLowerCase()) || s.address.includes(search);
    const matchFilter = filter === "all" ? true : filter === "verified" ? s.isVerified : filter === "unverified" ? !s.isVerified : !s.isVisible;
    return matchSearch && matchFilter;
  });

  const stats = {
    total: stations.length,
    verified: stations.filter(s => s.isVerified).length,
    ocm: stations.filter(s => s.source === "opencharge_map").length,
    hidden: stations.filter(s => !s.isVisible).length,
    totalChargers: stations.reduce((a, s) => a + s.totalChargers, 0),
    available: stations.reduce((a, s) => a + s.availableChargers, 0),
  };

  const handleSync = async () => {
    setSyncing(true);
    const token = localStorage.getItem("evo_admin_token");
    try {
      await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/charging-stations/sync`, {
        method: "POST",
        headers: { Authorization: `Bearer ${token}` },
      });
      await fetchStations();
    } catch (err) {
      console.error("Sync failed:", err);
    }
    setTimeout(() => setSyncing(false), 2000);
  };

  const toggleVisibility = async (id: string) => {
    const station = stations.find(s => s.id === id);
    if (!station) return;
    const newVisible = !station.isVisible;

    setStations(prev => prev.map(s => s.id === id ? { ...s, isVisible: newVisible } : s));

    const token = localStorage.getItem("evo_admin_token");
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/charging-stations/${id}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ isVisible: newVisible }),
      });
      if (!res.ok) {
        setStations(prev => prev.map(s => s.id === id ? { ...s, isVisible: !newVisible } : s));
      }
    } catch (err) {
      setStations(prev => prev.map(s => s.id === id ? { ...s, isVisible: !newVisible } : s));
    }
  };

  const toggleVerify = async (id: string) => {
    const station = stations.find(s => s.id === id);
    if (!station) return;
    const newVerified = !station.isVerified;

    setStations(prev => prev.map(s => s.id === id ? { ...s, isVerified: newVerified } : s));

    const token = localStorage.getItem("evo_admin_token");
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/charging-stations/${id}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ isVerified: newVerified }),
      });
      if (!res.ok) {
        setStations(prev => prev.map(s => s.id === id ? { ...s, isVerified: !newVerified } : s));
      }
    } catch (err) {
      setStations(prev => prev.map(s => s.id === id ? { ...s, isVerified: !newVerified } : s));
    }
  };

  const handleAddStation = async () => {
    if (!modal.name || !modal.lat || !modal.lng) return;
    const token = localStorage.getItem("evo_admin_token");
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/charging-stations`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          name: modal.name,
          nameAr: modal.nameAr || modal.name,
          lat: parseFloat(modal.lat),
          lng: parseFloat(modal.lng),
          address: modal.address,
          chargerTypes: modal.chargerTypes,
          totalChargers: parseInt(modal.totalChargers),
          operator: modal.operator,
        }),
      });
      if (res.ok) {
        const data = await res.json();
        if (data.station) {
          setStations(prev => [mapBackendStation(data.station), ...prev]);
        }
      }
    } catch (err) {
      console.error("Error adding station:", err);
    }
    setModal(INITIAL_MODAL);
  };

  const CHARGER_TYPE_OPTIONS = ["Type2", "CCS", "CHAdeMO"];

  return (
    <div className="space-y-6" dir="rtl">
      {/* HEADER */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white">محطات الشحن</h1>
          <p className="text-sm text-gray-400 mt-1">إدارة شبكة محطات شحن السيارات الكهربائية</p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={handleSync}
            disabled={syncing}
            className="bg-[var(--color-card)] border border-white/10 text-gray-300 px-4 py-2.5 rounded-xl text-sm font-bold hover:bg-white/5 transition-colors flex items-center gap-2 disabled:opacity-50"
          >
            <span className={syncing ? "animate-spin" : ""}>🔄</span>
            {syncing ? "جاري المزامنة..." : "مزامنة OpenChargeMap"}
          </button>
          <button
            onClick={() => setModal({ ...INITIAL_MODAL, isOpen: true })}
            className="bg-[var(--color-brand-500)] text-white px-4 py-2.5 rounded-xl text-sm font-bold shadow-[0_0_15px_rgba(0,200,83,0.3)] hover:bg-[var(--color-brand-600)] transition-colors"
          >
            + إضافة محطة
          </button>
        </div>
      </div>

      {/* STATS */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: "إجمالي المحطات", value: stats.total, icon: "⚡", color: "text-white" },
          { label: "موثّقة", value: stats.verified, icon: "✅", color: "text-emerald-400" },
          { label: "إجمالي الشواحن", value: stats.totalChargers, icon: "🔌", color: "text-blue-400" },
          { label: "متاحة الآن", value: stats.available, icon: "🟢", color: "text-emerald-400" },
        ].map((s, i) => (
          <div key={i} className="bg-[var(--color-card)] rounded-2xl p-4 border border-white/5">
            <div className="flex items-center gap-2 mb-2">
              <span>{s.icon}</span>
              <p className="text-xs text-gray-400 font-bold">{s.label}</p>
            </div>
            <p className={`text-3xl font-bold ${s.color}`}>{s.value}</p>
          </div>
        ))}
      </div>

      {/* SEARCH + FILTERS */}
      <div className="bg-[var(--color-card)] rounded-2xl p-4 border border-white/5 flex flex-col md:flex-row gap-4">
        <div className="relative flex-1">
          <span className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-500">🔍</span>
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            type="text"
            placeholder="ابحث باسم المحطة أو العنوان..."
            className="w-full bg-[#0B0F19] border border-white/5 rounded-xl py-3 pr-12 pl-4 text-sm text-white outline-none focus:border-[var(--color-brand-500)] transition-all font-alexandria placeholder:text-gray-500"
          />
        </div>
        <div className="flex gap-2">
          {(["all", "verified", "unverified", "hidden"] as const).map(f => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-3 py-2 rounded-xl text-xs font-bold border transition-all whitespace-nowrap ${
                filter === f
                  ? "bg-[var(--color-brand-500)] text-white border-transparent"
                  : "bg-white/5 text-gray-400 border-white/10 hover:bg-white/10"
              }`}
            >
              {f === "all" ? `الكل (${stats.total})` : f === "verified" ? `موثّق (${stats.verified})` : f === "unverified" ? `غير موثّق (${stats.total - stats.verified})` : `مخفي (${stats.hidden})`}
            </button>
          ))}
        </div>
      </div>

      {/* STATIONS TABLE */}
      <div className="bg-[var(--color-card)] rounded-3xl border border-white/5 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm text-right">
            <thead>
              <tr className="text-gray-500 text-xs border-b border-white/5 bg-[#0B0F19]">
                <th className="py-4 px-4 font-bold">المحطة</th>
                <th className="py-4 px-4 font-bold">العنوان</th>
                <th className="py-4 px-4 font-bold text-center">نوع الشاحن</th>
                <th className="py-4 px-4 font-bold text-center">الشواحن</th>
                <th className="py-4 px-4 font-bold text-center">المصدر</th>
                <th className="py-4 px-4 font-bold text-center">الحالة</th>
                <th className="py-4 px-4 font-bold text-center">إجراءات</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((station, i) => (
                <tr key={station.id} className="border-b border-white/5 last:border-0 hover:bg-white/2 transition-colors">
                  <td className="py-4 px-4">
                    <div className="flex items-start gap-2">
                      <span className="text-2xl mt-0.5">⚡</span>
                      <div>
                        <p className="font-bold text-white text-sm">{station.nameAr}</p>
                        <p className="text-xs text-gray-500" dir="ltr">{station.name}</p>
                        <p className="text-xs text-gray-600" dir="ltr">{station.lat.toFixed(4)}, {station.lng.toFixed(4)}</p>
                      </div>
                    </div>
                  </td>
                  <td className="py-4 px-4">
                    <p className="text-sm text-gray-300 max-w-[200px]">{station.address}</p>
                    <p className="text-xs text-gray-500">{station.operator}</p>
                  </td>
                  <td className="py-4 px-4 text-center">
                    <div className="flex flex-wrap gap-1 justify-center">
                      {station.chargerTypes.map(t => (
                        <span key={t} className={`px-2 py-0.5 rounded-full text-xs font-bold border ${CHARGER_COLORS[t] || "bg-white/5 text-gray-400 border-white/10"}`}>
                          {t}
                        </span>
                      ))}
                    </div>
                  </td>
                  <td className="py-4 px-4 text-center">
                    <div>
                      <p className="text-white font-bold">{station.availableChargers}/{station.totalChargers}</p>
                      <p className="text-xs text-gray-500">متاح</p>
                      <div className="w-16 h-1.5 bg-white/10 rounded-full mx-auto mt-1">
                        <div
                          className="h-full rounded-full bg-[var(--color-brand-500)]"
                          style={{ width: `${(station.availableChargers / station.totalChargers) * 100}%` }}
                        />
                      </div>
                    </div>
                  </td>
                  <td className="py-4 px-4 text-center">
                    <span className={`px-2 py-1 rounded-full text-xs font-bold border ${
                      station.source === "opencharge_map"
                        ? "bg-blue-500/10 text-blue-400 border-blue-500/20"
                        : "bg-purple-500/10 text-purple-400 border-purple-500/20"
                    }`}>
                      {station.source === "opencharge_map" ? "🌐 OCM" : "✍️ يدوي"}
                    </span>
                  </td>
                  <td className="py-4 px-4 text-center">
                    <div className="flex flex-col items-center gap-1">
                      <span className={`px-2 py-0.5 rounded-full text-xs font-bold border ${
                        station.isVerified ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/20" : "bg-orange-500/10 text-orange-400 border-orange-500/20"
                      }`}>
                        {station.isVerified ? "✅ موثّق" : "⏳ غير موثّق"}
                      </span>
                      <span className={`px-2 py-0.5 rounded-full text-xs font-bold border ${
                        station.isVisible ? "bg-white/5 text-gray-400 border-white/10" : "bg-red-500/10 text-red-400 border-red-500/20"
                      }`}>
                        {station.isVisible ? "👁️ مرئي" : "🙈 مخفي"}
                      </span>
                    </div>
                  </td>
                  <td className="py-4 px-4 text-center">
                    <div className="flex items-center justify-center gap-2">
                      <button
                        onClick={() => toggleVerify(station.id)}
                        className={`px-2 py-1 rounded-lg text-xs font-bold border transition-all ${
                          station.isVerified
                            ? "bg-white/5 text-gray-400 border-white/10 hover:bg-white/10"
                            : "bg-emerald-500/10 text-emerald-400 border-emerald-500/20 hover:bg-emerald-500/20"
                        }`}
                      >
                        {station.isVerified ? "إلغاء" : "توثيق"}
                      </button>
                      <button
                        onClick={() => toggleVisibility(station.id)}
                        className="px-2 py-1 rounded-lg text-xs font-bold bg-white/5 text-gray-400 border border-white/10 hover:bg-white/10 transition-all"
                      >
                        {station.isVisible ? "إخفاء" : "إظهار"}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={7} className="py-16 text-center text-gray-500">
                    <p className="text-4xl mb-3">⚡</p>
                    <p>لا توجد محطات تطابق البحث</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* ADD STATION MODAL */}
      {modal.isOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={() => setModal(INITIAL_MODAL)}>
          <div className="bg-[var(--color-card)] border border-white/10 rounded-3xl p-6 w-full max-w-lg shadow-2xl" onClick={e => e.stopPropagation()}>
            <h3 className="font-bold text-white text-lg mb-4">إضافة محطة شحن جديدة</h3>
            <div className="space-y-4">
              {/* Map coordinate selector */}
              <div>
                <label className="text-xs text-gray-400 block mb-2 font-bold">تحديد موقع المحطة على الخريطة (انقر لوضع دبوس الشحن)*</label>
                <MapPicker 
                  lat={parseFloat(modal.lat) || 31.9539} 
                  lng={parseFloat(modal.lng) || 35.9106} 
                  onChange={(lat, lng) => setModal(m => ({ ...m, lat: lat.toFixed(6), lng: lng.toFixed(6) }))}
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs text-gray-400 block mb-1 font-bold">اسم المحطة (EN)*</label>
                  <input value={modal.name} onChange={e => setModal(m => ({ ...m, name: e.target.value }))} placeholder="Station Name" className="w-full bg-[#0B0F19] border border-white/5 rounded-xl py-2.5 px-3 text-sm text-white outline-none focus:border-[var(--color-brand-500)] transition-all" dir="ltr" />
                </div>
                <div>
                  <label className="text-xs text-gray-400 block mb-1 font-bold">اسم المحطة (AR)</label>
                  <input value={modal.nameAr} onChange={e => setModal(m => ({ ...m, nameAr: e.target.value }))} placeholder="اسم المحطة" className="w-full bg-[#0B0F19] border border-white/5 rounded-xl py-2.5 px-3 text-sm text-white outline-none focus:border-[var(--color-brand-500)] transition-all" />
                </div>
              </div>
              <div>
                <label className="text-xs text-gray-400 block mb-1 font-bold">العنوان</label>
                <input value={modal.address} onChange={e => setModal(m => ({ ...m, address: e.target.value }))} placeholder="العنوان التفصيلي" className="w-full bg-[#0B0F19] border border-white/5 rounded-xl py-2.5 px-3 text-sm text-white outline-none focus:border-[var(--color-brand-500)] transition-all" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs text-gray-400 block mb-1 font-bold">خط العرض (Lat)*</label>
                  <input value={modal.lat} onChange={e => setModal(m => ({ ...m, lat: e.target.value }))} placeholder="31.9539" className="w-full bg-[#0B0F19] border border-white/5 rounded-xl py-2.5 px-3 text-sm text-white outline-none focus:border-[var(--color-brand-500)] transition-all" dir="ltr" />
                </div>
                <div>
                  <label className="text-xs text-gray-400 block mb-1 font-bold">خط الطول (Lng)*</label>
                  <input value={modal.lng} onChange={e => setModal(m => ({ ...m, lng: e.target.value }))} placeholder="35.9106" className="w-full bg-[#0B0F19] border border-white/5 rounded-xl py-2.5 px-3 text-sm text-white outline-none focus:border-[var(--color-brand-500)] transition-all" dir="ltr" />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs text-gray-400 block mb-1 font-bold">المشغّل</label>
                  <input value={modal.operator} onChange={e => setModal(m => ({ ...m, operator: e.target.value }))} placeholder="اسم الشركة" className="w-full bg-[#0B0F19] border border-white/5 rounded-xl py-2.5 px-3 text-sm text-white outline-none focus:border-[var(--color-brand-500)] transition-all" />
                </div>
                <div>
                  <label className="text-xs text-gray-400 block mb-1 font-bold">عدد الشواحن</label>
                  <input type="number" min="1" value={modal.totalChargers} onChange={e => setModal(m => ({ ...m, totalChargers: e.target.value }))} className="w-full bg-[#0B0F19] border border-white/5 rounded-xl py-2.5 px-3 text-sm text-white outline-none focus:border-[var(--color-brand-500)] transition-all" dir="ltr" />
                </div>
              </div>
              <div>
                <label className="text-xs text-gray-400 block mb-2 font-bold">أنواع الشواحن</label>
                <div className="flex gap-2 flex-wrap">
                  {CHARGER_TYPE_OPTIONS.map(t => (
                    <button
                      key={t}
                      onClick={() => setModal(m => ({
                        ...m,
                        chargerTypes: m.chargerTypes.includes(t) ? m.chargerTypes.filter(x => x !== t) : [...m.chargerTypes, t]
                      }))}
                      className={`px-3 py-1.5 rounded-full text-xs font-bold border transition-all ${
                        modal.chargerTypes.includes(t) ? `${CHARGER_COLORS[t]}` : "bg-white/5 text-gray-400 border-white/10"
                      }`}
                    >
                      {t}
                    </button>
                  ))}
                </div>
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button onClick={() => setModal(INITIAL_MODAL)} className="flex-1 py-3 rounded-xl border border-white/10 text-gray-400 hover:bg-white/5 transition-colors font-bold text-sm">
                إلغاء
              </button>
              <button onClick={handleAddStation} className="flex-1 py-3 rounded-xl bg-[var(--color-brand-500)] text-white font-bold text-sm hover:bg-[var(--color-brand-600)] transition-colors shadow-[0_0_15px_rgba(0,200,83,0.3)]">
                إضافة المحطة
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

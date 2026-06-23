"use client";

import { useEffect, useState } from "react";
import dynamic from "next/dynamic";

const MapLive = dynamic(() => import("@/components/MapLiveComponent"), {
  ssr: false,
  loading: () => (
    <div className="h-full w-full bg-[#0B1221] animate-pulse flex items-center justify-center text-xs text-gray-500 border border-white/5" style={{ minHeight: "500px" }}>
      جاري تحميل خريطة التتبع المباشرة...
    </div>
  ),
});

interface LiveDriver {
  id: string;
  name: string;
  phone: string;
  carType: string;
  carPlate: string;
  lat: number;
  lng: number;
  heading: number;
  speed: number;
  status: "online" | "in_ride" | "arriving";
  walletBalance: number;
  rideId?: string;
  lastSeen: string;
}

interface LiveRide {
  id: string;
  driverName: string;
  passengerName: string;
  carType: string;
  status: string;
  pickupAddress: string;
  dropoffAddress: string;
  totalFare: number;
  startedAt: string;
  pickup_lat?: number;
  pickup_lng?: number;
  dropoff_lat?: number;
  dropoff_lng?: number;
  passenger_name?: string;
}

interface Station {
  id: string;
  name: string;
  nameAr: string;
  lat: number;
  lng: number;
  address: string;
  totalChargers: number;
  availableChargers: number;
  operator: string;
  source: string;
}

const CAR_TYPE_LABELS: Record<string, string> = {
  ev_mini: "EV Mini",
  ev_taxi: "EV Taxi",
  ev_sedan: "EV Sedan",
  ev_suv: "EV SUV",
  ev_luxury: "EV Luxury",
};

const STATUS_CONFIG = {
  online: { label: "متاح", color: "text-emerald-400", bg: "bg-emerald-500/10 border-emerald-500/30", dot: "bg-emerald-400" },
  in_ride: { label: "في رحلة", color: "text-blue-400", bg: "bg-blue-500/10 border-blue-500/30", dot: "bg-blue-400" },
  arriving: { label: "في الطريق", color: "text-amber-400", bg: "bg-amber-500/10 border-amber-500/30", dot: "bg-amber-400" },
};

const getCarIcon = (carType: string) => {
  const icons: Record<string, string> = { ev_mini: "🚗", ev_taxi: "🚕", ev_sedan: "🚙", ev_suv: "🛻", ev_luxury: "🏎️" };
  return icons[carType] || "🚗";
};

export default function LiveTrackingPage() {
  const [drivers, setDrivers] = useState<LiveDriver[]>([]);
  const [rides, setRides] = useState<LiveRide[]>([]);
  const [stations, setStations] = useState<Station[]>([]);
  const [selectedDriver, setSelectedDriver] = useState<LiveDriver | null>(null);
  const [filter, setFilter] = useState<"all" | "online" | "in_ride" | "arriving">("all");
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [pulseCount, setPulseCount] = useState(0);

  const mapBackendRide = (r: any): LiveRide => ({
    id: r.id.toString(),
    driverName: r.driver_name || "قيد البحث",
    passengerName: r.passenger_name || "عميل",
    carType: r.car_type,
    status: r.status,
    pickupAddress: r.pickup_address || "",
    dropoffAddress: r.dropoff_address || "",
    totalFare: parseFloat(r.total_fare) || 0,
    startedAt: r.accepted_at 
      ? new Date(r.accepted_at).toLocaleTimeString("ar-JO-u-nu-latn", { hour: '2-digit', minute: '2-digit' }) 
      : new Date().toLocaleTimeString("ar-JO-u-nu-latn", { hour: '2-digit', minute: '2-digit' }),
    pickup_lat: parseFloat(r.pickup_lat),
    pickup_lng: parseFloat(r.pickup_lng),
    dropoff_lat: parseFloat(r.dropoff_lat),
    dropoff_lng: parseFloat(r.dropoff_lng),
    passenger_name: r.passenger_name || "عميل",
  });

  const fetchLiveTrackingData = async () => {
    const token = localStorage.getItem("evo_admin_token");
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/rides/live`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const data = await res.json();
        if (data.drivers) {
          setDrivers(data.drivers);
        }
        if (data.rides) {
          setRides(data.rides.map(mapBackendRide));
        }
        setLastUpdate(new Date());
        setPulseCount(c => c + 1);
      }
    } catch (err) {
      console.error("Failed to fetch live tracking data:", err);
    }
  };

  const fetchStations = async () => {
    const token = localStorage.getItem("evo_admin_token");
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/charging-stations`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const data = await res.json();
        if (data.stations) {
          setStations(data.stations.map((s: any) => ({
            id: s.id.toString(),
            name: s.name,
            nameAr: s.name_ar || s.name,
            lat: parseFloat(s.lat),
            lng: parseFloat(s.lng),
            address: s.address || "",
            totalChargers: parseInt(s.total_chargers) || 0,
            availableChargers: parseInt(s.available_chargers) || parseInt(s.total_chargers) || 0,
            operator: s.operator || "",
            source: s.source || "manual",
          })));
        }
      }
    } catch (err) {
      console.error("Failed to fetch stations:", err);
    }
  };

  // Initial and interval fetch
  useEffect(() => {
    fetchLiveTrackingData();
    fetchStations();

    const interval = setInterval(() => {
      fetchLiveTrackingData();
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  const filtered = filter === "all" ? drivers : drivers.filter(d => d.status === filter);

  const stats = {
    total: drivers.length,
    online: drivers.filter(d => d.status === "online").length,
    inRide: drivers.filter(d => d.status === "in_ride").length,
    arriving: drivers.filter(d => d.status === "arriving").length,
  };

  return (
    <div className="flex flex-col gap-6 h-full font-alexandria text-right" dir="rtl">
      {/* HEADER */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">التتبع المباشر</h1>
          <p className="text-sm text-gray-400 mt-1 flex items-center gap-2">
            <span className={`inline-block w-2 h-2 rounded-full bg-emerald-400 ${pulseCount % 2 === 0 ? "animate-pulse" : ""}`} />
            آخر تحديث: {lastUpdate.toLocaleTimeString("ar-JO-u-nu-latn")} — يتجدد كل 5 ثوانٍ
          </p>
        </div>
        <div className="flex gap-2">
          <button 
            onClick={fetchLiveTrackingData} 
            className="bg-[var(--color-brand-500)] text-white px-4 py-2 rounded-xl text-sm font-bold shadow-[0_0_15px_rgba(0,200,83,0.3)] hover:bg-[var(--color-brand-600)] transition-colors"
          >
            🔄 تحديث فوري
          </button>
        </div>
      </div>

      {/* STATS ROW */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: "إجمالي الكباتن", value: stats.total, color: "text-white", bg: "border-white/10" },
          { label: "متاح للرحلات", value: stats.online, color: "text-emerald-400", bg: "border-emerald-500/30" },
          { label: "في رحلة", value: stats.inRide, color: "text-blue-400", bg: "border-blue-500/30" },
          { label: "في الطريق", value: stats.arriving, color: "text-amber-400", bg: "border-amber-500/30" },
        ].map((s, i) => (
          <div key={i} className={`bg-[var(--color-card)] rounded-2xl p-4 border ${s.bg}`}>
            <p className="text-xs text-gray-400 font-bold mb-2">{s.label}</p>
            <p className={`text-3xl font-bold ${s.color}`}>{s.value}</p>
          </div>
        ))}
      </div>

      {/* MAIN CONTENT: MAP + SIDEBAR */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 flex-1" style={{ minHeight: "500px" }}>
        
        {/* MAP PANEL */}
        <div className="lg:col-span-2 bg-[var(--color-card)] rounded-3xl border border-white/5 overflow-hidden relative">
          <div className="absolute top-4 right-4 z-30 flex gap-2">
            {(["all", "online", "in_ride", "arriving"] as const).map(f => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-3 py-1.5 rounded-full text-xs font-bold border transition-all ${
                  filter === f
                    ? "bg-[var(--color-brand-500)] text-white border-transparent shadow-[0_0_10px_rgba(0,200,83,0.4)]"
                    : "bg-black/40 text-gray-400 border-white/10 hover:bg-white/10 backdrop-blur-sm"
                }`}
              >
                {f === "all" ? "الكل" : f === "online" ? "متاح" : f === "in_ride" ? "في رحلة" : "في الطريق"}
              </button>
            ))}
          </div>

          <MapLive 
            drivers={filtered} 
            stations={stations} 
            rides={rides.map(r => ({
              id: r.id,
              status: r.status,
              car_type: r.carType,
              pickup_lat: r.pickup_lat || 0,
              pickup_lng: r.pickup_lng || 0,
              dropoff_lat: r.dropoff_lat || 0,
              dropoff_lng: r.dropoff_lng || 0,
              pickup_address: r.pickupAddress,
              dropoff_address: r.dropoffAddress,
              total_fare: r.totalFare,
              passenger_name: r.passengerName,
            }))} 
            selectedDriver={selectedDriver}
            onSelectDriver={setSelectedDriver}
          />
        </div>

        {/* DRIVERS SIDEBAR */}
        <div className="bg-[var(--color-card)] rounded-3xl border border-white/5 flex flex-col overflow-hidden">
          <div className="p-4 border-b border-white/5">
            <h3 className="font-bold text-white text-sm">الكباتن المتصلون ({filtered.length})</h3>
          </div>
          <div className="flex-1 overflow-y-auto p-3 space-y-2 custom-scrollbar">
            {filtered.map(driver => {
              const cfg = STATUS_CONFIG[driver.status];
              return (
                <button
                  key={driver.id}
                  onClick={() => setSelectedDriver(driver === selectedDriver ? null : driver)}
                  className={`w-full text-right p-3 rounded-2xl border transition-all ${
                    selectedDriver?.id === driver.id
                      ? "border-[var(--color-brand-500)]/50 bg-[var(--color-brand-500)]/10"
                      : "border-white/5 hover:bg-white/5"
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <div className="relative">
                      <div className="w-9 h-9 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-base">
                        {getCarIcon(driver.carType)}
                      </div>
                      <span className={`absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2 border-[var(--color-card)] ${cfg.dot}`} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between gap-1">
                        <p className="text-sm font-bold text-white truncate">{driver.name}</p>
                        <span className={`text-xs font-bold shrink-0 ${cfg.color}`}>{cfg.label}</span>
                      </div>
                      <p className="text-xs text-gray-500 truncate">{driver.carPlate} | {CAR_TYPE_LABELS[driver.carType]}</p>
                      <div className="flex items-center justify-between mt-1">
                        <span className="text-xs font-bold text-emerald-400">
                          💰 {driver.walletBalance.toFixed(2)} د.أ
                        </span>
                        <span className="text-xs text-gray-600">{driver.lastSeen}</span>
                      </div>
                    </div>
                  </div>
                </button>
              );
            })}
            {filtered.length === 0 && (
              <div className="text-center py-10 text-gray-500">
                <p className="text-3xl mb-2">🚗</p>
                <p className="text-sm">لا يوجد كباتن في هذه الفئة</p>
              </div>
            )}
          </div>

          {/* Active Rides */}
          <div className="border-t border-white/5 p-4">
            <h3 className="font-bold text-white text-sm mb-3">الرحلات النشطة ({rides.length})</h3>
            <div className="space-y-2 max-h-[160px] overflow-y-auto custom-scrollbar">
              {rides.map(ride => (
                <div key={ride.id} className="bg-[#0B0F19] rounded-xl p-3 border border-white/5">
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-xs font-bold text-[var(--color-brand-500)]">{ride.driverName}</span>
                    <span className="text-xs font-bold text-emerald-400">{ride.totalFare.toFixed(2)} د.أ</span>
                  </div>
                  <p className="text-xs text-gray-400 truncate">🔴 {ride.pickupAddress}</p>
                  <p className="text-xs text-gray-400 truncate">🟢 {ride.dropoffAddress}</p>
                  <p className="text-xs text-gray-600 mt-1">الراكب: {ride.passengerName} | {ride.startedAt}</p>
                </div>
              ))}
              {rides.length === 0 && (
                <p className="text-xs text-gray-500 text-center py-4">لا توجد رحلات نشطة حالياً</p>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

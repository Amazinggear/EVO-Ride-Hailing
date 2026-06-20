"use client";

import { useEffect, useState, useCallback } from "react";
import { useSearchParams } from "next/navigation";

interface DriverWallet {
  user_id: string;
  full_name: string;
  phone: string;
  car_plate: string;
  car_type: string;
  car_model: string;
  cliq_alias: string;
  wallet_balance: number;
  total_commission_paid: number;
  total_rides: number;
  approval_status: string;
}

const CAR_TYPE_LABELS: Record<string, string> = {
  ev_mini: "EV MINI", ev_taxi: "EV TAXI", ev_sedan: "EV SEDAN",
  ev_suv: "EV SUV", ev_luxury: "EV Luxury",
};

import { Suspense } from "react";

export default function WalletsPage() {
  return (
    <Suspense fallback={<div className="p-8 text-center text-white">Loading...</div>}>
      <WalletsContent />
    </Suspense>
  );
}

function WalletsContent() {
  const searchParams = useSearchParams();
  const filterParam = searchParams.get("filter");
  const driverParam = searchParams.get("driver");

  const [wallets, setWallets] = useState<DriverWallet[]>([]);
  const [filtered, setFiltered] = useState<DriverWallet[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [showLowOnly, setShowLowOnly] = useState(filterParam === "low");
  const [selectedDriver, setSelectedDriver] = useState<DriverWallet | null>(null);
  const [rechargeAmount, setRechargeAmount] = useState("");
  const [rechargeNote, setRechargeNote] = useState("");
  const [recharging, setRecharging] = useState(false);
  const [success, setSuccess] = useState("");
  const [error, setError] = useState("");

  const getToken = () => localStorage.getItem("evo_admin_token") || "";

  const fetchWallets = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (showLowOnly) params.set("lowBalance", "true");
      const res = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/wallet/balances?${params}`,
        { headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${getToken()}` } }
      );
      const data = await res.json();
      if (!data.drivers) throw new Error();
      const mapped = data.drivers.map((d: any) => ({
        user_id: d.id,
        full_name: d.name,
        phone: d.phone,
        car_plate: d.carPlate,
        car_type: d.carType,
        car_model: d.carModel,
        cliq_alias: d.cliqAlias || 'N/A',
        wallet_balance: parseFloat(d.walletBalance) || 0,
        total_commission_paid: parseFloat(d.totalCommissionPaid) || 0,
        total_rides: parseInt(d.totalRides) || 0,
        approval_status: 'approved'
      }));
      setWallets(mapped);
    } catch {
      // Mock
      const mock: DriverWallet[] = [
        { user_id: "1", full_name: "أحمد الخالدي", phone: "+962791234567", car_plate: "87-12345",
          car_type: "ev_sedan", car_model: "Tesla Model 3", cliq_alias: "0791234567",
          wallet_balance: 18.50, total_commission_paid: 45.20, total_rides: 142, approval_status: "approved" },
        { user_id: "2", full_name: "سامر النعيمي", phone: "+962790987654", car_plate: "23-45678",
          car_type: "ev_suv", car_model: "BYD Atto 3", cliq_alias: "0790987654",
          wallet_balance: 2.10, total_commission_paid: 120.80, total_rides: 387, approval_status: "approved" },
        { user_id: "3", full_name: "ياسر المطيري", phone: "+962795555111", car_plate: "11-11111",
          car_type: "ev_mini", car_model: "Nissan Leaf", cliq_alias: "0795555111",
          wallet_balance: 1.20, total_commission_paid: 28.30, total_rides: 89, approval_status: "approved" },
        { user_id: "4", full_name: "عمر الشرع", phone: "+962796000222", car_plate: "55-23456",
          car_type: "ev_taxi", car_model: "BYD e6", cliq_alias: "0796000222",
          wallet_balance: 32.00, total_commission_paid: 88.60, total_rides: 278, approval_status: "approved" },
      ];
      setWallets(mock);
    } finally {
      setLoading(false);
    }
  }, [showLowOnly]);

  useEffect(() => { fetchWallets(); }, [fetchWallets]);

  // Auto-select driver if coming from drivers page
  useEffect(() => {
    if (driverParam && wallets.length > 0) {
      const found = wallets.find(w => w.user_id === driverParam);
      if (found) setSelectedDriver(found);
    }
  }, [driverParam, wallets]);

  useEffect(() => {
    let list = wallets;
    if (showLowOnly) list = list.filter(d => d.wallet_balance < 3.0);
    if (search) {
      const q = search.toLowerCase();
      list = list.filter(d =>
        d.full_name.includes(q) ||
        d.car_plate.toLowerCase().includes(q) ||
        d.phone.includes(q) ||
        d.cliq_alias.includes(q)
      );
    }
    setFiltered(list);
  }, [wallets, showLowOnly, search]);

  const handleRecharge = async () => {
    if (!selectedDriver || !rechargeAmount) return;
    const amount = parseFloat(rechargeAmount);
    if (isNaN(amount) || amount <= 0) { setError("أدخل مبلغاً صحيحاً"); return; }

    setRecharging(true);
    setError("");
    setSuccess("");

    try {
      const res = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/wallet/recharge`,
        {
          method: "POST",
          headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${getToken()}`, "Content-Type": "application/json" },
          body: JSON.stringify({
            carPlate: selectedDriver.car_plate,
            amount,
            note: rechargeNote || `شحن من الإدارة — ${new Date().toLocaleDateString("ar-JO-u-nu-latn")}`,
          }),
        }
      );
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "فشل الشحن");

      setSuccess(`✅ تم شحن ${amount} د.أ لمحفظة ${selectedDriver.full_name} بنجاح! الرصيد الجديد: ${data.newBalance} د.أ`);
      setRechargeAmount("");
      setRechargeNote("");
      await fetchWallets();
      // Update selected driver
      setSelectedDriver(prev => prev ? { ...prev, wallet_balance: data.newBalance } : null);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "فشل الشحن");
    } finally {
      setRecharging(false);
    }
  };

  const QUICK_AMOUNTS = [5, 10, 15, 20, 30, 50];

  return (
    <div className="flex flex-col lg:flex-row gap-6 animate-fade-in-up">
      {/* ═══ LEFT: Wallets List ═══ */}
      <div className="w-full lg:w-96 shrink-0 space-y-4">
        {/* Filters */}
        <div className="space-y-3 relative z-10">
          <div className="relative group">
            <input
              type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="بحث بالاسم، اللوحة، الهاتف..."
              className="w-full bg-[#0B0F19] border border-white/10 rounded-xl px-4 py-3.5 text-white placeholder-gray-500 focus:outline-none focus:border-[var(--color-brand-500)] text-sm font-bold shadow-lg transition-all focus:shadow-[0_0_15px_rgba(0,200,83,0.1)]"
            />
            <span className="absolute left-4 top-1/2 -translate-y-1/2 opacity-50 group-focus-within:opacity-100 transition-opacity">🔍</span>
          </div>
          <label className="flex items-center gap-3 cursor-pointer bg-[#0B0F19] p-2 rounded-xl">
            <div
              onClick={() => setShowLowOnly(!showLowOnly)}
              className={`w-12 h-6 rounded-full transition-colors relative shadow-inner ${showLowOnly ? "bg-red-500" : "bg-white/10"}`}
            >
              <div className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all shadow-sm ${showLowOnly ? "left-7" : "left-1"}`} />
            </div>
            <span className="text-sm text-gray-300 font-bold">رصيد منخفض فقط (أقل من 3 د.أ)</span>
          </label>
        </div>

        {/* Summary */}
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-[var(--color-card)] border border-white/5 shadow-lg rounded-2xl p-4 flex flex-col justify-between">
            <p className="text-xs text-gray-400 font-bold">إجمالي الكباتن</p>
            <p className="text-2xl font-cy-bold text-white mt-2">{wallets.length}</p>
          </div>
          <div className="bg-[var(--color-card)] border border-red-500/20 shadow-lg shadow-red-500/5 rounded-2xl p-4 flex flex-col justify-between">
            <p className="text-xs text-red-400 font-bold">رصيد منخفض</p>
            <p className="text-2xl font-cy-bold text-red-400 mt-2">
              {wallets.filter(d => d.wallet_balance < 3).length}
            </p>
          </div>
        </div>

        {/* Driver List */}
        {loading ? (
          <div className="flex items-center justify-center h-32">
            <div className="w-8 h-8 border-4 border-white/10 border-t-[var(--color-brand-500)] rounded-full animate-spin" />
          </div>
        ) : (
          <div className="space-y-3 overflow-y-auto max-h-[calc(100vh-350px)] pr-1">
            {filtered.map(driver => (
              <div
                key={driver.user_id}
                onClick={() => { setSelectedDriver(driver); setSuccess(""); setError(""); }}
                className={`bg-[var(--color-card)] border rounded-2xl p-5 cursor-pointer transition-all duration-300 hover:-translate-y-1 shadow-md hover:shadow-xl ${
                  selectedDriver?.user_id === driver.user_id
                    ? "border-[var(--color-brand-500)]/50 bg-[var(--color-brand-500)]/5 shadow-[0_0_15px_rgba(0,200,83,0.1)]"
                    : driver.wallet_balance < 3
                    ? "border-red-500/30 hover:border-red-500/50"
                    : "border-white/5 hover:border-white/20"
                }`}
              >
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-bold text-white text-sm mb-1">{driver.full_name}</p>
                    <p className="text-gray-400 text-xs font-cy-bold">{driver.car_plate} · {CAR_TYPE_LABELS[driver.car_type]}</p>
                  </div>
                  <div className="text-right">
                    <p className={`text-xl font-cy-bold ${driver.wallet_balance < 3 ? "text-red-400" : "text-[var(--color-brand-500)]"}`}>
                      {driver.wallet_balance.toFixed(2)}
                    </p>
                    <p className="text-gray-500 text-[10px] font-bold">د.أ</p>
                  </div>
                </div>
                {driver.wallet_balance < 3 && (
                  <div className="mt-3 bg-red-500/10 rounded-xl px-3 py-1.5 text-xs text-red-400 text-center font-bold">
                    ⚠️ رصيد منخفض — لن يستقبل طلبات
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* ═══ RIGHT: Recharge Panel ═══ */}
      <div className="flex-1 lg:h-[calc(100vh-140px)] lg:overflow-y-auto">
        {!selectedDriver ? (
          <div className="flex items-center justify-center h-64 lg:h-full text-gray-500 bg-[var(--color-card)] border border-white/5 rounded-3xl shadow-xl animate-pulse">
            <div className="text-center">
              <span className="text-6xl block mb-6 opacity-40">💰</span>
              <p className="font-bold text-lg text-gray-400">اختر كابتن لشحن محفظته</p>
            </div>
          </div>
        ) : (
          <div className="space-y-6 animate-fade-in-up delay-100">
            {/* Driver Header */}
            <div className="bg-[var(--color-card)] border border-[var(--color-brand-500)]/20 shadow-[0_0_30px_rgba(0,200,83,0.05)] rounded-3xl p-6 sm:p-8 relative overflow-hidden group">
              <div className="absolute top-0 right-0 w-48 h-48 bg-[var(--color-brand-500)] opacity-10 blur-[60px] rounded-full mix-blend-screen"></div>
              <div className="relative z-10 flex flex-col sm:flex-row sm:items-center justify-between gap-6">
                <div>
                  <h2 className="text-2xl font-black text-white mb-1">{selectedDriver.full_name}</h2>
                  <p className="text-gray-400 text-sm font-cy-bold">{selectedDriver.phone}</p>
                  <p className="text-gray-400 text-sm mt-1 font-cy-bold">
                    {selectedDriver.car_model} · <span className="text-white">{selectedDriver.car_plate}</span>
                  </p>
                  <p className="text-[var(--color-brand-500)] text-sm font-bold mt-2 bg-[var(--color-brand-500)]/10 inline-block px-3 py-1 rounded-full border border-[var(--color-brand-500)]/20">كليك: <span className="font-cy-bold">{selectedDriver.cliq_alias}</span></p>
                </div>
                <div className="text-right sm:text-left self-end sm:self-auto border-t sm:border-t-0 border-white/10 pt-4 sm:pt-0 w-full sm:w-auto">
                  <p className="text-gray-400 text-sm font-bold mb-1">الرصيد الحالي</p>
                  <div className="flex items-baseline sm:justify-end gap-1.5">
                    <p className={`text-5xl font-cy-bold tracking-tight ${selectedDriver.wallet_balance < 3 ? "text-red-400 drop-shadow-[0_0_10px_rgba(248,113,113,0.3)]" : "text-white drop-shadow-[0_0_10px_rgba(255,255,255,0.1)]"}`}>
                      {selectedDriver.wallet_balance.toFixed(2)}
                    </p>
                    <p className="text-gray-500 text-sm font-bold">د.أ</p>
                  </div>
                </div>
              </div>

              {/* Stats Row */}
              <div className="grid grid-cols-3 gap-3 mt-6 pt-6 border-t border-white/5">
                <div className="text-center">
                  <p className="text-xl font-cy-bold text-white">{selectedDriver.total_rides}</p>
                  <p className="text-xs text-gray-400 font-bold mt-1">رحلة مكتملة</p>
                </div>
                <div className="text-center border-r border-white/5 border-l">
                  <p className="text-xl font-cy-bold text-[var(--color-brand-500)]">{selectedDriver.total_commission_paid.toFixed(2)} <span className="text-sm">د.أ</span></p>
                  <p className="text-xs text-gray-400 font-bold mt-1">عمولة مدفوعة</p>
                </div>
                <div className="text-center">
                  <p className="text-lg font-cy-bold text-white">{CAR_TYPE_LABELS[selectedDriver.car_type]}</p>
                  <p className="text-xs text-gray-400 font-bold mt-1">نوع السيارة</p>
                </div>
              </div>
            </div>

            {/* Recharge Form */}
            <div className="bg-[var(--color-card)] border border-white/5 shadow-xl rounded-3xl p-8 space-y-6">
              <h3 className="font-bold text-white text-xl">⚡ شحن المحفظة</h3>

              {/* Low balance warning */}
              {selectedDriver.wallet_balance < 3 && (
                <div className="bg-red-500/10 border border-red-500/30 rounded-xl px-4 py-3 text-red-400 text-sm font-bold flex items-center gap-2">
                  <span>⚠️</span> هذا الكابتن لا يستقبل طلبات حالياً — رصيده أقل من 3 د.أ
                </div>
              )}

              {/* Quick amounts */}
              <div>
                <label className="block text-sm text-gray-400 mb-3 font-bold">مبالغ سريعة (د.أ)</label>
                <div className="flex flex-wrap gap-3">
                  {QUICK_AMOUNTS.map(amt => (
                    <button
                      key={amt}
                      onClick={() => setRechargeAmount(String(amt))}
                      className={`px-5 py-3 rounded-xl text-lg font-cy-bold transition-all border ${
                        rechargeAmount === String(amt)
                          ? "bg-[var(--color-brand-500)] text-[#0B0F19] border-transparent shadow-[0_0_15px_rgba(0,200,83,0.4)]"
                          : "bg-[#0B0F19] text-gray-300 border-white/5 hover:border-[var(--color-brand-500)]/40 hover:bg-white/5"
                      }`}
                    >
                      {amt}
                    </button>
                  ))}
                </div>
              </div>

              {/* Custom amount */}
              <div>
                <label className="block text-sm text-gray-400 mb-2 font-bold">مبلغ مخصص (د.أ)</label>
                <div className="relative group">
                  <input
                    type="number"
                    value={rechargeAmount}
                    onChange={e => setRechargeAmount(e.target.value)}
                    min="1"
                    step="0.5"
                    placeholder="0.00"
                    className="w-full bg-[#0B0F19] border border-white/10 rounded-xl pl-12 pr-5 py-4 text-white placeholder-gray-600 focus:outline-none focus:border-[var(--color-brand-500)] text-3xl font-cy-bold transition-all focus:shadow-[0_0_15px_rgba(0,200,83,0.1)] text-left"
                    dir="ltr"
                  />
                  <span className="absolute left-5 top-1/2 -translate-y-1/2 text-gray-500 text-lg font-bold pointer-events-none group-focus-within:text-[var(--color-brand-500)] transition-colors opacity-80">د.أ</span>
                </div>
              </div>

              {/* Note */}
              <div>
                <label className="block text-sm text-gray-400 mb-2 font-bold">ملاحظة (اختياري)</label>
                <input
                  type="text"
                  value={rechargeNote}
                  onChange={e => setRechargeNote(e.target.value)}
                  placeholder="مثال: استلمنا التحويل من الكابتن"
                  className="w-full bg-[#0B0F19] border border-white/10 rounded-xl px-5 py-4 text-white placeholder-gray-600 focus:outline-none focus:border-[var(--color-brand-500)] text-sm font-bold transition-colors"
                />
              </div>

              {/* Alerts */}
              {success && (
                <div className="bg-[var(--color-brand-500)]/10 border border-[var(--color-brand-500)]/30 rounded-xl px-5 py-4 text-[var(--color-brand-500)] text-sm font-bold">
                  {success}
                </div>
              )}
              {error && (
                <div className="bg-red-500/10 border border-red-500/30 rounded-xl px-5 py-4 text-red-400 text-sm font-bold flex items-center gap-2">
                  <span>⚠️</span> {error}
                </div>
              )}

              {/* Submit */}
              <button
                onClick={handleRecharge}
                disabled={recharging || !rechargeAmount}
                className="w-full bg-[var(--color-brand-500)] hover:bg-[var(--color-brand-600)] disabled:opacity-40 text-[#0B0F19] font-black py-4 rounded-xl text-xl transition-all shadow-[0_0_20px_rgba(0,200,83,0.2)] active:scale-95"
              >
                {recharging
                  ? "جاري الشحن..."
                  : `شحن ${rechargeAmount ? parseFloat(rechargeAmount).toFixed(2) : "0.00"} د.أ ⚡`}
              </button>

              <p className="text-xs text-gray-500 text-center font-bold">
                الكابتن سيتلقى إشعار فوري عند شحن محفظته
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}


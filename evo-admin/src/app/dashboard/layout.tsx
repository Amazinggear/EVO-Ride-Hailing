"use client";

import { useState, useEffect } from "react";
import { useRouter, usePathname } from "next/navigation";
import Link from "next/link";
import EvoLogo from "@/components/EvoLogo";

const ALL_MENU_ITEMS = [
  { href: "/dashboard", icon: "📊", label: "الرئيسية", roles: ["super_admin", "operations", "finance", "support"] },
  { href: "/dashboard/live", icon: "🗺️", label: "التتبع المباشر", roles: ["super_admin", "operations"] },
  { href: "/dashboard/customers", icon: "👥", label: "العملاء", roles: ["super_admin", "operations", "support"] },
  { href: "/dashboard/drivers", icon: "🚗", label: "الكباتن", roles: ["super_admin", "operations"] },
  { href: "/dashboard/drivers/pending", icon: "⏳", label: "الاعتمادات", roles: ["super_admin", "operations"] },
  { href: "/dashboard/rides", icon: "📍", label: "الرحلات", roles: ["super_admin", "operations"] },
];

const ALL_GENERAL_ITEMS = [
  { href: "/dashboard/complaints", icon: "🚨", label: "الشكاوى", roles: ["super_admin", "support"] },
  { href: "/dashboard/notifications", icon: "📢", label: "الإشعارات", roles: ["super_admin", "support"] },
  { href: "/dashboard/wallets", icon: "💰", label: "المحافظ", roles: ["super_admin", "finance"] },
  { href: "/dashboard/promos", icon: "🎟️", label: "الخصومات", roles: ["super_admin", "finance"] },
  { href: "/dashboard/pricing", icon: "⚙️", label: "الأسعار", roles: ["super_admin", "finance"] },
  { href: "/dashboard/stations", icon: "⚡", label: "محطات الشحن", roles: ["super_admin", "operations"] },
  { href: "/dashboard/financials", icon: "📈", label: "التقارير المالية", roles: ["super_admin", "finance"] },
  { href: "/dashboard/audit", icon: "🔍", label: "سجل التدقيق", roles: ["super_admin", "support"] },
  { href: "/dashboard/admins", icon: "🛡️", label: "الصلاحيات", roles: ["super_admin"] },
  { href: "/dashboard/system-logs", icon: "📋", label: "سجل النظام", roles: ["super_admin"] },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [isDesktop, setIsDesktop] = useState(true);

  const [isProfileDropdownOpen, setIsProfileDropdownOpen] = useState(false);
  const [isProfileModalOpen, setIsProfileModalOpen] = useState(false);

  const [profile, setProfile] = useState({
    id: "",
    fullName: "",
    email: "",
    avatarUrl: "",
    role: "admin",
    adminRole: "",
    createdAt: "",
  });

  const [editName, setEditName] = useState("");
  const [editEmail, setEditEmail] = useState("");
  const [editAvatar, setEditAvatar] = useState("");
  const [isEditingProfile, setIsEditingProfile] = useState(false);
  const [profileSaveError, setProfileSaveError] = useState("");

  const fetchProfile = async () => {
    const token = localStorage.getItem("evo_admin_token");
    if (!token) {
      router.push("/login");
      return;
    }
    // Retry helper — handle Render cold start
    const fetchWithRetry = async (url: string, options: RequestInit, retries = 3): Promise<Response> => {
      for (let i = 0; i < retries; i++) {
        try {
          const controller = new AbortController();
          const timeout = setTimeout(() => controller.abort(), 15000);
          const res = await fetch(url, { ...options, signal: controller.signal });
          clearTimeout(timeout);
          if (res.ok || i === retries - 1) return res;
          // Wait longer each retry
          await new Promise(r => setTimeout(r, 2000 * (i + 1)));
        } catch (err) {
          if (i === retries - 1) throw err;
          await new Promise(r => setTimeout(r, 2000 * (i + 1)));
        }
      }
      throw new Error('Failed after retries');
    };

    try {
      const res = await fetchWithRetry(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/auth/me`, {
        headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const data = await res.json();
        setProfile({
          id: data.id || "",
          fullName: data.fullName || "",
          email: data.email || "",
          avatarUrl: data.avatarUrl || "",
          role: data.role || "admin",
          adminRole: data.adminRole || "",
          createdAt: data.createdAt || "",
        });
      }
    } catch (err) {
      console.error("Failed to load profile after retries", err);
      // Don't redirect — keep user on page, let them retry
    }
  };

  useEffect(() => {
    fetchProfile();
  }, []);

  // Route protection: redirect if role doesn't have access to current page
  useEffect(() => {
    if (!profile.adminRole) return;
    const allItems = [...ALL_MENU_ITEMS, ...ALL_GENERAL_ITEMS];
    const currentItem = allItems.find(item => pathname === item.href || pathname?.startsWith(item.href + '/'));
    if (currentItem && !currentItem.roles.includes(profile.adminRole)) {
      router.push("/dashboard");
    }
  }, [profile.adminRole, pathname]);

  // Activity ping — track admin page visits for working hours
  useEffect(() => {
    const token = localStorage.getItem("evo_admin_token");
    if (!token || !pathname) return;
    const ping = () => {
      fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/activity/ping`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
        body: JSON.stringify({ page: pathname }),
      }).catch(() => {});
    };
    ping(); // initial ping
    const interval = setInterval(ping, 60000); // every 1 minute
    return () => clearInterval(interval);
  }, [pathname]);

  useEffect(() => {
    if (isProfileModalOpen) {
      setEditName(profile.fullName);
      setEditEmail(profile.email);
      setEditAvatar(profile.avatarUrl || "");
      setIsEditingProfile(false);
      setProfileSaveError("");
    }
  }, [isProfileModalOpen, profile]);

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setProfileSaveError("");
    const token = localStorage.getItem("evo_admin_token");
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/auth/profile`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Bypass-Tunnel-Reminder": "true",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          fullName: editName,
          email: editEmail,
          avatarUrl: editAvatar,
        }),
      });
      if (res.ok) {
        const data = await res.json();
        if (data.user) {
          setProfile(prev => ({
            ...prev,
            fullName: data.user.fullName,
            email: data.user.email,
            avatarUrl: data.user.avatarUrl,
          }));
          setIsEditingProfile(false);
        } else {
          setProfileSaveError("فشل تحديث البيانات");
        }
      } else {
        const d = await res.json();
        setProfileSaveError(d.error || "فشل تحديث البيانات");
      }
    } catch (err) {
      setProfileSaveError("حدث خطأ في الشبكة");
    }
  };

  useEffect(() => {
    const checkWidth = () => {
      const desktop = window.innerWidth >= 1024;
      setIsDesktop(desktop);
      if (desktop) setSidebarOpen(true);
      else setSidebarOpen(false);
    };
    checkWidth();
    window.addEventListener("resize", checkWidth);
    return () => window.removeEventListener("resize", checkWidth);
  }, []);

  const handleLogout = () => {
    localStorage.removeItem("evo_admin_token");
    router.push("/login");
  };

  const handleBackup = async () => {
    try {
      const token = localStorage.getItem("evo_admin_token") || "";
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/admin/backup/export`, {
        headers: { "Bypass-Tunnel-Reminder": "true", Authorization: `Bearer ${token}` }
      });
      if (res.ok) {
        const blob = await res.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `evo_backup_${new Date().toISOString().split('T')[0]}.json`;
        a.click();
      } else {
        alert("فشل تحميل النسخة الاحتياطية. قد لا تملك الصلاحية (Super Admin).");
      }
    } catch (err) {
      alert("حدث خطأ أثناء طلب النسخة الاحتياطية.");
    }
  };

  const NavItem = ({ href, icon, label }: { href: string; icon: string; label: string }) => {
    const isActive = pathname === href || (href !== "/dashboard" && href !== "/dashboard/drivers" && pathname.startsWith(href + '/'));
    return (
      <Link
        href={href}
        className={`flex items-center gap-3 px-4 py-3 mx-4 rounded-xl transition-all duration-200 font-medium ${
          isActive 
            ? "bg-[var(--color-brand-500)] text-[#0B0F19] shadow-[0_0_15px_rgba(0,200,83,0.3)]" 
            : "text-gray-400 hover:bg-white/5 hover:text-white"
        }`}
      >
        <span className="text-xl">{icon}</span>
        <span className="font-bold text-sm tracking-wide">{label}</span>
      </Link>
    );
  };

  return (
    <div className="flex h-screen bg-background overflow-hidden font-alexandria text-foreground">
      {/* Mobile Overlay */}
      {!isDesktop && sidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/80 backdrop-blur-sm z-40 transition-opacity"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* ═══ SIDEBAR ═══ */}
      <aside
        className={`
          ${isDesktop ? (sidebarOpen ? "w-[280px]" : "w-[280px]") : "fixed inset-y-0 right-0 w-[280px] z-50"}
          ${!isDesktop && !sidebarOpen ? "translate-x-full" : "translate-x-0"}
          transition-all duration-300 ease-in-out bg-[var(--color-card)] border-l border-white/5 flex flex-col shadow-2xl
        `}
      >
        {/* Logo */}
        <div className="h-24 flex items-center px-8 border-b border-white/5 relative overflow-hidden group">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_left,_var(--tw-gradient-stops))] from-[var(--color-brand-500)]/5 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
          <div className="flex items-center gap-3 relative z-10" dir="ltr">
            <EvoLogo className="h-14 drop-shadow-[0_0_8px_rgba(0,200,83,0.6)]" />
            <span className="text-2xl font-cy-bold tracking-[0.2em] text-white/90 mt-2 font-bold" style={{ textShadow: "0 0 10px rgba(255,255,255,0.1)" }}>ADMIN</span>
          </div>
        </div>

        {/* Nav Sections */}
        <div className="flex-1 overflow-y-auto py-4 custom-scrollbar flex flex-col gap-6">
          
          {/* MENU */}
          <div>
            <div className="px-8 mb-3 text-xs font-bold text-gray-500 uppercase tracking-wider">القائمة الأساسية</div>
            <nav className="flex flex-col gap-1">
              {ALL_MENU_ITEMS.filter(item => item.roles.includes(profile.adminRole || 'support')).map((item) => (
                <NavItem key={item.href} {...item} />
              ))}
            </nav>
          </div>

          {/* GENERAL */}
          <div>
            <div className="px-8 mb-3 text-xs font-bold text-gray-500 uppercase tracking-wider">عام</div>
            <nav className="flex flex-col gap-1">
              {ALL_GENERAL_ITEMS.filter(item => item.roles.includes(profile.adminRole || 'support')).map((item) => (
                <NavItem key={item.href} {...item} />
              ))}
            </nav>
          </div>

        </div>

        {/* Profile Card */}
        <div className="p-6">
          <div className="bg-[var(--color-brand-900)] rounded-2xl p-5 text-white shadow-lg border border-[var(--color-brand-500)]/30 relative overflow-hidden group hover:border-[var(--color-brand-500)] transition-colors">
            <div className="absolute inset-0 opacity-20 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-[var(--color-brand-500)] via-transparent to-transparent"></div>
            <div className="relative z-10">
              <p className="text-xs text-brand-200 mb-1">المركز الرئيسي</p>
              <h4 className="font-bold text-lg leading-tight">{profile.fullName || "Admin"}</h4>
              <p className="text-sm text-brand-300 mt-1 mb-4 font-cy-bold">{profile.adminRole === 'super_admin' ? 'Super Admin' : profile.adminRole || 'Admin'}</p>
              <div className="flex flex-col gap-2">
                <button onClick={handleBackup} className="bg-[var(--color-brand-500)]/20 text-[var(--color-brand-500)] hover:bg-[var(--color-brand-500)] hover:text-[#0B0F19] transition-colors rounded-lg py-2 px-4 text-xs font-bold w-full text-center flex items-center justify-center gap-2">
                  💾 نسخة احتياطية
                </button>
                <button onClick={handleLogout} className="bg-white/10 hover:bg-red-500 transition-colors rounded-lg py-2 px-4 text-xs font-bold w-full text-center flex items-center justify-center gap-2">
                  تسجيل الخروج <span className="rotate-180">➜</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </aside>

      {/* ═══ MAIN CONTENT ═══ */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden bg-background">
        {/* TOPBAR */}
        <header className="h-24 bg-background flex items-center justify-between px-8 z-10 shrink-0 border-b border-white/5">
          {!isDesktop && (
            <button onClick={() => setSidebarOpen(true)} className="p-2 text-gray-400 hover:text-white">
              ☰
            </button>
          )}
          
          <div className="flex-1 max-w-md hidden md:flex items-center relative mr-auto ml-8">
            {/* Search removed as per strict requirement to not have non-functional placeholders */}
          </div>

          <div className="flex items-center gap-4 relative">
            {/* Notification and Message icons removed as per strict requirement */}
            <button 
              onClick={() => setIsProfileDropdownOpen(!isProfileDropdownOpen)}
              className="flex items-center gap-3 mr-4 pr-4 border-r border-white/10 cursor-pointer hover:bg-white/5 px-4 py-2 rounded-2xl transition-all duration-300 border border-transparent hover:border-white/5 active:scale-95 focus:outline-none focus:ring-2 focus:ring-[var(--color-brand-500)]/30"
              aria-expanded={isProfileDropdownOpen}
              aria-haspopup="true"
            >
              <div className="w-10 h-10 rounded-full bg-[var(--color-brand-900)] border-2 border-[var(--color-brand-500)] overflow-hidden shrink-0 shadow-[0_0_10px_rgba(0,200,83,0.3)]">
                <img src={profile.avatarUrl || `https://ui-avatars.com/api/?name=${encodeURIComponent(profile.fullName)}&background=004219&color=00C853`} alt="Admin" className="w-full h-full object-cover" />
              </div>
              <div className="hidden sm:block text-right">
                <p className="text-sm font-bold text-white leading-tight">{profile.fullName}</p>
                <p className="text-xs text-brand-400 font-cy-bold mt-0.5">{profile.email}</p>
              </div>
              <span className="text-gray-500 text-xs transition-transform duration-300 ml-1">▼</span>
            </button>

            {/* Profile Dropdown Menu */}
            {isProfileDropdownOpen && (
              <>
                <div className="fixed inset-0 z-40" onClick={() => setIsProfileDropdownOpen(false)} />
                <div 
                  dir="rtl"
                  className="absolute left-4 top-16 w-64 bg-[#0B0F19]/90 backdrop-blur-xl border border-white/10 rounded-2xl p-4 shadow-[0_20px_50px_rgba(0,0,0,0.5),_0_0_30px_rgba(0,200,83,0.05)] z-50 animate-fade-in-up text-right"
                >
                  <div className="flex items-center gap-3 pb-3 border-b border-white/5 mb-3">
                    <div className="w-10 h-10 rounded-full bg-[var(--color-brand-900)] border border-[var(--color-brand-500)] overflow-hidden shrink-0">
                      <img src={profile.avatarUrl || `https://ui-avatars.com/api/?name=${encodeURIComponent(profile.fullName)}&background=004219&color=00C853`} alt="Admin" className="w-full h-full object-cover" />
                    </div>
                    <div>
                      <p className="text-sm font-bold text-white leading-tight">{profile.fullName}</p>
                      <span className="text-[10px] bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] border border-[var(--color-brand-500)]/20 px-2 py-0.5 rounded-full font-bold mt-1 inline-block">{profile.adminRole === 'super_admin' ? 'Super Admin' : 'Admin'}</span>
                    </div>
                  </div>
                  <div className="flex flex-col gap-1">
                    <button 
                      onClick={() => { setIsProfileModalOpen(true); setIsProfileDropdownOpen(false); }} 
                      className="w-full text-right px-3 py-2 rounded-xl hover:bg-white/5 text-gray-300 hover:text-white transition-colors text-sm font-bold flex items-center justify-between"
                    >
                      <span className="flex items-center gap-2">👤 الملف الشخصي</span>
                      <span className="text-xs text-gray-500 font-cy-bold">عرض</span>
                    </button>

                    <button 
                      onClick={() => { handleBackup(); setIsProfileDropdownOpen(false); }} 
                      className="w-full text-right px-3 py-2 rounded-xl hover:bg-white/5 text-gray-300 hover:text-white transition-colors text-sm font-bold flex items-center justify-between"
                    >
                      <span className="flex items-center gap-2">💾 نسخة احتياطية</span>
                      <span className="text-xs text-gray-500 font-cy-bold">تحميل</span>
                    </button>
                    <div className="border-t border-white/5 my-2" />
                    <button 
                      onClick={() => { handleLogout(); setIsProfileDropdownOpen(false); }} 
                      className="w-full text-right px-3 py-2 rounded-xl hover:bg-red-500/10 text-red-400 hover:text-red-300 transition-colors text-sm font-bold flex items-center justify-between"
                    >
                      <span className="flex items-center gap-2">🚪 تسجيل الخروج</span>
                      <span className="rotate-180">➜</span>
                    </button>
                  </div>
                </div>
              </>
            )}
          </div>
        </header>

        {/* PROFILE MODAL */}
        {isProfileModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4" onClick={() => setIsProfileModalOpen(false)}>
            <div className="bg-[var(--color-card)] border border-white/10 rounded-3xl w-full max-w-md p-6 space-y-5 shadow-2xl relative" onClick={e => e.stopPropagation()} dir="rtl">
              <div className="flex items-center justify-between border-b border-white/5 pb-4">
                <h2 className="text-lg font-black text-white flex items-center gap-2">👤 الملف الشخصي للـ Admin</h2>
                <button onClick={() => setIsProfileModalOpen(false)} className="text-gray-500 hover:text-white transition-colors text-2xl leading-none">×</button>
              </div>

              {isEditingProfile ? (
                <form onSubmit={handleSaveProfile} className="space-y-4">
                  {profileSaveError && (
                    <div className="bg-red-500/10 border border-red-500/30 rounded-xl px-4 py-3 text-red-400 text-sm font-bold">{profileSaveError}</div>
                  )}
                  <div>
                    <label className="text-xs text-gray-400 block mb-1.5 font-bold">الاسم الكامل*</label>
                    <input 
                      required 
                      type="text"
                      value={editName} 
                      onChange={e => setEditName(e.target.value)} 
                      className="w-full bg-[#0B0F19] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white outline-none focus:border-[var(--color-brand-500)]" 
                    />
                  </div>
                  <div>
                    <label className="text-xs text-gray-400 block mb-1.5 font-bold">البريد الإلكتروني*</label>
                    <input 
                      required 
                      type="email"
                      value={editEmail} 
                      onChange={e => setEditEmail(e.target.value)} 
                      className="w-full bg-[#0B0F19] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white outline-none focus:border-[var(--color-brand-500)]" 
                    />
                  </div>
                  <div>
                    <label className="text-xs text-gray-400 block mb-1.5 font-bold">رابط الصورة الشخصية (Avatar URL)</label>
                    <input 
                      type="text"
                      value={editAvatar} 
                      onChange={e => setEditAvatar(e.target.value)} 
                      placeholder="https://example.com/avatar.jpg"
                      className="w-full bg-[#0B0F19] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white outline-none focus:border-[var(--color-brand-500)]" 
                      dir="ltr"
                    />
                  </div>
                  <div className="flex gap-3 pt-2">
                    <button type="submit" className="flex-1 bg-[var(--color-brand-500)] text-[#0B0F19] font-bold py-3 rounded-xl hover:bg-[var(--color-brand-600)] transition-colors text-sm shadow-lg">حفظ</button>
                    <button type="button" onClick={() => setIsEditingProfile(false)} className="flex-1 border border-white/10 text-gray-400 font-bold py-3 rounded-xl hover:bg-white/5 transition-colors text-sm">إلغاء</button>
                  </div>
                </form>
              ) : (
                <>
                  <div className="flex flex-col items-center gap-3 py-4">
                    <div className="w-20 h-20 rounded-full bg-[var(--color-brand-900)] border-4 border-[var(--color-brand-500)] overflow-hidden shadow-lg">
                      <img src={profile.avatarUrl || `https://ui-avatars.com/api/?name=${encodeURIComponent(profile.fullName)}&background=004219&color=00C853`} alt="Admin" className="w-full h-full object-cover" />
                    </div>
                    <h3 className="text-xl font-bold text-white">{profile.fullName}</h3>
                    <span className="px-3 py-1 rounded-full bg-[var(--color-brand-500)]/10 text-[var(--color-brand-500)] border border-[var(--color-brand-500)]/20 text-xs font-bold">{profile.adminRole === 'super_admin' ? 'Super Admin (صلاحية كاملة)' : 'Admin'}</span>
                  </div>

                  <div className="space-y-3">
                    <div className="bg-[#0B0F19] rounded-xl px-4 py-3 flex justify-between items-center border border-white/5">
                      <p className="text-gray-500 text-xs font-bold">البريد الإلكتروني</p>
                      <p className="text-white text-sm font-cy-bold" dir="ltr">{profile.email}</p>
                    </div>
                    <div className="bg-[#0B0F19] rounded-xl px-4 py-3 flex justify-between items-center border border-white/5">
                      <p className="text-gray-500 text-xs font-bold">تاريخ الإنشاء</p>
                      <p className="text-white text-sm font-cy-bold">{profile.createdAt ? new Date(profile.createdAt).toLocaleDateString("ar-JO") : "—"}</p>
                    </div>
                    <div className="bg-[#0B0F19] rounded-xl p-4 border border-white/5 space-y-2">
                      <p className="text-gray-400 text-xs font-bold mb-2">🛡️ الصلاحيات المفعلة بالكامل:</p>
                      <div className="space-y-1.5 text-xs text-gray-300 font-bold">
                        <p className="flex items-center gap-2">🟢 إدارة واعتماد الكباتن والعملاء</p>
                        <p className="flex items-center gap-2">🟢 شحن محافظ الكباتن وتعديل الأرصدة</p>
                        <p className="flex items-center gap-2">🟢 تعديل أسعار الرحلات وعمولات النظام</p>
                        <p className="flex items-center gap-2">🟢 تصدير البيانات والنسخ الاحتياطية</p>
                      </div>
                    </div>
                  </div>
                  <div className="flex gap-3 pt-2">
                    <button onClick={() => setIsEditingProfile(true)} className="flex-1 bg-[var(--color-brand-500)] text-[#0B0F19] font-bold py-3 rounded-xl hover:bg-[var(--color-brand-600)] transition-colors text-sm shadow-lg">تعديل الملف الشخصي</button>
                    <button onClick={() => setIsProfileModalOpen(false)} className="flex-1 border border-white/10 text-gray-400 font-bold py-3 rounded-xl hover:bg-white/5 transition-colors text-sm">إغلاق</button>
                  </div>
                </>
              )}
            </div>
          </div>
        )}

        {/* PAGE CONTENT */}
        <main className="flex-1 overflow-y-auto p-8 custom-scrollbar">
          <div className="max-w-[1400px] mx-auto w-full">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}

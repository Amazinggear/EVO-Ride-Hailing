# ⚡ EVO — منصة توصيل السيارات الكهربائية في الأردن

<div dir="rtl">

## 🗂️ هيكلية المشروع

```
EVO/
├── evo-backend/           # Node.js Backend API + Socket.io
├── evo_passenger/         # Flutter — تطبيق الراكب
├── evo_driver/            # Flutter — تطبيق الكابتن
└── evo_admin/             # Next.js Admin Dashboard (قيد الإنشاء)
```

## 🚀 البدء السريع

### المتطلبات
- Node.js >= 18
- Flutter >= 3.1.0
- PostgreSQL (مع PostGIS)
- Redis (Upstash)
- Firebase Project
- OneSignal Account

### 1. Backend Setup

```bash
cd evo-backend
cp .env.example .env
# أضف بياناتك في .env
npm install
npm run migrate      # تهجير قاعدة البيانات
npm run dev          # تشغيل السيرفر
```

**Server يشتغل على:** `http://localhost:5000`
**WebSocket:** `ws://localhost:5000`
**Health check:** `http://localhost:5000/health`

### 2. Flutter Passenger App

```bash
cd evo_passenger
flutter pub get
flutter run
```

### 3. Flutter Driver App

```bash
cd evo_driver
flutter pub get
flutter run
```

---

## 🏗️ Architecture Overview

```
Passenger App (Flutter)    Driver App (Flutter)
        │                         │
        │──── REST API ────────────│
        │──── WebSocket ───────────│
        ▼                         ▼
   Node.js/Express Backend (Railway)
        │
   PostgreSQL + Redis + Firebase Auth
        │
   OneSignal │ Cloudflare R2 │ OpenChargeMap
```

## ⚡ Real-Time Zero-Lag Sync

**تقنية:** Redis Pub/Sub — قناة مستقلة لكل رحلة

```
Driver GPS (كل 5 ثواني)
  → Socket.io → Redis Pub/Sub (ride:{id}:location)
  → Passenger Socket receives → Smooth animated marker
  
الوقت الكلي: < 200ms
```

## 📡 API Endpoints Summary

| Module | Endpoints |
|--------|-----------|
| Auth | POST /auth/verify-otp, /auth/refresh-token |
| Driver Registration | POST /driver/register/step-{1-4}, /submit |
| Rides | GET /rides/nearby-drivers, POST /rides/request, /estimate |
| Driver Ops | PATCH /rides/:id/{accept,start,complete} |
| Wallet | GET /wallet/balance, /wallet/transactions |
| Charging | GET /charging-stations |
| Promo | POST /promo/validate |
| Admin | /api/admin/* (20+ admin endpoints) |

## 🗄️ Database Schema (12 Tables)

```
users → driver_profiles → driver_documents → driver_approval_logs
                                                      ↕
rides → transactions → payment_cards          admin_audit_logs
  ↕
promo_codes → promo_code_usages
  ↕
pricing_config → surge_zones → charging_stations
```

## 🔒 Security

- JWT Authentication (7-day access + 30-day refresh)
- Firebase Phone OTP (حماية أرقام الهاتف)
- AES-256 encryption for driver documents in Cloudflare R2
- Rate limiting: 300 req/15min (20 req/hr for auth)
- GPS spoofing detection (يرفض تحديثات تتجاوز 200 km/h)
- Admin audit logs for all critical actions

## 🌍 Languages

- **Arabic (ar)** — RTL, Cairo font, Jordanian dialect
- **English (en)** — LTR
- Dynamic switching without app restart

## 💰 Pricing Formula

```
Total = (Base + Distance×PerKm + Duration×PerMin) × Surge
Discount = min(Total × pct/100, maxDiscount) OR fixed
FinalFare = max(Total - Discount, minFare)
CO₂ Saved = Distance × 0.21 kg
```

## 📋 Implementation Status

| Phase | Status |
|-------|--------|
| Phase 1: Foundation | 🟡 In Progress |
| Phase 2: Auth & Registration | ⭕ Not Started |
| Phase 3: Passenger App | ⭕ Not Started |
| Phase 4: Driver App | ⭕ Not Started |
| Phase 5: Admin Dashboard | ⭕ Not Started |
| Phase 6: Polish & Launch | ⭕ Not Started |

## 🔧 Services & Credentials Needed

| Service | Status | How to Get |
|---------|--------|------------|
| Firebase Project | ⭕ Setup needed | firebase.google.com |
| OneSignal App | ⭕ Setup needed | onesignal.com |
| Google Maps API | ⭕ Setup needed | console.cloud.google.com |
| OpenChargeMap API | ⭕ Setup needed | openchargemap.org/develop |
| PayTabs Merchant | ⭕ Apply needed | merchant.paytabs.com |
| Neon/Supabase DB | ⭕ Setup needed | neon.tech or supabase.com |
| Upstash Redis | ⭕ Setup needed | upstash.com |
| Cloudflare R2 | ⭕ Setup needed | cloudflare.com |
| Railway (Backend) | ⭕ Setup needed | railway.app |
| Vercel (Admin) | ⭕ Setup needed | vercel.com |

</div>

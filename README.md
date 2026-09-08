# 🅿️ ParkDady Host — Space Owner & Parking Spot Management Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Backend](https://img.shields.io/badge/Backend-Supabase_PostgreSQL-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Maps](https://img.shields.io/badge/Maps-Google_Maps_SDK-4285F4?style=for-the-badge&logo=googlemaps&logoColor=white)](https://cloud.google.com/maps-platform)
[![RBAC](https://img.shields.io/badge/Security-Dual--Role_RBAC-10B981?style=for-the-badge)](https://supabase.com)

> **ParkDady Host** is an enterprise cross-platform mobile application built with **Flutter** and **Supabase** designed for residential and commercial parking space owners. It empowers hosts to monetize unused parking spots, configure hourly rates, monitor real-time check-ins, and manage monthly earnings.

---

## 🏗️ Architecture & Dual-Role System

ParkDady Host incorporates an intelligent **Dual-Role State Machine** allowing registered users to seamlessly operate as both space owners (Hosts) and parking seekers (Renters) under a single identity profile:

```
┌─────────────────────────────────────────────────────────────┐
│                      HOST PRESENTATION                      │
│  • Spot Inventory & Availability Calendar Controller        │
│  • Real-Time Spot Occupancy Dashboard                       │
│  • Dynamic Hourly & Flat-Rate Pricing Manager               │
│  • Payouts, Earnings Analytics & Bank Account Linking       │
├─────────────────────────────────────────────────────────────┤
│                    DUAL-ROLE RBAC ENGINE                    │
│  • Dynamic Role Switcher (Host ⇋ Renter)                    │
│  • Isolated Permission Boundaries with Supabase RLS         │
│  • Google Maps Geocoding for Accurate Spot Coordinates      │
├─────────────────────────────────────────────────────────────┤
│                     DATA & BACKEND CORE                     │
│  • Supabase PostgreSQL Database with Custom Triggers        │
│  • Realtime Occupancy WebSockets                            │
│  • Encrypted Keystore for Release Security                  │
└─────────────────────────────────────────────────────────────┘
```

---

## ✨ Features

- 📍 **Interactive Spot Onboarding:** Pinpoint exact parking spots with Google Maps integration, upload photos, and define access instructions.
- 💵 **Flexible Rate Engine:** Set custom hourly, daily, or flat weekend parking tariffs.
- 📊 **Real-Time Occupancy Tracking:** Instant notifications and dashboard updates when a driver reserves or checks in to your parking space.
- 💳 **Earnings & Direct Payouts:** Automated transaction summaries, commission calculations, and monthly payout records.
- 🛡️ **Account Lifecycle & Security:** Includes self-service account deletion compliant with Google Play Store & Apple App Store guidelines.

---

## 🚀 Quick Setup & Installation

### 1. Clone the Repository
```bash
git clone https://github.com/sangamesh5588/park-dady-host-.git
cd park-dady-host-
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Environment Configuration
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
```ini
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
```

### 4. Run Application
```bash
flutter run
```

---

## 🛡️ License
Copyright © 2026 Sangamesh K. All rights reserved.
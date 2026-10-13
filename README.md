# X-Agents by TripCosmos.co 🚀
### Superfone-Grade AI Telephony, Multi-Source CRM & Autonomous Sales Agent App

**X-Agents** is an enterprise-grade mobile application built for TripCosmos.co sales teams, tour coordinators, and cab logistics desks. It provides a complete, 100% Free Superfone alternative powered by our physical Jio SIM (`+91 93361 16210`) and local WordPress AI Puffer RAG Bot (`Bot 155464`).

---

## 🌟 Key Features

### 1. 📞 Zero-Cost Jio SIM Telephony & Smart Dialer
- **T9 Fast Search Dialer**: Dial any customer or search contacts by name.
- **Jio 5G Hardware Bridge**: All calls routed via unlimited domestic calling (`+91 93361 16210`) for ₹0.00/min.
- **Smart Floating Caller-ID Overlay**: Displays customer name, city, tour package of interest, group size, budget, and last chat notes before/during calls.
- **1-Tap Post-Call Action Sheet**: Dispatches instant WhatsApp brochures, cab tariff sheets, and ₹1,500 advance booking token links upon call termination.

### 2. 👥 10,000+ Multi-Source Leads & CRM Hub
- **Universal Inbound Ingestion**: Syncs in real time from:
  - Website Chatbot & Fast Quote Forms
  - WhatsApp Business Inbound
  - Meta (Facebook & Instagram) Lead Ads
  - Google Search Ads
  - Direct Phone Calls
- **Dynamic Kanban/List Pipeline**: Stages: `New Lead`, `Contacted`, `Qualified`, `Quote Sent`, `Advance Paid (Won)`, `Lost`.
- **Sticky Agent Routing**: Automatically routes returning travelers to their dedicated tour specialist (e.g. Santosh Yadav).

### 3. 🤖 Autonomous AI Agents Command Center
- **AI Outbound Sales Agent**: One-tap toggle. Automatically polls pending website leads from `/mobile/call-queue` and initiates conversational qualification calls.
- **24/7 AI Voice Receptionist**: Speaks concise, warm 2-sentence responses via Google's native speech engine and local **AI Puffer RAG Bot 155464 ("TripCosmos AI")**.
- **Live AI RAG Playground**: Test-drive pilgrimage questions (Aarti timings, VIP Darshan, Innova rates) directly inside the app.

### 4. 💬 WhatsApp & Dispatch Hub
- **Pre-Approved Spiritual Brochures**:
  - Varanasi 3D2N VIP Darshan & Reserved Boat (₹12,499)
  - Ayodhya Ram Mandir Day Tour (₹19,800)
  - Kashi - Gaya - Bodhgaya Circuit (₹18,500)
  - Outstation Cab Rate Card (Dzire ₹11/km, Innova ₹17/km, Tempo ₹24/km)
- **Dynamic Tour & Cab Tariff Calculator**: Instant Net (B2B) vs Retail (B2C) quote generation with commission breakdown.

### 5. 📊 In-App Telephony & Sales Reports
- Real-time call logs, talk time duration, conversion funnel, and sticky agent leaderboards.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: Flutter 3.47+ (Dart 3.13+) with Material 3 Dark Palette
- **State Management**: Reactive `Provider` (CallProvider, LeadProvider, AiAgentProvider)
- **Design System**: TripCosmos Celestial Midnight Navy (`#0B132B`), Sacred Saffron Gold (`#F59E0B`), and Frosted Glassmorphism
- **Backend API**: Connected to `https://tripcosmos.co/wp-json/tc-agents/v1/`
- **Native Android Telephony**: `Intent.ACTION_CALL`, `url_launcher` (wa.me)

---

## 📱 How to Run & Build

### Development / Debug Run:
```bash
flutter run
```

### Build Android APK:
```bash
# Debug APK:
flutter build apk --debug

# Production Release APK:
flutter build apk --release
```
Output APK location:
`build/app/outputs/flutter-apk/app-debug.apk` or `app-release.apk`

# TripCosmos Sales Agents 🚀📱
### Native Android CRM companion for the TripCosmos Agents WordPress plugin (api_level 2)

An Android sales companion for TripCosmos travel concierges: leads, follow-ups, trip quotes and
payments, a central WhatsApp inbox, and zero-cost calling over the agent's own carrier SIM.

---

## v3.0.0 — rebuilt on the plugin's mobile CRM API

This is a full rewrite of the app's data and UI layers against the plugin's `api_level 2` mobile API
(20 endpoints: dashboard, leads, tasks, bookings/quotes/payments, WhatsApp threads). Earlier versions
(`v1.0.x`–`v2.x`, see tags/history) talked to a smaller, earlier set of endpoints.

### What's in this version

- **Screens**: Today (dashboard), Leads (search/filter/add), Lead detail (AI call summary, tasks,
  activity timeline, trips), Follow-ups, a Trip/Quote/Payment sheet, WhatsApp inbox + thread (with
  an AI on/off switch and delivery ticks), pairing/settings, and a post-call notes sheet.
- **Telephony**: `PhoneStateReceiver` + `CallTracker` decide call type/duration from the phone's own
  call log (not just broadcast timing), so outgoing calls are correctly attributed via a short-lived
  "pending outgoing" marker. `CallerIdOverlayService` shows a floating card with the caller's CRM
  info while the phone rings.
- **Offline**: `Repository` caches the last good response of each screen in Room, and surfaces
  network/auth/validation errors with the server's own message.
- **Notifications**: `SyncWorker` (WorkManager, ~15 min) turns new leads, WhatsApp replies and due
  follow-ups into local notifications, each announced once.
- **Security**: the mobile access token lives in `EncryptedSharedPreferences`; there is no built-in
  default token — pair a device with a token generated in WordPress → TripCosmos Agents →
  Integrations → Mobile App Access.

### Project structure

```
apps/sales-agents-android/
├── app/
│   ├── build.gradle.kts
│   ├── proguard-rules.pro
│   └── src/
│       ├── main/
│       │   ├── AndroidManifest.xml
│       │   ├── java/co/tripcosmos/salesagents/
│       │   │   ├── AppConfig.kt              # pairing, encrypted token, settings
│       │   │   ├── SalesAgentsApp.kt
│       │   │   ├── data/
│       │   │   │   ├── api/                  # Retrofit service + client
│       │   │   │   ├── db/                   # Room cache
│       │   │   │   ├── model/                # wire models (api_level 2)
│       │   │   │   ├── repo/Repository.kt    # single call path, Res<T>, caching
│       │   │   │   └── sync/CallLogSync.kt   # retry queue for call logs
│       │   │   ├── notify/                   # notifications + background sync worker
│       │   │   ├── telephony/                # call detection, dialer, caller-ID overlay
│       │   │   ├── ui/                       # Compose screens
│       │   │   └── updater/                  # GitHub release checker
│       │   └── res/
│       ├── debug/                            # cleartext-to-localhost config for local testing
│       └── test/                             # JUnit + MockWebServer unit tests
├── build.gradle.kts
└── settings.gradle.kts
```

### Building

```
cd apps/sales-agents-android
./gradlew.bat :app:testDebugUnitTest   # 33 tests
./gradlew.bat :app:assembleDebug       # unsigned debug APK
./gradlew.bat :app:assembleRelease     # needs keystore.properties + a release keystore
```

Release signing: `keystore.properties` and `signing/*.jks` are gitignored and never committed.
Generate your own with `keytool -genkeypair -v -keystore signing/release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tripcosmos`
and point `keystore.properties` at it (see `app/build.gradle.kts` for the expected keys:
`storeFile`, `storePassword`, `keyAlias`, `keyPassword`).

### Pairing a device

1. In WordPress: TripCosmos Agents → Integrations → Mobile App Access → generate a token.
2. Install the app, open it, paste the site URL and the token.
3. Grant "Display over other apps" so the caller-ID card can show while a call rings.

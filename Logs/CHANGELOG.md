# Texas Daily — Changelog

---

## 2026-03-11

### Android — AdMob IDs + Manifest Cleanup + Play Console Setup

**`Android/Project/app/src/main/java/com/refuge/texasdaily/ui/components/BannerAdView.kt`**
- Replaced Google test banner unit ID with production Android banner unit ID:
  - `ca-app-pub-2130345513930124/7290959047`

**`Android/Project/app/src/main/AndroidManifest.xml`**
- Removed unused exact alarm permission:
  - Removed `android.permission.SCHEDULE_EXACT_ALARM`
- Updated AdMob Android App ID meta-data to production app ID:
  - `ca-app-pub-2130345513930124~6457369469`

**AdMob Console**
- Created Android app entry for Texas Daily.
- Created Android banner ad unit used above.

**Google Play Console**
- Confirmed app exists in Play Console (`Texas Daily`, app id `4972268518474885176`).
- In-app one-time product creation remains blocked by merchant account setup requirement in Play Console.

### Android — Initial Release Build

**New Platform: Android (Kotlin / Jetpack Compose)**
- Created full Android project at `Android/Project/` targeting API 26+ (Android 8.0), compiled against API 35.
- Package ID matches iOS: `com.refuge.texasdaily`.

**`app/build.gradle.kts` + `gradle/libs.versions.toml`**
- Configured AGP 8.5.2, Kotlin 2.0.21, Compose BOM 2024.09.03, Material3.
- Dependencies: WorkManager, DataStore Preferences, Gson, Coroutines, Google Mobile Ads 23.5.0, Play Billing 7.1.1, Material Icons Extended.

**`data/TexasFact.kt`**
- `TexasFact` and `FactsWrapper` data classes matching iOS model; `@SerializedName("facts")` for Gson wrapper unwrap.

**`data/FactRepository.kt`**
- Loads `texas_facts.json` from `res/raw/` via Gson, unwrapping the `facts` array.
- `getCategories()` returns sorted distinct category list.
- `randomFact()` respects category filter; falls back to full pool if no filter active.
- JSON file copied from iOS project.

**`viewmodel/TexasViewModel.kt`**
- Replaces iOS `TexasAppViewModel` with Kotlin `ViewModel` + `StateFlow`.
- DataStore Preferences for dark mode, reminder toggle/time, and selected categories (`Set<String>`).
- `loadNewFact()`, `toggleCategory()`, `clearCategoryFilter()`, `setDarkMode()`, `saveReminder()`.
- `BillingManager` injected via `Factory`; `adsRemoved` state flows up to UI via `billingManager.adsRemoved`.

**`billing/BillingManager.kt`**
- Google Play Billing Library 7.x implementation replacing iOS StoreKit 2.
- Same product ID as iOS: `com.refuge.texasdaily.removead`.
- Connects on init, queries product details and existing purchases.
- `purchaseRemoveAds(activity)`, `restorePurchases()`, purchase acknowledgement, `onPurchasesUpdated` listener.
- `adsRemoved` and `statusMessage` exposed as `StateFlow`.

**`ui/screens/MainScreen.kt`**
- Full-screen fact display: category chip, main fact card (serif), background info card, source + date footer.
- Share button generates plain-text share intent with fact + source + "Shared from Texas Daily".
- Filter button tinted accent green when any category is active.
- Bottom banner ad slot hidden when `adsRemoved == true`; content padded to avoid ad overlap.
- `CategoryFilterSheet` shown as modal bottom sheet on filter tap.

**`ui/screens/SettingsScreen.kt`**
- Appearance toggle (dark/light) with `Switch`.
- Daily reminder toggle; expands to show Material3 `TimePicker` + "Save & Schedule" button + confirmation banner.
- Support Us section (hidden when ads removed): "Remove Ads — $1.99" purchase button + "Restore Purchases".
- Billing status messages auto-clear after 3 seconds via `LaunchedEffect`.
- About card with app description.

**`ui/components/BannerAdView.kt`**
- Wraps `AdView` in `AndroidView` Composable.
- Ad unit ID set to Android test banner ID (`ca-app-pub-3940256099942544/6300978111`) — **replace with real Android unit ID before publishing** (`ca-app-pub-2130345513930124/7290959047`).

**`ui/components/CategoryFilterSheet.kt`**
- `ModalBottomSheet` with scrollable category list, checkmarks on selected items, "Clear All" button, close button.

**`ui/theme/`**
- `Color.kt`: Accent green `#85A63D`, limestone parchment light background, deep charcoal dark background, pecan brown light ink.
- `Theme.kt`: `TexasDailyTheme` with explicit light/dark `ColorScheme`; theme driven by `isDarkMode` StateFlow.
- `Type.kt`: Serif headings and body, sans-serif labels — mirrors iOS typography scale.

**`notifications/DailyReminderWorker.kt`**
- `PeriodicWorkRequest` fires daily at user-set time. `ExistingPeriodicWorkPolicy.UPDATE` to reschedule cleanly.
- Notification channel `texas_daily_reminder`.

**`notifications/BootReceiver.kt`**
- Restores WorkManager daily reminder after reboot if reminder was enabled; reads enabled flag + time from DataStore.

**`TexasDailyApplication.kt`**
- Initializes Google Mobile Ads SDK (`MobileAds.initialize`) on app startup.

**`MainActivity.kt`**
- Added runtime `POST_NOTIFICATIONS` permission request for Android 13+ (API 33+).
- Two-screen `AnimatedContent` router: `MainScreen` ↔ `SettingsScreen`.

**`AndroidManifest.xml`**
- Permissions: `INTERNET`, `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`.
- AdMob Application ID meta-data: `ca-app-pub-2130345513930124~9178491170`.
- `BootReceiver` registered for `BOOT_COMPLETED`.

**`res/mipmap-*/`**
- App icons generated from iOS iTunes Artwork (1024×1024), resized to all Android mipmap densities (mdpi 48px → xxxhdpi 192px).
- Adaptive icon XML (`mipmap-anydpi-v26/`) with accent green background.

**`gradle/wrapper/gradle-wrapper.properties`**
- Added wrapper pointing to Gradle 8.7.

---

## 2026-03-10

### Compliance + Ad Serving

**`TexasDailyApp.swift`**
- Confirmed launch flow now binds ad readiness to UMP result: `adsSDKReady = await requestConsentAndStartAds()`.
- Ads SDK only starts when `ConsentInformation.shared.canRequestAds == true`.

**`SettingsView.swift`**
- Added in-app **Privacy Choices** entry point for regions where privacy options are required.
- Added `presentPrivacyChoices()` flow using `ConsentForm.presentPrivacyOptionsForm(...)`.
- After privacy form dismissal, app now re-syncs ad eligibility (`adsSDKReady`) and starts AdMob if consent allows.

### Bug Fixes

**`Texas Daily.xcodeproj/project.pbxproj`**
- Aligned deployment targets for project and test targets to `16.6` (removed `26.1` mismatch that could cause test/runtime inconsistencies).

**`NotificationManager.swift` + `TexasAppViewModel.swift`**
- Changed repeating daily reminder content to a neutral prompt (`"Tap to read today's Texas fact."`) to avoid stale repeated fact text.
- Scheduling now no longer depends on a specific in-memory fact payload.

### Performance

**`TodayFactView.swift`**
- Reworked share generation to lazy-render on tap (`prepareShareSheet()`) instead of rendering on every fact change/on-appear.
- Added cached share state per fact id and invalidation on fact changes (`resetSharePayload(...)`).
- Added temporary loading state for share preparation.

---

## 2026-03-09

### Bug Fixes

**`FactStore.swift`**
- Added error logging to the JSON load failure path. Previously a missing or malformed `texas_facts.json` silently returned an empty facts array with no indication of failure. Now logs the specific decode error and a success count on load.

**`NotificationManager.swift`**
- Replaced silent `// swallow` error suppression in `scheduleDailyFactNotification()` with `print("⚠️ Failed to schedule daily fact notification: \(error)")`. Scheduling failures are now visible in logs.

**`TexasAppViewModel.swift`**
- Validated loaded category selections against the current fact set on init. Categories saved in UserDefaults from a previous app version that no longer exist in the current fact set are now filtered out instead of being silently restored as phantom filters.

**`TodayFactView.swift`**
- Fixed `formattedDate()` to return `nil` for any date string that cannot be parsed as ISO 8601, instead of falling through and displaying the raw string. Malformed date values (e.g. `"2025-13-45"`) no longer appear in the UI.

### New Features

**`SettingsView.swift`**
- Added Daily Reminder toggle with wheel time picker and "Save & Schedule" button.
- Added "Saved & scheduled." confirmation banner after saving.
- Added Light / Dark mode theme picker with immediate application.
- Added Support Us section with Remove Ads in-app purchase and Restore Purchases.

**`TexasAppViewModel.swift`**
- Added StoreKit listener (`startStoreKitListener()`) initialized on app launch for real-time purchase updates.
- Added `refreshEntitlements()` for verifying purchase status on launch and after restore.
- Added `scheduleDailyReminderIfEnabled()` for managing daily notification scheduling.
- Added notification time persistence using UserDefaults (hour + minute keys).

**`TexasDailyApp.swift`**
- Integrated GDPR/CCPA consent handling via Google's User Messaging Platform (UMP). Consent form appears for users in EU, UK, California, and other regulated regions. Ads only initialize after consent is granted.

**`RootView.swift`**
- Settings screen now opens as a full-screen cover instead of a modal sheet for immediate theme application.

**`TodayFactView.swift`**
- Added share functionality — facts rendered as high-resolution images via `FactShareCard` at 3× scale and shared through the native iOS share sheet.
- Share content includes fact text, source attribution, and "Shared from Texas Daily".

**`FactShareCard.swift`** *(new file)*
- New component for rendering facts as branded shareable images. Includes "TEXAS DAILY" header, category chip, fact text, and source attribution at a fixed 390pt width for consistent share dimensions.

**`ActivityView.swift`** *(new file)*
- UIViewControllerRepresentable wrapper around `UIActivityViewController` enabling native iOS share sheet integration.

**`BannerAdView.swift`**
- Google AdMob banner ad implementation. Only displays after consent is granted and StoreKit entitlement verification completes. Hidden for users who purchased ad removal.

### Accessibility

**`RootView.swift`**
- Added `.accessibilityLabel("Settings")` to the gear icon button.
- Increased gear button touch target to minimum 44×44pt.

**`TodayFactView.swift`**
- Added `.accessibilityLabel("Share fact")` and `.accessibilityHint` to the share button. Button is now always present (previously conditionally hidden) — disabled with a dimmed appearance when share image is not yet ready, with a hint explaining availability.
- Added `.accessibilityLabel("Filter categories")` and `.accessibilityHint("Opens the category filter sheet")` to the filter button. Increased touch target to minimum 44×44pt.
- Added `.accessibilityLabel` and `.accessibilityHint` to each category toggle row in the filter sheet — VoiceOver now announces selected/deselected state and provides a "Double tap to select/deselect" hint.
- Added `.accessibilityLabel("Close")` to the filter sheet close button. Increased touch target to minimum 44×44pt.

**`SettingsView.swift`**
- Added `.accessibilityLabel("Close settings")` to the close button. Increased touch target to minimum 44×44pt.
- Added `.accessibilityLabel("Daily reminder")` and dynamic `.accessibilityHint` (on/off state) to the daily reminder toggle.

---

## Previous

- Initial app build and content population.

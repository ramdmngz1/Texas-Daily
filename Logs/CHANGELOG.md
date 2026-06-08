# Texas Daily — Changelog

---

## 2026-05-21

### Production Deployment Infrastructure

Complete CI/CD pipeline, automated store deployment, and monitoring strategy.

**D1 — GitHub Actions: iOS CI/CD (`.github/workflows/ios.yml`)**
- PR builds: Xcode build + test with SPM cache
- Main push: auto-deploy to TestFlight via Fastlane
- Tag `ios-v*`: submit to App Store Review
- Concurrency groups prevent duplicate runs

**D2 — GitHub Actions: Android CI/CD (`.github/workflows/android.yml`)**
- PR builds: Gradle lint + assembleDebug + unit tests
- Main push: bundle release AAB → Play Internal Track
- Tag `android-v*`: bundle → Play Store Production
- Gradle + wrapper caching for fast builds

**D3 — Release Management (`.github/workflows/release.yml`)**
- Manual `workflow_dispatch` with platform selector and version input
- Auto-bumps `MARKETING_VERSION`/`versionCode` + `versionName`
- Creates platform-specific tags that trigger store deployments
- Generates GitHub Release with notes

**D4 — Weekly Health Check (`.github/workflows/health-check.yml`)**
- Scheduled Monday 9am UTC: builds both platforms, runs lint, checks dependencies
- Early warning for broken builds or outdated dependencies

**D5 — Fastlane Configuration (`fastlane/Fastfile`, `fastlane/Appfile`)**
- `beta` lane: increment build number → archive → TestFlight upload
- `release` lane: increment → archive → App Store submit with auto-release
- App Store Connect API key auth (no password prompts in CI)

**D6 — Deployment Guide (`DEPLOYMENT.md`)**
- Architecture diagram, pipeline trigger matrix, secrets inventory
- Step-by-step Firebase Crashlytics setup for both platforms
- Monitoring thresholds, reliability checklist, downtime risk matrix
- Emergency hotfix procedure

---

### Security Audit & Hardening (iOS & Android)

Full security audit across both platforms. 14 findings identified, fixes implemented for all actionable items.

#### HIGH Severity Fixes

**S1 — IAP bypass via UserDefaults tampering (iOS)**
- `StoreKitManager.init()` now defaults `adsRemoved = false` instead of reading from UserDefaults cache. Ads display until `refreshEntitlements()` completes with Apple-signed verification. Eliminates the jailbreak/backup-editing attack vector entirely.

**S2 — Purchase signature verification (Android)**
- Added `isVerifiedPurchase()` to `BillingManager` that checks `purchaseState`, product ID match, and non-empty `signature`/`originalJson`. Applied to all three purchase-checking paths: `checkExistingPurchases()`, `restorePurchases()`, and `onPurchasesUpdated()`.

**S3 — `local.properties` tracked in git**
- Added `local.properties`, `*.jks`, `*.keystore`, `.gradle/`, `.idea/`, `*.apk`, `*.aab` to `.gitignore`. File must be manually untracked with `git rm --cached Android/Project/local.properties`.

#### MEDIUM Severity Fixes

**S5 — GDPR consent errors silently swallowed (iOS)**
- `AdsManager.requestConsentAndStartAds()` now returns `false` (no ads) when consent info update or consent form presentation fails. Prevents ads from loading without valid consent state.

**S6 — Network security config (Android)**
- Created `res/xml/network_security_config.xml` with `cleartextTrafficPermitted="false"`. Wired to manifest via `android:networkSecurityConfig`.

#### LOW Severity Fixes

**S8 — Error messages leak internal details (iOS)**
- `StoreKitManager` purchase/restore errors now show generic user-facing messages. Raw `error.localizedDescription` logged only in `#if DEBUG`.

**S10 — Production ad unit on physical debug devices (iOS)**
- `BannerAdView` now uses Google's test ad unit for all `#if DEBUG` builds, not just simulator. Prevents invalid traffic flags on the AdMob account.

**S11 — Billing reconnect loop without backoff (Android)**
- `onBillingServiceDisconnected` now uses exponential backoff (1s, 2s, 4s… capped at 32s) via `Handler.postDelayed` instead of immediate reconnection.

---

### Production UI Component Library (iOS & Android)

Extracted reusable UI components, improved accessibility, and added polished transitions. No functionality changes.

#### iOS — 1 New File, 3 Files Modified

**U1 — Created `AppComponents.swift` — shared UI component library**
- `CardStyle` ViewModifier (`.appCard(fill:cornerRadius:shadowRadius:shadowY:)`) replaces 5 identical `RoundedRectangle + .fill + .shadow` blocks across TodayFactView, SettingsView, and CategoryFilterSheet.
- `AccentButtonStyle` — proper `ButtonStyle` with built-in press animation (scale spring). Replaces the manual `isButtonPressed` `@State` + `simultaneousGesture(DragGesture)` workaround in TodayFactView (20 lines → 3 lines).
- `StatusBanner` — auto-dismissing message view using `.task(id:)`. Replaces inline status text with manual formatting in SettingsView.
- `EmptyStateView` — accessible empty state with icon, title, and subtitle.

**U2 — `TodayFactView.swift` — Dynamic Type + component adoption**
- Added `@ScaledMetric(relativeTo: .title)` for the fact title font size — scales with the user's Dynamic Type setting for accessibility.
- Replaced manual card background+shadow with `.appCard(fill:)`.
- Replaced 20-line manual button press animation with `AccentButtonStyle`.

**U3 — `SettingsView.swift` — component adoption**
- Replaced 3 identical card background+shadow blocks with `.appCard(fill: cardColor)`.
- Replaced inline status message `Text` with `StatusBanner(message:isError:onDismiss:)`.

**U4 — `CategoryFilterSheet.swift` — component adoption**
- Replaced card background+shadow with `.appCard(fill: cardColor)`.

#### Android — 1 New File, 2 Files Modified

**U5 — Created `ui/components/AppComponents.kt` — shared composable library**
- `AppCard` — promoted from `SettingsScreen`'s private `SettingsCard`. Configurable corner radius and elevation.
- `EmptyState` — composable with icon, title, and optional subtitle.
- `StatusBanner` — auto-dismissing with `AnimatedVisibility` fade + `LaunchedEffect` timer.

**U6 — `MainScreen.kt` — animated transitions + empty state**
- Wrapped fact content in `Crossfade(animationSpec = tween(300))` for smooth fact-to-fact transitions.
- Added `LaunchedEffect(fact?.id)` to `animateScrollTo(0)` when facts change.
- Added `EmptyState` composable for null-fact loading state.

**U7 — `SettingsScreen.kt` — component adoption**
- Replaced private `SettingsCard` with shared `AppCard` import (4 usages).
- Replaced inline billing status `Text` + `LaunchedEffect(delay)` with `StatusBanner`.

---

### Clean Architecture Refactoring (iOS & Android)

Separated concerns, reduced coupling, and improved modularity across both platforms. No functionality changes.

#### iOS — 5 New Files, 6 Files Modified

**A1 — Extracted `StoreKitManager.swift` from TexasAppViewModel**
- TexasAppViewModel was a 267-line God Object handling facts, categories, notifications, StoreKit transactions, entitlement verification, and purchase/restore flows — 5 unrelated domains in one class.
- Extracted all StoreKit 2 logic (transaction listener, `buy()`, `restore()`, `refreshEntitlements()`, verification) into a dedicated `StoreKitManager: ObservableObject`. Injected as a separate `@EnvironmentObject` for views that need purchase state.
- TexasAppViewModel reduced to 120 lines focused on facts, categories, and notifications.

**A2 — Extracted `AdsManager.swift` from TexasDailyApp**
- `TexasDailyApp.swift` contained 50 lines of Google UMP consent flow and AdMob initialization logic — business logic in the app entry point.
- Moved to `AdsManager` singleton. `TexasDailyApp` reduced from 89 lines to 24 — just app lifecycle and environment injection.

**A3 — Created `PreferenceKeys.swift` — centralized UserDefaults keys**
- 7 UserDefaults key strings were scattered as private constants across `TexasAppViewModel`, referenced by raw strings. A typo in any key would silently create a separate preference.
- Centralized into a `PreferenceKeys` enum. All callers (ViewModel, StoreKitManager) reference the shared constants.

**A4 — Extracted `CategoryFilterSheet.swift` from TodayFactView**
- `TodayFactView.swift` contained two independent view structs — the main fact screen (327 lines) and the category filter sheet (165 lines). Violated one-type-per-file principle.
- Moved `CategoryFilterSheet` to its own file. No code changes to the struct itself.

**A5 — Extracted `UIApplication+KeyWindow.swift` from AppColors**
- `AppColors.swift` contained a `UIApplication` extension for root view controller lookup — unrelated to colors.
- Moved to `UIApplication+KeyWindow.swift` following standard iOS extension naming. `AppColors.swift` now only contains color definitions. Removed unused `import UIKit` from AppColors.

#### Android — 1 New File, 2 Files Modified

**A6 — Created `data/PreferenceKeys.kt` — centralized DataStore keys**
- The `Context.dataStore` extension and 6 preference key constants were defined at file level in `TexasViewModel.kt`. `BootReceiver.kt` duplicated 3 of the key strings (`"reminder_enabled"`, `"reminder_hour"`, `"reminder_minute"`) as inline `booleanPreferencesKey()`/`intPreferencesKey()` calls — a desync between the two files would silently read/write different preferences.
- Moved the DataStore extension and all keys to `data/PreferenceKeys.kt`. Both `TexasViewModel` and `BootReceiver` now import from the single source. Removed 6 unused DataStore-related imports from TexasViewModel.

---

### Performance Optimization Pass (iOS & Android)

Full codebase audit targeting speed, memory, rendering efficiency, and resource lifecycle.

#### iOS — 5 Optimizations

**P1 — Category index eliminates O(n) scans on every fact lookup (`FactStore.swift`)**
- `randomFact(from:excluding:)` filtered all 700 facts on every call — each "New Fact" tap, each category toggle, and 60 times during notification scheduling.
- Built a `categoryIndex: [String: [TexasFact]]` dictionary at init time. Lookups now use `flatMap` over the index, reducing per-call work from O(700) to O(facts-in-selected-categories).

**P2 — Notification cancel eliminates 2 IPC round-trips (`NotificationManager.swift`)**
- `cancelDailyFactNotification()` fetched all pending notifications and all delivered notifications from the system daemon, then filtered by prefix — two async IPC calls that blocked the main actor.
- Replaced with synchronous removal using the known identifier set (`dailyTexasFact_0`…`dailyTexasFact_59` + legacy `dailyTexasFact`). Function changed from `async` to synchronous. Callers updated to remove unnecessary `await`.

**P3 — Notification scheduling replaces 60 filter passes with single shuffle (`NotificationManager.swift`)**
- Each of the 60 notifications called `randomFact(excluding:)`, filtering the full 700-fact array each time (60 × O(n) = 42,000 comparisons). Also used only single-step exclusion, allowing near-repeats within the 60-day window.
- Replaced with `allFacts.shuffled()` — one O(n) pass produces 60 unique, non-repeating facts. Also eliminated the continuation-wrapped `requestAuthorization` in favor of the native async API available since iOS 15.

**P4 — Share image freed on sheet dismiss (`TodayFactView.swift`)**
- The 3×-rendered share card (`UIImage` at ~390×400pt × 3 × 4 bytes ≈ 7 MB) remained in `@State` memory after sharing until the next fact load.
- Added `onDismiss` handler to nil out `shareImage` when the share sheet closes, immediately reclaiming ~7 MB.

**P5 — Launch task reordered for faster startup (`TexasDailyApp.swift`)**
- On cold launch, StoreKit listener and notification scheduling waited behind the consent network call (`requestConsentAndStartAds`), which can take 1–5 seconds on slow connections.
- Reordered: StoreKit listener starts immediately, notifications schedule next (local work), consent/ads run last. Notifications and entitlement verification are now available seconds earlier.

#### Android — 5 Optimizations

**P6 — Category index eliminates O(n) scans on every fact lookup (`FactRepository.kt`)**
- Same issue as iOS P1. `randomFact()` filtered all 700 facts on every call.
- Added `categoryIndex: Map<String, List<TexasFact>>` built lazily alongside `allFacts`. `getCategories()` now returns `categoryIndex.keys.sorted()` instead of mapping + distinct + sort on the full array.

**P7 — BootReceiver uses `goAsync()` for process safety (`BootReceiver.kt`)**
- `onReceive` launched an unscoped `CoroutineScope(Dispatchers.IO)` coroutine to read DataStore preferences. The system could kill the receiver's process after `onReceive` returned but before the coroutine completed, silently dropping the reminder reschedule after reboot.
- Added `goAsync()` to hold the receiver alive, with `pendingResult.finish()` in a `finally` block guaranteeing cleanup.

**P8 — `enableEdgeToEdge` no longer runs on every recomposition (`MainActivity.kt`)**
- `SideEffect { enableEdgeToEdge(...) }` ran after every successful recomposition, calling into the window manager's system bar configuration on every frame — dozens of times per second during animations.
- Changed to `LaunchedEffect(isDark)` so it only fires when the dark mode value actually changes.

**P9 — First fact displays immediately on cold start (`TexasViewModel.kt`)**
- `loadNewFact()` was called inside `viewModelScope.launch` after `context.dataStore.data.first()`, blocking fact display until DataStore finished reading preferences from disk (50–200ms on cold start). The UI showed a blank screen during this window.
- Moved `loadNewFact()` before the coroutine launch. A fact displays instantly with no category filter. After DataStore loads, if the user had saved category preferences, the fact refreshes with those filters applied.

**P10 — AdView resources properly released on disposal (`BannerAdView.kt`)**
- `AndroidView` created an `AdView` in its factory but never called `destroy()` when the composable left composition. The ad view's internal WebView, network connections, and renderer leaked until process death.
- Added `onRelease = { it.destroy() }` to the `AndroidView` call, ensuring cleanup when the ad is removed from the UI (e.g., after purchasing "Remove Ads").

---

## 2026-05-20

### Production Bug Fix Pass (iOS & Android)

Full codebase audit identified and fixed 9 bugs across both platforms.

#### iOS — 5 Fixes

**B1 — "New Fact" button does nothing for single-fact categories (`FactStore.swift`)**
- `randomFact(from:excluding:)` had a `pool.count > 1` guard that skipped exclusion when a category contained exactly 1 fact. The same fact was returned (non-nil), so the fallback never fired. User taps the button, gets haptic feedback, but the fact never changes.
- Removed the count guard. Exclusion is now always attempted; falls through to the same fact only when there is literally no alternative in the pool.

**B2 — Category fallback silently ignored user's filter (`TexasAppViewModel.swift`)**
- `refreshTodayFact()` used `randomFact(from: selectedCategories, excluding:) ?? randomFact(excluding:)`. When the filtered call returned a non-nil result (even the same fact), the unfiltered fallback never fired. Restructured to only fall back to unfiltered when `selectedCategories` produces `nil`.

**B3 — Notification rescheduling storm from DatePicker (`TexasAppViewModel.swift`)**
- `onChange(of: viewModel.notificationTime)` fired on every wheel increment, each time cancelling all 60 pending notifications and re-scheduling 60 new ones. Spinning the picker caused hundreds of cancel+schedule cycles per second.
- Added 800ms debounce via a cancellable `Task`. UserDefaults still saves immediately; notification rescheduling waits for the wheel to settle.

**B4 — Double padding on "New Random Texas Fact" button (`TodayFactView.swift`)**
- Button had `.padding(.horizontal, 24).padding(.bottom, 24)` inside the computed property AND `.padding(.horizontal, 20).padding(.bottom, 18)` at the call site — 44pt total horizontal inset, making the button ~30% narrower than intended.
- Removed internal padding; external padding at the call site is the single source.

**B5 — Share sheet could present empty (`TodayFactView.swift`)**
- Race condition: if `viewModel.todayFact?.id` changed between `showingShareSheet = true` and sheet presentation, `resetSharePayload` set `shareImage = nil`. The sheet's `if let image = shareImage` resolved to false, rendering an empty view.
- Added `else` branch that auto-dismisses the sheet when `shareImage` is nil at presentation time.

#### Android — 4 Fixes

**B6 — "New Fact" button returns same fact (`FactRepository.kt`, `TexasViewModel.kt`)**
- `randomFact()` had no exclusion parameter — the user could tap "New Random Texas Fact" and see the identical fact.
- Added `excludingId: Int?` parameter to `randomFact()`. `loadNewFact()` now passes the current fact's ID. Same exclusion-with-fallback logic as the iOS fix.

**B7 — Toggling category filter didn't refresh the displayed fact (`TexasViewModel.kt`)**
- `toggleCategory()` and `clearCategoryFilter()` updated the selection state and persisted to DataStore, but never called `loadNewFact()`. The user changed filters, closed the sheet, and still saw the old (possibly irrelevant) fact.
- Both functions now call `loadNewFact()` after updating state, matching iOS behavior.

**B8 — "Restore Purchases" always showed success (`BillingManager.kt`)**
- `restorePurchases()` called `checkExistingPurchases()` (async callback) then immediately set `_statusMessage.value = "Purchases restored."` before the query completed. User always saw a success message regardless of actual purchase history.
- Inlined the query and moved the status message into the callback: "Purchases restored." vs. "No purchases found to restore." based on actual results.

**B9 — `LaunchedEffect` fired `saveReminder` on every Settings screen open (`SettingsScreen.kt`)**
- `LaunchedEffect(localReminderEnabled, timePickerState.hour, timePickerState.minute)` triggered on initial composition, re-scheduling the WorkManager notification on every Settings screen visit even without user interaction.
- Added `hasUserInteracted` flag that skips the first `LaunchedEffect` firing, so rescheduling only happens after the user actually changes the time.

### Architecture & Code Quality Refactoring (iOS & Android)

Codebase-wide refactoring to eliminate duplication, fix layer violations, and improve lifecycle management. No functionality changes.

#### iOS — Color Centralization & Layer Cleanup

**R1 — Centralized color palette (`AppColors.swift` — new file)**
- 7 color definitions were duplicated 31 times across 7 files, each with inline RGB literals. A single typo in any copy would create a visual inconsistency.
- Created `AppColors` enum with `accent`, `background(for:)`, `ink(for:)`, `card(for:)`, and `chip(for:)`. All 7 view files now reference `AppColors` instead of inline literals.

**R2 — Extracted shared `UIApplication.keyWindowRootViewController` extension (`AppColors.swift`)**
- Three files (`TexasDailyApp.swift`, `SettingsView.swift`, `BannerAdView.swift`) each contained an identical 5-line root view controller lookup. Extracted to a single `UIApplication` extension.

**R3 — Removed ViewModel layer violation (`TexasAppViewModel.swift`)**
- `refreshTodayFact(haptic:)` accepted a `haptic` parameter and called `Haptics.light()` + `withAnimation` — UI concerns embedded in the ViewModel. The button's action closure already called `Haptics.light()` separately, causing a double-haptic on every tap.
- Removed the `haptic` parameter, `Haptics.light()` call, and `withAnimation` wrapper from the ViewModel. Haptics and animation are now solely the view's responsibility.

**R4 — Deleted dead code (`PaperBackground.swift`)**
- `PaperBackground` was a gradient overlay view that had been removed from all call sites in a prior update but the file itself was never deleted. Removed.

#### Android — Singleton, Lifecycle & Connection Management

**R5 — `FactRepository` converted to thread-safe singleton (`FactRepository.kt`)**
- Was instantiated fresh on every access: `FactRepository(context)` in `TexasViewModel` and `DailyReminderWorker`. Each instance re-parsed the full JSON file from raw resources.
- Converted to private constructor with `companion object getInstance(context)` using double-checked locking. Stores `applicationContext` to prevent Activity leaks. All callers updated.

**R6 — `BillingManager` lifecycle management (`BillingManager.kt`, `TexasViewModel.kt`)**
- `BillingClient` connection was opened on init but never closed — the AIDL service connection leaked when the ViewModel was destroyed.
- Added `endConnection()` method to `BillingManager`. Added `onCleared()` override to `TexasViewModel` that calls `billingManager.endConnection()`.

**R7 — `BillingClient` auto-reconnect (`BillingManager.kt`)**
- `onBillingServiceDisconnected()` was an empty stub. If the Play Store service disconnected mid-session, all subsequent billing operations would silently fail.
- Extracted the `BillingClientStateListener` as a named `connectionListener` field and added `billingClient.startConnection(this)` to the disconnect callback for automatic reconnection.

---

### Android App Icon Fix

**A1 — Adaptive Icon Foreground Rescaled (Android)**
- The adaptive icon foreground (`ic_launcher_foreground.png`) had the "TX Daily" text filling the entire 432x432 canvas. Android's adaptive icon system masks to the inner ~66% safe zone, causing the text to be almost entirely cropped — the home screen showed a blank beige square.
- Regenerated the foreground at 432x432 with content scaled to 288x288 and centered with 72px padding, placing all text within the adaptive icon safe zone.
- Source: iOS `iTunesArtwork@2x.png` (1024x1024).

**A2 — Legacy Launcher Icons Regenerated (Android)**
- Regenerated all density-specific legacy icons from the iOS 1024x1024 source:
  - `mipmap-mdpi`: 48x48
  - `mipmap-hdpi`: 72x72
  - `mipmap-xhdpi`: 96x96
  - `mipmap-xxhdpi`: 144x144
  - `mipmap-xxxhdpi`: 192x192
- Both `ic_launcher.png` and `ic_launcher_round.png` updated at each density.

---

## 2026-03-18

### Code Quality — Android

#### Bug Fix — Unguarded Log Statements in Release Builds (`BannerAdView.kt`)

Mirrored the iOS `FactStore.swift` `#if DEBUG` fix. Two `Log` calls in the AdMob banner ad listener were firing in release builds, leaking internal ad unit IDs and error details to device logs:

- `onAdLoaded()`: `Log.d(TAG, "Banner loaded: $adUnitId")` → wrapped in `if (BuildConfig.DEBUG)`
- `onAdFailedToLoad()`: `Log.w(TAG, "Banner failed: ...")` → wrapped in `if (BuildConfig.DEBUG)`

Both calls are now suppressed in release builds.

---

## 2026-03-17

### Feature — Dynamic Facts in Daily Push Notifications (iOS & Android)

#### iOS (`NotificationManager.swift`)

**`cancelDailyFactNotification()`**
- Updated to fetch all pending notifications and remove any with the `dailyTexasFact_` identifier prefix, replacing the previous single hardcoded identifier `"dailyTexasFact"`.

**`scheduleDailyFactNotification(at:)`**
- Replaced single repeating notification (static body: "Tap to read today's Texas fact.") with a batch of up to 60 one-time daily notifications.
- Each notification is scheduled for a specific calendar date+time (`repeats: false`) across the next 60 days.
- Each notification picks a unique random fact from `FactStore.shared`, passing the previous fact's ID to avoid back-to-back repeats.
- Notification identifiers use the format `dailyTexasFact_0` through `dailyTexasFact_59`.
- Notifications already in the past (e.g., today's slot if the scheduled time has passed) are skipped automatically.
- Existing reschedule triggers in `TexasAppViewModel` (app launch, time change, toggle) keep the 60-day batch current.

#### Android (`DailyReminderWorker.kt`)

- Added `FactRepository` import.
- `showNotification()` now instantiates `FactRepository(context)` and calls `randomFact(emptySet())` at worker execution time (i.e., when the notification fires), replacing the static string resource body.
- Falls back to `R.string.notification_body` if the repository returns null.

---

## 2026-03-14

### Security & Bug Fix Pass

#### Security — HIGH (Android)

**H1 — `android:allowBackup` disabled (`AndroidManifest.xml`)**
- Changed `allowBackup` from `true` → `false`. Prevents app data (DataStore preferences, category selections, notification settings) from being extractable via `adb backup` or Google cloud backup.

**H2 — `BootReceiver` not exported (`AndroidManifest.xml`)**
- Changed `BootReceiver android:exported` from `true` → `false`. An exported receiver without a permission guard can be triggered by any installed app, allowing arbitrary rescheduling of daily reminder WorkManager tasks.

#### Security — MEDIUM (iOS)

**M1 — Production logging guarded (`BannerAdView.swift`, `NotificationManager.swift`, `TexasDailyApp.swift`)**
- Wrapped all `print()` calls with `#if DEBUG` guards:
  - `BannerAdView.swift`: banner loaded log, banner error log (2 call sites)
  - `NotificationManager.swift`: notification scheduling error log (1 call site)
  - `TexasDailyApp.swift`: AdMob start/skip logs (2 call sites)

#### Bug Fixes — MEDIUM (Android)

**B1 — `FactRepository.randomFact()` crash on empty category pool fixed (`FactRepository.kt`)**
- `pool.random()` throws `IndexOutOfBoundsException` when all selected categories are empty or invalid (e.g., stale categories after a content update).
- Changed return type to `TexasFact?` and replaced `random()` with `randomOrNull()`. `TexasViewModel._currentFact` is already `MutableStateFlow<TexasFact?>`, so callers are unaffected.

**B2 — Unsafe `Activity` cast guarded in `SettingsScreen.kt`**
- `context as Activity` would throw `ClassCastException` if the context is not an Activity (unlikely but possible in instrumentation or future refactors).
- Changed to `val activity = context as? Activity ?: return@Button` safe cast with early return.

---

## 2026-03-13 (continued)

### Android — Parity Updates with iOS (UI + Reminder + Ads)

Applied Android counterparts for tonight’s iOS changes.

**`ui/screens/SettingsScreen.kt`**
- Daily reminder now auto-saves and auto-schedules:
  - Toggling reminder ON schedules immediately with the currently selected time.
  - Toggling reminder OFF cancels immediately.
  - Changing time in the picker re-saves/re-schedules in real time when enabled.
- Removed manual reminder save UX:
  - Removed **"Save & Schedule"** button.
  - Removed transient **"Saved & scheduled."** banner.
- Added clear persisted-state copy under the picker:
  - `Reminder is ON. Saved time: HH:MM.`
  - Styled with darker text (`onBackground` at 90% opacity) for stronger readability.

**`ui/screens/MainScreen.kt`**
- Bottom banner strip now explicitly uses `MaterialTheme.colorScheme.background` so it matches the top/background shade in both light and dark mode (no second strip tone).

**`MainActivity.kt`**
- Status bar and navigation bar now track in-app Light/Dark mode immediately.
- Added `enableEdgeToEdge(...)` updates via `SystemBarStyle` inside a Compose `SideEffect` driven by `isDark`.

**`ui/components/BannerAdView.kt`**
- Improved AdMob debug behavior and diagnostics:
  - Uses Google’s Android test banner unit in **debug emulator** builds.
  - Uses production banner unit otherwise.
  - Added log output for banner load success/failure with error code/message.

**`ui/screens/OnboardingScreen.kt`**
- Adjusted text opacity hierarchy to match iOS tuning:
  - Skip text alpha `0.5` → `0.7`.
  - Description text alpha `0.65` → `0.72`.

### Consistent Tan Background Color — iOS & Android

Sampled the app icon background pixel color (`#F5F5DC`, RGB 245/245/220) and applied it uniformly across both platforms. Required three rounds of fixes to fully eliminate all background inconsistencies.

**Root cause:** Multiple overlapping background layers — `PaperBackground` (a `LinearGradient` overlay using `Color(.systemBackground)` at 30–35% opacity), duplicate `backgroundColor` fills in `TodayFactView`, and stale `#F7F5E6` values across several files — were each contributing slightly different shades on top of each other.

**iOS**
- `RootView.swift`: Light-mode `backgroundColor` updated from `#F7F5E6` → `#F5F5DC`.
- `TodayFactView.swift`: Removed `backgroundColor.ignoresSafeArea()` from the main `body` ZStack entirely — `RootView`'s background is now the single source of truth for the main screen background. Both `backgroundColor` properties in the file also updated to `#F5F5DC`.
- `PaperBackground.swift`: Updated both `LinearGradient` layers from `Color(.systemBackground)` / `Color(.secondarySystemBackground)` / `Color.white` / `Color(.systemGray6)` to tan-matched values (`#F5F5DC` → `#ECECD1`).
- `TodayFactView.swift` + `SettingsView.swift`: Removed all three `PaperBackground()` overlay usages (were `opacity(0)` in dark mode and causing a lighter wash in light mode).
- `SettingsView.swift`: `backgroundColor` light-mode value updated to `#F5F5DC`.
- `FactShareCard.swift`: `bgColor` updated to `#F5F5DC`.

**Android**
- `ui/theme/Color.kt`: `LightBackground` updated from `0xFFF7F5E6` → `0xFFF5F5DC`.
- `res/values/colors.xml`: Added `splash_background` color `#F5F5DC`.
- `res/values/themes.xml`: Added `Theme.TexasDaily.Splash` (extends `Theme.SplashScreen`) with `windowSplashScreenBackground = @color/splash_background`.
- `AndroidManifest.xml`: App theme changed to `Theme.TexasDaily.Splash` (sets splash background; transitions to `Theme.TexasDaily` after launch).
- `gradle/libs.versions.toml` + `app/build.gradle.kts`: Added `androidx.core:core-splashscreen:1.0.1` dependency.
- `MainActivity.kt`: Added `installSplashScreen()` call before `super.onCreate()`.

---

## 2026-03-13

### iOS — Onboarding Screen (First-Launch)

**`OnboardingView.swift`** *(new)*
- 4-page swipeable onboarding using `TabView` with `.page` style.
- Pages: Welcome → 700+ Facts → Browse by Category → Daily Reminders.
- Animated capsule dot indicators, "Next" / "Get Started" button, and "Skip" link.
- Styled with accent green and adapts to light/dark mode.

**`TexasAppViewModel.swift`**
- Added `onboardingDoneKey` UserDefaults key.
- Added `onboardingDone: Bool` `@Published` property loaded from UserDefaults on init.
- Added `completeOnboarding()` — sets flag to `true` in memory and UserDefaults.

**`RootView.swift`**
- Checks `viewModel.onboardingDone`; shows `OnboardingView` on first launch, then routes to main app permanently.
- Extracted existing main content into a `mainContent` computed property for clean branching.

### Android — Onboarding Screen (First-Launch)

**`ui/screens/OnboardingScreen.kt`** *(new)*
- 4-page swipeable onboarding flow using `HorizontalPager` (Compose foundation — no new dependency).
- Pages: Welcome → 700+ Facts → Browse by Category → Daily Reminders.
- Animated pill-shaped dot indicators, "Next" / "Get Started" button, and "Skip" link.
- Styled with `AccentGreen` and existing Material3 theme.

**`viewmodel/TexasViewModel.kt`**
- Added `KEY_ONBOARDING_DONE` DataStore key.
- Added `onboardingDone: StateFlow<Boolean>` read from DataStore on init.
- Added `completeOnboarding()` — sets flag to `true` in memory and DataStore; called once by the user.

**`MainActivity.kt`**
- Observes `onboardingDone` state; routes to `OnboardingScreen` on first launch, then to the main app permanently.

### Content — Accuracy Review of 101 New Facts (IDs 601–701, iOS & Android)

All 101 new facts reviewed. 100 of 101 confirmed accurate. One correction applied:

**ID 667 — Bessie Coleman pilot's license (CORRECTED)**
- Old: "...became the first American to earn an international pilot's license." — Misleadingly broad; American men had international licenses before 1921.
- New: "...became the first Black American and first American woman to earn an international pilot's license."
- Applied to both Android and iOS `texas_facts.json`.

### Content — Added 101 Verified Facts (iOS & Android)

- Added 101 new Texas facts across all 11 categories in 11 batches (10 facts per batch, final batch of 1).
- Appended IDs `601` through `701` to both:
  - `iOS/Texas Daily/texas_facts.json`
  - `Android/Project/app/src/main/res/raw/texas_facts.json`
- New facts were distributed across categories as follows:
  - History (+10), Geography (+10), Culture (+10), Sports (+10)
  - Government (+9), Economy (+9), People (+9), Nature (+9), Infrastructure (+9)
  - Science/Tech (+8), Education (+8)
- Post-update validation:
  - Both JSON files valid and synchronized on all added IDs.
  - Each file now contains 700 facts (ID range `1`–`701`, with `379` intentionally absent).

### Content — Fact Removed (iOS & Android)

**ID 379 — Pickup truck decoration fact (REMOVED)**
- Removed from both `texas_facts.json` files (Android & iOS).
- Reason: unverifiable and anecdotal — not a factual statement about Texas history or culture.
- Both files remain valid JSON with 599 facts each.

### Content — Fact Accuracy Corrections (iOS & Android)

All corrections applied to both `iOS/Texas Daily/texas_facts.json` and `Android/Project/app/src/main/res/raw/texas_facts.json`.

**ID 43 — Texas flag height myth (CORRECTED)**
- Old: "The Texas flag is the only state flag allowed to fly at the same height as the U.S. flag on separate poles." — This is a well-documented myth; all 50 state flags may fly at equal height on separate poles.
- New: "Texas law allows the state flag to fly at the same height as the U.S. flag on a separate pole, reflecting its history as an independent republic."

**ID 46 — Desert regions (CORRECTED)**
- Old: "Texas has four major desert regions touching or within its borders." (cited Sonoran, Mojave, Chihuahuan, Great Plains) — The Sonoran and Mojave deserts do not reach Texas.
- New: "The Chihuahuan Desert, the largest desert in North America, extends deep into West Texas."

**ID 57 — First word from the Moon (CORRECTED)**
- Old: "The first word spoken from the Moon to Mission Control in Houston was 'Houston.'" — Factually incorrect; the first words from the surface were Buzz Aldrin's "Contact light."
- New: Rewritten to focus on the iconic Armstrong transmission without the inaccurate "first word" claim.

**ID 419 (iOS only) — Duplicate Moon fact (CORRECTED)**
- Same inaccuracy as ID 57, found in a second entry in the iOS JSON. Rewritten to the accurate transmission framing.

---

## 2026-03-11

### Android — Stability Pass

**`gradle/libs.versions.toml`**
- Synced `agp` from `9.0.0` → `9.0.1` to match CJIS Daily and pick up AGP patch fixes.
- Updated `coroutines` from `1.8.1` → `1.9.0` for Kotlin 2.2.x compatibility.

**`billing/BillingManager.kt`**
- Fixed compile error: `enablePendingPurchases()` (no-arg overload) was removed in Play Billing Library 7.0. Replaced with `enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())`. Added `PendingPurchasesParams` import.

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

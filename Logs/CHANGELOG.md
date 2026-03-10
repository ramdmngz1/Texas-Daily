# Texas Daily — Changelog

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

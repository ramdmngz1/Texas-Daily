# Texas Daily — Testing Checklist

Use this checklist before every TestFlight build and App Store submission.
Check off each item on a **physical device** where noted — the simulator cannot
test purchases, notifications, or haptics reliably.

---

## 1. First Launch / Fresh Install

- [ ] Delete the app completely, then install a clean build
- [ ] App opens without crashing
- [ ] A fact loads immediately on the main screen
- [ ] The consent form appears (if testing with a VPN set to EU/UK region)
- [ ] Banner ad loads after consent is granted
- [ ] No banner ad appears before consent is resolved
- [ ] `✅ Loaded N facts` log appears in console (N should be 600)
- [ ] No unexpected errors in the console on launch

---

## 2. Facts — Core Display

- [ ] Fact text is readable in both light and dark mode
- [ ] Category chip displays correctly above the fact
- [ ] Background info card displays below the fact
- [ ] Source attribution displays at the bottom of the card
- [ ] Facts with a date display a formatted date ("March 2, 1836")
- [ ] Facts without a date show no date field
- [ ] Long facts expand vertically without truncating
- [ ] Scrolling works when fact + background text is long

---

## 3. New Fact Button

- [ ] Tapping "New Random Texas Fact" loads a new fact
- [ ] The new fact is **never** the same as the one just displayed
- [ ] The transition between facts cross-fades smoothly (no jarring cut)
- [ ] Light haptic fires on tap
- [ ] Button press scale animation plays correctly
- [ ] Scroll position resets to the top when a new fact loads

---

## 4. Category Filters

- [ ] Tapping the filter icon opens the filter sheet
- [ ] All categories are listed and sorted alphabetically
- [ ] Tapping a category selects it (checkmark appears)
- [ ] Tapping a selected category deselects it
- [ ] Fact refreshes immediately after toggling a category
- [ ] "Clear Filters" button appears only when at least one category is selected
- [ ] Tapping "Clear Filters" removes all selections and refreshes the fact
- [ ] **Category selections persist after force-quitting and relaunching the app**
- [ ] Selecting all categories produces the same result as no filter
- [ ] Filter sheet dismisses with the X button

---

## 5. Share

- [ ] Share icon appears in the top-right header when a fact is loaded
- [ ] Tapping share opens the iOS share sheet
- [ ] Share text includes the fact
- [ ] Share text includes the source
- [ ] Share text includes "Shared from Texas Daily"
- [ ] Share works via Messages, Mail, Notes, and Copy

---

## 6. Settings — Daily Reminder

- [ ] Settings screen opens via the gear icon
- [ ] Daily Reminder toggle turns the notification on and off
- [ ] Time picker appears when the toggle is on
- [ ] "Save & Schedule" button saves the chosen time
- [ ] "Saved & scheduled." banner appears briefly after saving
- [ ] **Physical device:** notification arrives at the scheduled time
- [ ] **Physical device:** notification body contains a Texas fact
- [ ] Toggling the reminder off cancels the pending notification
- [ ] Saved reminder time persists after force-quitting and relaunching

---

## 7. Settings — Appearance

- [ ] Light Mode renders the limestone/parchment background
- [ ] Dark Mode renders the deep charcoal background
- [ ] Theme change applies immediately without restarting the app
- [ ] Theme applies to both the main screen and the Settings screen simultaneously
- [ ] Theme persists after force-quitting and relaunching

---

## 8. In-App Purchase — Remove Ads *(physical device required)*

- [ ] "Remove Ads" button is visible for users who have not purchased
- [ ] Tapping "Remove Ads" shows the StoreKit purchase sheet
- [ ] Loading spinner stays up for the **full duration** of the purchase flow
- [ ] Spinner disappears only after the purchase resolves (not after 1 second)
- [ ] After a successful purchase:
  - [ ] Banner ad disappears immediately
  - [ ] Support card switches to "Ads are turned off on this device."
  - [ ] No purchase status message is shown (success is self-evident from the UI change)
- [ ] After cancelling the purchase sheet:
  - [ ] "Purchase cancelled." message appears in the support card
  - [ ] Banner ad remains visible
- [ ] After a purchase error:
  - [ ] Error message is shown in red in the support card
- [ ] **Force-quit and relaunch:** paying user sees no banner ad and no flash
- [ ] **No banner flash on launch** for a user who has already purchased

---

## 9. In-App Purchase — Restore Purchases *(physical device required)*

- [ ] "Restore Purchases" button is always visible (even after purchase)
- [ ] Tapping restore shows a spinner for the full duration of the restore
- [ ] If the user has a prior purchase: banner disappears, UI updates to paid state
- [ ] If the user has no prior purchase: "No purchases found to restore." message appears
- [ ] If restore fails: error message appears in red
- [ ] Spinner disappears only after the restore resolves

---

## 10. Ads

- [ ] Banner ad is visible at the bottom for non-paying users
- [ ] Banner ad is hidden for paying users
- [ ] Banner ad is hidden while StoreKit is verifying entitlements on launch
- [ ] No `Missing network(s):` warnings in the console (SKAdNetwork list is complete)
- [ ] Simulator: `✅ Banner loaded` appears in the console

---

## 11. Consent (GDPR / CCPA)

- [ ] Simulate EU region (VPN or simulator region): consent form appears on first launch
- [ ] Ads do not load before consent is resolved
- [ ] Declining consent: ads do not load, app still functions normally
- [ ] Accepting consent: ads load after form is dismissed
- [ ] Consent preference is remembered on subsequent launches (form does not re-appear)

---

## 12. Edge Cases

- [ ] Launch with no internet connection — app loads facts normally (offline-first)
- [ ] Launch with no internet connection — banner ad fails gracefully (no crash)
- [ ] Select a category that has very few facts (1–2) — no crash, no repeat facts
- [ ] Rapid taps on "New Random Texas Fact" — no crash, transitions queue correctly
- [ ] Force-quit mid-purchase — on relaunch, StoreKit state is correctly re-verified
- [ ] Restore purchases with no prior purchase on a fresh Apple ID — handled gracefully

---

## 13. Device & OS Coverage

Test on at least one device from each size class:

- [ ] iPhone SE / 16 mini (small screen, no Dynamic Island)
- [ ] iPhone 16 (mid-size)
- [ ] iPhone 16 Pro Max (large screen, Dynamic Island)
- [ ] iOS 16 (minimum supported — confirm ShareLink compiles and works)
- [ ] iOS 17
- [ ] Latest iOS (26.x in simulator)

---

## 14. Visual QA

- [ ] Light mode — all text is legible, no clipping
- [ ] Dark mode — all text is legible, no clipping
- [ ] Dynamic Type — increase text size in Accessibility settings, confirm nothing clips
- [ ] Landscape orientation — app is usable (or gracefully restricted to portrait)
- [ ] Safe area insets respected on all device sizes (no content behind home indicator)

---

## 15. Pre-Submission Final Check

- [ ] All debug `print()` statements removed from production code:
  - `FactStore.swift` — `✅ Loaded N facts` and decoding error prints
  - `BannerAdView.swift` — `✅ Banner loaded` and `❌ Banner failed` prints
  - `NotificationManager.swift` — `debugPrintPendingRequests()` not called in production
- [ ] Version number and build number incremented in Xcode
- [ ] App icon is set for all required sizes
- [ ] Launch screen displays correctly
- [ ] Privacy policy URL is live and accessible
- [ ] App Store screenshots are current
- [ ] SKAdNetwork list matches Google's latest AdMob list (check console for warnings)
- [ ] No crashes in Xcode's Organizer from previous builds
- [ ] TestFlight beta tested by at least one external user on a physical device

---

## 16. TestFlight Smoke Test *(after uploading, before releasing)*

- [ ] Install from TestFlight (not Xcode) on a physical device
- [ ] App launches without crashing
- [ ] Facts load correctly
- [ ] Purchase flow works end-to-end (use Sandbox Apple ID)
- [ ] Notification schedules and fires correctly
- [ ] No unexpected console errors (connect device to Xcode Console)

---

*Last updated: February 2026*

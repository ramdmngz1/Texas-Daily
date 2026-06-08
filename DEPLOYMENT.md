# Texas Daily — Production Deployment Guide

## Architecture Overview

```
┌───────────────────────────────────────────────��─────────┐
│                    GitHub Repository                       │
│                                                           │
│  Push to main ──► CI Build & Test ──► Deploy to Testing   │
│  Tag ios-v* ───► CI Build ──► App Store Review            │
│  Tag android-v* ► CI Build ──► Play Store Production      │
└─────────────────────────────────────────────────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  TestFlight  │     │ Play Internal│     │   Firebase   │
│  (iOS Beta)  │     │   (Android)  │     │ Crashlytics  │
└──────┬───────┘     └──────┬───────┘     └──────────────┘
       │                    │
       ▼                    ▼
┌──────────────┐     ┌──────────────┐
│  App Store   │     │  Play Store  │
│ (Production) │     │ (Production) │
└──────────────┘     └──────────────┘
```

## Deployment Pipelines

### iOS Pipeline
| Trigger | Action | Destination |
|---------|--------|-------------|
| PR to `main` | Build + Test | CI feedback only |
| Push to `main` (iOS changes) | Build + Test + Archive | TestFlight (internal) |
| Tag `ios-v*` | Build + Archive + Submit | App Store Review |

### Android Pipeline
| Trigger | Action | Destination |
|---------|--------|-------------|
| PR to `main` | Build + Lint + Test | CI feedback only |
| Push to `main` (Android changes) | Build + Bundle | Play Internal Track |
| Tag `android-v*` | Build + Bundle | Play Store Production |

## Required GitHub Secrets

### iOS Secrets
| Secret | Description | How to Generate |
|--------|-------------|-----------------|
| `IOS_CERTIFICATE_P12` | Base64-encoded .p12 distribution cert | Keychain Access → Export → `base64 -i cert.p12` |
| `IOS_CERTIFICATE_PASSWORD` | Password for the .p12 file | Set during export |
| `IOS_PROVISIONING_PROFILE` | Base64-encoded .mobileprovision | `base64 -i profile.mobileprovision` |
| `ASC_KEY_ID` | App Store Connect API Key ID | App Store Connect → Users → Keys |
| `ASC_ISSUER_ID` | API Issuer ID | Same page as above |
| `ASC_PRIVATE_KEY` | Base64-encoded .p8 private key | `base64 -i AuthKey_XXXXXX.p8` |

### Android Secrets
| Secret | Description | How to Generate |
|--------|-------------|-----------------|
| `ANDROID_KEYSTORE_BASE64` | Base64 release keystore | `base64 -i release.keystore` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | Set during keytool creation |
| `ANDROID_KEY_ALIAS` | Key alias name | Set during keytool creation |
| `ANDROID_KEY_PASSWORD` | Key password | Set during keytool creation |
| `PLAY_SERVICE_ACCOUNT_JSON` | Google Play service account JSON | Google Cloud Console → Service Accounts |

## Release Process

### Standard Release (both platforms)
```bash
# 1. Ensure main is stable (all CI green)
# 2. Go to GitHub Actions → "Create Release" → Run workflow
#    - Platform: both
#    - Version: 1.3.0
#    - Release notes: "Added UI component library, security hardening"
# 3. CI automatically:
#    - Bumps version numbers
#    - Creates platform-specific tags
#    - Triggers store deployment workflows
```

### Emergency Hotfix
```bash
# 1. Create hotfix branch from the release tag
git checkout -b hotfix/crash-fix ios-v1.2.0

# 2. Apply fix, push
git push origin hotfix/crash-fix

# 3. PR to main, merge, then manually trigger release workflow
#    with the next patch version (e.g., 1.2.1)
```

## Monitoring & Observability

### Recommended Stack (No Backend Required)

| Tool | Purpose | Cost |
|------|---------|------|
| **Firebase Crashlytics** | Crash reporting, ANR detection | Free |
| **Firebase Analytics** | User behavior, retention, funnel | Free |
| **App Store Connect Analytics** | Download, revenue, retention | Free (included) |
| **Google Play Console Vitals** | ANR rate, crash rate, startup time | Free (included) |

### Firebase Setup Steps

1. Create Firebase project at console.firebase.google.com
2. **iOS:** Download `GoogleService-Info.plist`, add to Xcode target
3. **Android:** Download `google-services.json`, place in `app/`
4. Add SDK dependencies:
   - iOS: Add `firebase-ios-sdk` SPM package
   - Android: Add `com.google.firebase:firebase-crashlytics-ktx` to build.gradle
5. Add Crashlytics Gradle plugin to Android build

### Key Metrics to Monitor

| Metric | Threshold | Action |
|--------|-----------|--------|
| Crash-free rate | < 99.5% | Investigate immediately |
| ANR rate (Android) | > 0.5% | Profile main thread |
| App startup time | > 2s cold start | Optimize init path |
| Daily active users | Trending down | Check store reviews |
| Ad fill rate | < 80% | Check AdMob configuration |

## Reliability Measures

### Already Implemented
- [x] `goAsync()` for BroadcastReceiver (prevents ANR on boot)
- [x] Exponential backoff on billing reconnect
- [x] Graceful degradation: app works offline (bundled data)
- [x] StoreKit2 JWS verification (tamper-proof entitlements)
- [x] Network security config blocks cleartext
- [x] Debug logging stripped from release builds

### Recommended Additions
- [ ] Add `firebase-crashlytics` for real-time crash alerts
- [ ] Configure ProGuard mapping upload for symbolicated crash reports
- [ ] Add dSYM upload step to iOS CI for Crashlytics symbolication
- [ ] Set up Slack/email alerts for crash-free rate drops
- [ ] Add staged rollouts on Play Store (10% → 50% → 100%)

## Scaling Considerations

This app scales inherently because:
- **No backend server** — all data is bundled locally
- **No API calls** — facts are read from embedded JSON
- **Ad serving handled by Google** — their CDN scales infinitely
- **Billing handled by Apple/Google** — their infrastructure handles peak load

The only scaling concern is **content updates** (adding new facts):
- Currently requires a new app binary for each content update
- Future enhancement: fetch new facts from a lightweight CDN (Cloudflare KV, S3 + CloudFront)
- This would require adding a content sync mechanism with offline fallback

## Downtime Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| App Store rejection | Medium | High | TestFlight beta testing, review guidelines compliance |
| Google Play suspension | Low | Critical | Staged rollouts, policy compliance checks |
| AdMob account ban | Low | Medium (revenue loss) | Test ads in debug, monitor invalid traffic |
| Signing cert expiration | Medium | High (can't release) | Calendar reminder 30 days before expiry |
| Dependency CVE | Low | Medium | Weekly health-check workflow |

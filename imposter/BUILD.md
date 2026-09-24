# Build Instructions for Imposter

## Quick Start

```bash
cd imposter
npm install
npx expo start
```

## Development Build (Required for Native Modules)

Since this app uses `expo-av`, `expo-haptics`, and `react-native-reanimated`, you need a development build to test on physical devices:

```bash
# iOS
npx expo run:ios

# Android
npx expo run:android
```

Or use EAS for cloud builds:
```bash
eas build --profile development --platform all
```

## EAS Build Setup

### 1. Login to Expo
```bash
eas login
```

### 2. Configure Project
```bash
eas build:configure
```
This creates `eas.json` and prompts for project settings.

### 3. Build Profiles

#### Development (for testing on devices)
```bash
eas build --profile development --platform all
```
- Creates installable `.apk` (Android) and `.app` (iOS Simulator)
- Includes dev client for live reload

#### Preview (Internal Distribution)
```bash
eas build --profile preview --platform all
```
- Creates `.apk` for Android sideloading
- Creates internal iOS build for TestFlight/internal distribution

#### Production (Store Submission)
```bash
# iOS - creates .ipa for TestFlight/App Store
eas build --profile production --platform ios

# Android - creates .aab for Play Store
eas build --profile production --platform android

# Both platforms
eas build --profile production --platform all
```

### 4. Local Builds (Alternative)

If you have Xcode (macOS) and Android Studio installed:

```bash
# iOS local build
eas build --profile production --platform ios --local

# Android local build
eas build --profile production --platform android --local
```

## Submitting to App Stores

### iOS App Store / TestFlight
```bash
eas submit --platform ios
```
Prompts for:
- Apple ID / App Store Connect credentials
- Build to submit (latest or specific)
- Release type (TestFlight, App Store, etc.)

### Google Play Store
```bash
eas submit --platform android
```
Prompts for:
- Service account JSON / Play Console credentials
- Build to submit
- Track (internal, closed, open, production)

## Bundle Identifier / Package Name

Current config:
- iOS: `com.imposterapp.game`
- Android: `com.imposterapp.game`

**Change before first production build:**
Edit `app.config.js`:
```javascript
ios: { bundleIdentifier: "com.yourdomain.imposter" },
android: { package: "com.yourdomain.imposter" },
```

## App Icons & Splash Screen

Replace placeholder assets in `assets/`:
| File | Size | Purpose |
|------|------|---------|
| `icon.png` | 1024×1024 | App Store / Home screen icon |
| `splash.png` | 1024×1024 | Launch screen |
| `adaptive-icon.png` | 1024×1024 | Android adaptive icon foreground |
| `favicon.png` | 512×512 | Web favicon |
| `sounds/*.mp3` | ~1-10KB | Sound effects (flip, timer, vote, win, lose) |

Generate with:
```bash
# Using Expo's icon generator
npx expo-icon-generator assets/icon.png

# Or use Figma/Sketch with 1024×1024 artboard
```

## Environment Variables

Create `.env` for local development:
```env
EXPO_PUBLIC_API_URL=https://api.example.com
```

For EAS builds, set secrets:
```bash
eas secret:create --scope project --name API_KEY --value "your-key"
```

## Troubleshooting

### "No matching provisioning profiles found"
- Ensure bundle identifier matches Apple Developer account
- Run `eas build --profile production --platform ios` to trigger provisioning

### "Keystore not found" (Android)
- EAS generates keystore automatically for preview/production
- For local builds, configure `android/app/build.gradle` signing config

### Metro bundler issues
```bash
npx expo start --clear
```

### TypeScript errors
```bash
npm run typecheck
```

### Dependency conflicts
```bash
npx expo install --fix
npm install --legacy-peer-deps
```

## CI/CD with GitHub Actions

Example workflow (`.github/workflows/build.yml`):
```yaml
name: Build & Submit
on:
  push:
    tags: ['v*']
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci
      - run: npm run typecheck
      - uses: expo/expo-github-action@v8
        with:
          eas-version: latest
          token: ${{ secrets.EXPO_TOKEN }}
      - run: eas build --profile production --platform all --non-interactive
      - run: eas submit --platform all --non-interactive
```

## Versioning

Update version in `app.config.js`:
```javascript
version: "1.0.0",
```

Or use EAS auto-increment:
```json
// eas.json
"production": { "autoIncrement": true }
```

## Testing Checklist

Before submitting:
- [ ] Test on iOS Simulator
- [ ] Test on Android Emulator
- [ ] Test on physical iOS device (via TestFlight)
- [ ] Test on physical Android device (via .apk)
- [ ] Verify all animations run at 60fps
- [ ] Test haptic feedback
- [ ] Test sound effects
- [ ] Test persistence (close/open app mid-game)
- [ ] Test custom categories/words
- [ ] Verify safe areas on notched devices
- [ ] Test landscape/portrait (portrait only for this app)
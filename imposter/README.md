# Imposter

A social deduction party game (Spyfall/Among Us style) built with React Native, Expo, and Reanimated.

## Features

- **Setup Screen**: Configure players (3-12), imposters (1-3), category, and timer length
- **Pass-and-Play Reveal**: 3D card flip animation reveals secret word or "You're the Imposter" + category hint
- **Discussion Timer**: Animated countdown ring with pause/resume, haptic feedback on last 10 seconds
- **Voting Screen**: Tap-to-vote UI with live tally, dramatic staggered reveal animations
- **Results & Scoring**: Reveal imposters, win/loss state, running scores persisted across rounds
- **Word Bank**: 200 words across 10 built-in categories + custom categories/words
- **Customization**: Create custom categories with neon colors, add/remove words
- **Dark Theme**: Moody dark UI with 10 neon accent colors per category
- **Haptics & Sound**: Expo Haptics + Expo AV for tactile/audio feedback
- **Persistence**: AsyncStorage for settings, categories, words, scores, and game state

## Tech Stack

- **React Native** with **Expo** (managed workflow, SDK 57)
- **Expo Router** for file-based navigation
- **Reanimated 3** + **Gesture Handler** for 60fps UI-thread animations
- **Zustand** for lightweight state management with AsyncStorage persistence
- **Space Grotesk** font for headings via `@expo-google-fonts/space-grotesk`
- **Expo AV** for sound effects, **Expo Haptics** for haptic feedback
- **TypeScript** with strict mode

## Project Structure

```
imposter/
├── app/                          # Expo Router screens
│   ├── _layout.tsx              # Root layout, font loading, stack navigator
│   ├── index.tsx                # Setup screen (home)
│   ├── setup/
│   │   ├── player-names.tsx     # Optional custom player names
│   │   └── settings.tsx         # Sound/Haptic/Accessibility toggles
│   ├── reveal/
│   │   ├── card.tsx             # Card flip animation screen
│   │   └── handoff.tsx          # "Pass to Player X" transition
│   ├── discussion/
│   │   └── timer.tsx            # Animated timer ring
│   ├── voting/
│   │   └── index.tsx            # Tap-to-vote with live tally
│   ├── results/
│   │   └── index.tsx            # Reveal + scores + End Party
│   └── manage/
│       ├── categories.tsx       # Category CRUD + neon picker
│       └── words.tsx            # Word management per category
├── components/
│   ├── ui/                      # Reusable UI components
│   │   ├── FlipCard.tsx         # 3D flip card (Reanimated)
│   │   ├── TimerRing.tsx        # Circular progress ring (Reanimated)
│   │   ├── VoteButton.tsx       # Pressable vote button with spring
│   │   ├── NeonButton.tsx       # Themed button with glow
│   │   ├── ScoreRow.tsx         # Animated score display
│   │   ├── NeonColorPicker.tsx  # 10-color palette grid
│   │   └── InputField.tsx       # Styled text input
│   ├── layout/
│   │   ├── SafeContainer.tsx    # SafeAreaView + KeyboardAvoiding
│   │   └── ScreenHeader.tsx     # Title + back/close actions
│   └── animations/
│       ├── useCardFlip.ts       # useSharedValue + withSpring
│       ├── useStaggeredReveal.ts # Staggered entrance animations
│       └── useTimerRing.ts      # Ring progress + color shift
├── store/
│   ├── gameStore.ts             # Active game state
│   ├── settingsStore.ts         # User preferences
│   ├── categoryStore.ts         # Categories + custom words
│   └── scoreStore.ts            # Session scores + history
├── data/                        # Built-in categories & neon palette
├── hooks/                       # Custom hooks
├── utils/                       # Scoring, persistence, validation
├── constants/                   # Theme, dimensions, game constants
├── types/                       # TypeScript interfaces
└── assets/                      # Icons, splash, sounds, fonts
```

## Getting Started

### Prerequisites

- Node.js 18+
- npm or bun
- Expo CLI: `npm install -g @expo/cli`
- EAS CLI: `npm install -g eas-cli`

### Installation

```bash
cd imposter
npm install
```

### Development

```bash
# Start Expo dev server
npx expo start

# Run on iOS Simulator
npx expo start --ios

# Run on Android Emulator
npx expo start --android

# Run in browser
npx expo start --web
```

### Type Checking

```bash
npm run typecheck
```

### Linting

```bash
npm run lint
```

## EAS Build Configuration

### First Time Setup

```bash
eas login
eas build:configure
```

This creates `eas.json` and links your project to EAS.

### Build Profiles

| Profile | Purpose | Output |
|---------|---------|--------|
| `development` | Development client for testing | `.apk` / `.app` |
| `preview` | Internal distribution/testing | `.apk` (Android) / internal iOS |
| `production` | App Store / Play Store submission | `.ipa` / `.aab` |

### Build Commands

```bash
# Preview builds (internal distribution)
eas build --profile preview --platform all

# Production iOS build (.ipa for TestFlight)
eas build --profile production --platform ios

# Production Android build (.aab for Play Store)
eas build --profile production --platform android

# Local builds (requires Xcode/Android Studio)
eas build --profile production --platform ios --local
eas build --profile production --platform android --local
```

### Submit to Stores

```bash
# iOS App Store
eas submit --platform ios

# Google Play Store
eas submit --platform android
```

## Game Rules

### Setup
1. Select player count (3-12)
2. Select imposter count (1-3)
3. Choose category (Movies, Food, Celebrities, Animals, Places, Books, Brands, Sports, Music, Historical Figures, or Custom)
4. Set discussion timer (30-300 seconds)
5. Optionally customize player names
6. Press "Start Party Game"

### Reveal Phase
- Each player taps the card to reveal their role
- Civilians see the secret word + category hint
- Imposters see only the category hint
- Pass phone to next player

### Discussion Phase
- Timer counts down (pause/resume available)
- Haptic warning at 10 seconds
- Discuss who might be the imposter

### Voting Phase
- Tap a player to vote for them
- Live vote tally shown
- Press "Reveal Votes" when all have voted

### Scoring
| Role | Win Round | Correct Vote Bonus |
|------|-----------|-------------------|
| Imposter | +2 pts | — |
| Civilian | +1 pt | +0.5 pts |

- Scores accumulate across rounds until "End Party" is pressed
- Game history saved automatically

## Customization

### Categories
- 10 built-in categories (20 words each = 200 words)
- Create custom categories with name, hint prefix, and neon color
- 10 neon colors available for custom categories

### Words
- Add custom words to any category
- Remove custom words (built-in words cannot be removed)
- Words persist across app restarts

### Settings
- Toggle sound effects (off by default, prompt on first launch)
- Toggle haptic feedback (on by default)
- Toggle accessibility mode (future VoiceOver/TalkBack support)

## Assets

Replace placeholder assets in `assets/`:
- `icon.png` - 1024×1024 app icon
- `splash.png` - 1024×1024 splash screen
- `adaptive-icon.png` - 1024×1024 Android adaptive icon
- `favicon.png` - Web favicon
- `sounds/` - Replace placeholder MP3s with real SFX

## Configuration Files

- `app.json` / `app.config.js` - Expo config
- `eas.json` - EAS Build profiles
- `tsconfig.json` - TypeScript config
- `package.json` - Dependencies & scripts

## License

MIT
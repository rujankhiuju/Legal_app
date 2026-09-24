import React from 'react';
import { View, ScrollView, Text, StyleSheet, Pressable, Alert } from 'react-native';
import { router } from 'expo-router';
import { SafeContainer } from '../components/layout/SafeContainer';
import { ScreenHeader } from '../components/layout/ScreenHeader';
import { NeonButton } from '../components/ui/NeonButton';
import { InputField } from '../components/ui/InputField';
import { NeonColorPicker } from '../components/ui/NeonColorPicker';
import { useGameStore } from '../store/gameStore';
import { useCategoryStore } from '../store/categoryStore';
import { useSettingsStore } from '../store/settingsStore';
import { useGameFlow } from '../hooks/useGameFlow';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY } from '../constants/theme';
import { LAYOUT } from '../constants/dimensions';
import { GAME_CONSTANTS } from '../constants/game';

export default function SetupScreen() {
  const {
    settings,
    setSettings,
    resetSession,
  } = useGameStore();

  const { categories, getNeonPalette } = useCategoryStore();
  const { firstLaunch } = useSettingsStore();
  const { startGame } = useGameFlow();

  const handleStartGame = () => {
    const result = startGame();
    if (result.valid) {
      router.push('/reveal/card');
    } else {
      Alert.alert('Invalid Settings', result.errors.join('\n'));
    }
  };

  const handlePlayerCountChange = (value: string) => {
    const count = parseInt(value, 10) || GAME_CONSTANTS.MIN_PLAYERS;
    const clamped = Math.max(GAME_CONSTANTS.MIN_PLAYERS, Math.min(GAME_CONSTANTS.MAX_PLAYERS, count));
    setSettings({ playerCount: clamped });
  };

  const handleImposterCountChange = (value: string) => {
    const count = parseInt(value, 10) || GAME_CONSTANTS.MIN_IMPOSTERS;
    const maxImposters = Math.min(GAME_CONSTANTS.MAX_IMPOSTERS, settings.playerCount - 1);
    const clamped = Math.max(GAME_CONSTANTS.MIN_IMPOSTERS, Math.min(maxImposters, count));
    setSettings({ imposterCount: clamped });
  };

  const handleTimerChange = (value: string) => {
    const seconds = parseInt(value, 10) || GAME_CONSTANTS.MIN_TIMER_SECONDS;
    const clamped = Math.max(GAME_CONSTANTS.MIN_TIMER_SECONDS, Math.min(GAME_CONSTANTS.MAX_TIMER_SECONDS, seconds));
    setSettings({ roundTimerSeconds: clamped });
  };

  const selectedCategory = categories.find(c => c.id === settings.categoryId) || categories[0];

  return (
    <SafeContainer avoidKeyboard={true}>
      <View style={styles.scrollContainer}>
        <ScreenHeader title="IMPOSTER" neonColor={selectedCategory.neonColor} />
        
        <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>GAME SETUP</Text>
            
            <View style={styles.inputRow}>
              <InputField
                label="Players"
                value={settings.playerCount.toString()}
                onChangeText={handlePlayerCountChange}
                keyboardType="numeric"
                neonColor={selectedCategory.neonColor}
                placeholder={`${GAME_CONSTANTS.MIN_PLAYERS}–${GAME_CONSTANTS.MAX_PLAYERS}`}
                style={styles.numberInput}
              />
              <InputField
                label="Imposters"
                value={settings.imposterCount.toString()}
                onChangeText={handleImposterCountChange}
                keyboardType="numeric"
                neonColor={selectedCategory.neonColor}
                placeholder={`1–${Math.min(GAME_CONSTANTS.MAX_IMPOSTERS, settings.playerCount - 1)}`}
                style={styles.numberInput}
              />
            </View>

            <InputField
              label="Discussion Timer (seconds)"
              value={settings.roundTimerSeconds.toString()}
              onChangeText={handleTimerChange}
              keyboardType="numeric"
              neonColor={selectedCategory.neonColor}
              placeholder={`${GAME_CONSTANTS.MIN_TIMER_SECONDS}–${GAME_CONSTANTS.MAX_TIMER_SECONDS}`}
            />
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>CATEGORY</Text>
            <View style={styles.categoryGrid}>
              {categories.map((category) => (
                <Pressable
                  key={category.id}
                  onPress={() => setSettings({ categoryId: category.id })}
                  style={[
                    styles.categoryCard,
                    settings.categoryId === category.id && styles.categoryCardSelected,
                    { borderColor: category.neonColor },
                  ]}
                  hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                >
                  <View style={[styles.categoryIcon, { backgroundColor: category.neonColor }]} />
                  <Text style={[
                    styles.categoryName,
                    settings.categoryId === category.id && { color: category.neonColor },
                  ]}>
                    {category.name}
                  </Text>
                  {category.isCustom && (
                    <Text style={styles.customBadge}>CUSTOM</Text>
                  )}
                </Pressable>
              ))}
            </View>

            <NeonButton
              title="Manage Categories"
              variant="secondary"
              onPress={() => router.push('/manage/categories')}
              neonColor={selectedCategory.neonColor}
              style={styles.manageButton}
            />
          </View>

          <View style={styles.section}>
            <NeonButton
              title={firstLaunch ? "Start Party Game" : "New Game"}
              variant="primary"
              onPress={handleStartGame}
              neonColor={selectedCategory.neonColor}
              fullWidth
              style={styles.startButton}
            />
          </View>
        </ScrollView>

        <View style={styles.footer}>
          <NeonButton
            title="Settings"
            variant="ghost"
            onPress={() => router.push('/setup/settings')}
            neonColor={selectedCategory.neonColor}
            style={styles.settingsButton}
          />
        </View>
      </View>
    </SafeContainer>
  );
}

const styles = StyleSheet.create({
  scrollContainer: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: SPACING.lg,
    paddingBottom: SPACING.xxl,
    flexGrow: 1,
  },
  section: {
    marginBottom: SPACING.xl,
  },
  sectionTitle: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.sm,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 2,
    marginBottom: SPACING.md,
  },
  inputRow: {
    flexDirection: 'row',
    gap: SPACING.md,
  },
  numberInput: {
    flex: 1,
  },
  categoryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: SPACING.md,
    justifyContent: 'center',
  },
  categoryCard: {
    width: (LAYOUT.screenWidth - SPACING.lg * 2 - SPACING.md * 4) / 5,
    aspectRatio: 1,
    borderRadius: RADIUS.lg,
    borderWidth: 2,
    borderColor: COLORS.border,
    backgroundColor: COLORS.surface,
    alignItems: 'center',
    justifyContent: 'center',
    padding: SPACING.md,
  },
  categoryCardSelected: {
    borderWidth: 3,
    backgroundColor: COLORS.surfaceElevated,
  },
  categoryIcon: {
    width: 40,
    height: 40,
    borderRadius: RADIUS.full,
    marginBottom: SPACING.sm,
  },
  categoryName: {
    fontFamily: TYPOGRAPHY.fontFamily.bodyMedium,
    fontSize: TYPOGRAPHY.fontSize.xs,
    color: COLORS.textSecondary,
    textAlign: 'center',
  },
  customBadge: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.xs,
    color: COLORS.textMuted,
    marginTop: SPACING.xs,
  },
  manageButton: {
    marginTop: SPACING.md,
  },
  startButton: {
    marginTop: SPACING.lg,
    paddingVertical: SPACING.lg,
  },
  footer: {
    paddingHorizontal: SPACING.lg,
    paddingVertical: SPACING.lg,
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
  },
  settingsButton: {
    width: '100%',
  },
});
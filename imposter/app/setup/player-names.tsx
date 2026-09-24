import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, TextInput } from 'react-native';
import { router } from 'expo-router';
import { SafeContainer } from '../../components/layout/SafeContainer';
import { ScreenHeader } from '../../components/layout/ScreenHeader';
import { NeonButton } from '../../components/ui/NeonButton';
import { InputField } from '../../components/ui/InputField';
import { useGameStore } from '../../store/gameStore';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY } from '../../constants/theme';
import { GAME_CONSTANTS } from '../../constants/game';

export default function PlayerNamesScreen() {
  const { settings, setSettings, players } = useGameStore();
  const [names, setNames] = useState<string[]>([]);

  useEffect(() => {
    const initialNames = players.slice(0, settings.playerCount).map(p => p.name);
    setNames(initialNames);
  }, [settings.playerCount, players]);

  const handleNameChange = (index: number, name: string) => {
    const newNames = [...names];
    newNames[index] = name.slice(0, GAME_CONSTANTS.MAX_CUSTOM_NAME_LENGTH);
    setNames(newNames);
  };

  const handleSave = () => {
    const updatedPlayers = players.map((p, i) => ({
      ...p,
      name: names[i]?.trim() || `Player ${i + 1}`,
    }));
    useGameStore.setState({ players: updatedPlayers });
    router.back();
  };

  const handleSkip = () => {
    router.back();
  };

  return (
    <SafeContainer avoidKeyboard={true}>
      <View style={styles.container}>
        <ScreenHeader 
          title="PLAYER NAMES" 
          neonColor={COLORS.neonCyan}
          onBack={handleSkip}
          showBack
        />

        <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
          <View style={styles.header}>
            <Text style={styles.headerTitle}>Customize Names (Optional)</Text>
            <Text style={styles.headerSubtitle}>
              Tap to edit, or skip to use defaults
            </Text>
          </View>

          <View style={styles.namesList}>
            {Array.from({ length: settings.playerCount }, (_, i) => (
              <View key={i} style={styles.nameItem}>
                <Text style={styles.playerNumber}>
                  PLAYER {i + 1}
                </Text>
                <InputField
                  value={names[i] || `Player ${i + 1}`}
                  onChangeText={(text) => handleNameChange(i, text)}
                  placeholder={`Player ${i + 1}`}
                  neonColor={COLORS.neonCyan}
                  maxLength={GAME_CONSTANTS.MAX_CUSTOM_NAME_LENGTH}
                  style={styles.nameInput}
                />
              </View>
            ))}
          </View>
        </ScrollView>

        <View style={styles.footer}>
          <NeonButton
            title="Skip"
            variant="ghost"
            onPress={handleSkip}
            neonColor={COLORS.textMuted}
            style={styles.footerButton}
          />
          <NeonButton
            title="Save & Continue"
            variant="primary"
            onPress={handleSave}
            neonColor={COLORS.neonCyan}
            style={styles.footerButton}
          />
        </View>
      </View>
    </SafeContainer>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: SPACING.lg,
    paddingBottom: SPACING.xxl,
    flexGrow: 1,
  },
  header: {
    alignItems: 'center',
    marginBottom: SPACING.xl,
  },
  headerTitle: {
    fontFamily: TYPOGRAPHY.fontFamily.headingMedium,
    fontSize: TYPOGRAPHY.fontSize.lg,
    color: COLORS.textPrimary,
    textAlign: 'center',
    marginBottom: SPACING.xs,
  },
  headerSubtitle: {
    fontFamily: TYPOGRAPHY.fontFamily.body,
    fontSize: TYPOGRAPHY.fontSize.md,
    color: COLORS.textSecondary,
    textAlign: 'center',
  },
  namesList: {
    gap: SPACING.md,
  },
  nameItem: {
    gap: SPACING.sm,
  },
  playerNumber: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.xs,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 2,
  },
  nameInput: {
    // InputField handles its own styling
  },
  footer: {
    paddingHorizontal: SPACING.lg,
    paddingVertical: SPACING.lg,
    gap: SPACING.md,
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
  },
  footerButton: {
    width: '100%',
  },
});
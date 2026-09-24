import React from 'react';
import { View, Text, StyleSheet, ScrollView, Switch } from 'react-native';
import { router } from 'expo-router';
import { SafeContainer } from '../../components/layout/SafeContainer';
import { ScreenHeader } from '../../components/layout/ScreenHeader';
import { NeonButton } from '../../components/ui/NeonButton';
import { useSettingsStore } from '../../store/settingsStore';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY } from '../../constants/theme';

export default function SettingsScreen() {
  const { 
    enableSounds, 
    enableHaptics, 
    enableAccessibility, 
    firstLaunch,
    setEnableSounds, 
    setEnableHaptics, 
    setEnableAccessibility,
    setFirstLaunch,
    resetSettings,
  } = useSettingsStore();

  const handleReset = () => {
    resetSettings();
  };

  return (
    <SafeContainer avoidKeyboard={false}>
      <View style={styles.container}>
        <ScreenHeader 
          title="SETTINGS" 
          neonColor={COLORS.neonViolet}
          onBack={() => router.back()}
          showBack
        />

        <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>GAMEPLAY</Text>
            
            <View style={styles.settingRow}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingLabel}>Sound Effects</Text>
                <Text style={styles.settingDescription}>
                  Play sounds for card flips, votes, and round results
                </Text>
              </View>
              <Switch
                value={enableSounds}
                onValueChange={setEnableSounds}
                thumbColor={enableSounds ? COLORS.neonViolet : COLORS.textMuted}
                trackColor={{ false: COLORS.border, true: `${COLORS.neonViolet}66` }}
              />
            </View>

            <View style={styles.settingRow}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingLabel}>Haptic Feedback</Text>
                <Text style={styles.settingDescription}>
                  Vibration on card reveal, vote, and timer warnings
                </Text>
              </View>
              <Switch
                value={enableHaptics}
                onValueChange={setEnableHaptics}
                thumbColor={enableHaptics ? COLORS.neonViolet : COLORS.textMuted}
                trackColor={{ false: COLORS.border, true: `${COLORS.neonViolet}66` }}
              />
            </View>
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>ACCESSIBILITY</Text>
            
            <View style={styles.settingRow}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingLabel}>Screen Reader Support</Text>
                <Text style={styles.settingDescription}>
                  Enable VoiceOver/TalkBack optimizations (experimental)
                </Text>
              </View>
              <Switch
                value={enableAccessibility}
                onValueChange={setEnableAccessibility}
                thumbColor={enableAccessibility ? COLORS.neonViolet : COLORS.textMuted}
                trackColor={{ false: COLORS.border, true: `${COLORS.neonViolet}66` }}
              />
            </View>
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>DATA</Text>
            
            <NeonButton
              title="Reset All Settings"
              variant="danger"
              onPress={handleReset}
              neonColor={COLORS.error}
              fullWidth
              style={styles.resetButton}
            />
          </View>

          <View style={styles.versionInfo}>
            <Text style={styles.versionText}>Imposter v1.0.0</Text>
            <Text style={styles.versionText}>Built with Expo & React Native</Text>
          </View>
        </ScrollView>
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
  section: {
    marginBottom: SPACING.xl,
    padding: SPACING.lg,
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.xl,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  sectionTitle: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.sm,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 2,
    marginBottom: SPACING.lg,
  },
  settingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: SPACING.lg,
  },
  settingRowLast: {
    marginBottom: 0,
  },
  settingInfo: {
    flex: 1,
  },
  settingLabel: {
    fontFamily: TYPOGRAPHY.fontFamily.bodyMedium,
    fontSize: TYPOGRAPHY.fontSize.md,
    color: COLORS.textPrimary,
    marginBottom: SPACING.xs,
  },
  settingDescription: {
    fontFamily: TYPOGRAPHY.fontFamily.body,
    fontSize: TYPOGRAPHY.fontSize.sm,
    color: COLORS.textSecondary,
  },
  resetButton: {
    marginTop: SPACING.md,
  },
  versionInfo: {
    alignItems: 'center',
    paddingTop: SPACING.xl,
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
    marginTop: SPACING.xl,
  },
  versionText: {
    fontFamily: TYPOGRAPHY.fontFamily.body,
    fontSize: TYPOGRAPHY.fontSize.xs,
    color: COLORS.textMuted,
    marginBottom: SPACING.xs,
  },
});
import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { router } from 'expo-router';
import { SafeContainer } from '../../components/layout/SafeContainer';
import { NeonButton } from '../../components/ui/NeonButton';
import { TimerRing } from '../../components/ui/TimerRing';
import { useGameStore } from '../../store/gameStore';
import { useSettingsStore } from '../../store/settingsStore';
import { useHaptics } from '../../hooks/useHaptics';
import { useSound } from '../../hooks/useSound';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY } from '../../constants/theme';
import { GAME_CONSTANTS } from '../../constants/game';

export default function DiscussionTimerScreen() {
  const { settings, players, secretWord, phase, setPhase } = useGameStore();
  const { enableHaptics, enableSounds } = useSettingsStore();
  const { trigger: haptic } = useHaptics();
  const { play } = useSound();

  const [timeRemaining, setTimeRemaining] = useState(settings.roundTimerSeconds);
  const [isPaused, setIsPaused] = useState(false);
  const [warningPlayed, setWarningPlayed] = useState(false);

  useEffect(() => {
    if (phase !== 'discussion') return;

    const interval = setInterval(() => {
      if (!isPaused) {
        setTimeRemaining((prev) => {
          const next = prev - 1;
          
          if (next <= GAME_CONSTANTS.TIMER_WARNING_THRESHOLD && next > 0 && !warningPlayed) {
            setWarningPlayed(true);
            if (enableHaptics) haptic('warning');
            if (enableSounds) play('timerWarning');
          }
          
          if (next <= 0) {
            if (enableHaptics) haptic('heavy');
            if (enableSounds) play('reveal');
            setPhase('voting');
            return 0;
          }
          
          return next;
        });
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [phase, isPaused, enableHaptics, enableSounds, haptic, play, setPhase]);

  useEffect(() => {
    setTimeRemaining(settings.roundTimerSeconds);
    setIsPaused(false);
    setWarningPlayed(false);
  }, [settings.roundTimerSeconds, phase]);

  const progress = 1 - timeRemaining / settings.roundTimerSeconds;

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <SafeContainer avoidKeyboard={false}>
      <View style={styles.container}>
        <View style={styles.header}>
          <Text style={styles.phaseLabel}>DISCUSSION PHASE</Text>
          <Text style={styles.wordHint}>
            Word: {secretWord} · {players.filter(p => p.role === 'imposter').length} Imposter{players.filter(p => p.role === 'imposter').length > 1 ? 's' : ''}
          </Text>
        </View>

        <TimerRing
          duration={settings.roundTimerSeconds}
          progress={progress}
          isPaused={isPaused}
          size={280}
          strokeWidth={12}
        />

        <View style={styles.controls}>
          <TouchableOpacity
            onPress={() => {
              setIsPaused(!isPaused);
              haptic('light');
            }}
            style={[
              styles.controlButton,
              isPaused && styles.controlButtonActive,
            ]}
            hitSlop={{ top: 16, bottom: 16, left: 24, right: 24 }}
          >
            <Text style={[
              styles.controlButtonText,
              { color: isPaused ? COLORS.neonAmber : COLORS.textSecondary },
            ]}>
              {isPaused ? 'RESUME' : 'PAUSE'}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => {
              setPhase('voting');
              haptic('heavy');
              play('reveal');
            }}
            style={styles.controlButton}
            hitSlop={{ top: 16, bottom: 16, left: 24, right: 24 }}
          >
            <Text style={styles.controlButtonText}>SKIP</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.instruction}>
          <Text style={styles.instructionText}>
            Discuss who the Imposter might be. Vote when ready.
          </Text>
        </View>
      </View>
    </SafeContainer>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingHorizontal: SPACING.xl,
    justifyContent: 'center',
  },
  header: {
    alignItems: 'center',
    marginBottom: SPACING.xl,
  },
  phaseLabel: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.sm,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 3,
    marginBottom: SPACING.sm,
  },
  wordHint: {
    fontFamily: TYPOGRAPHY.fontFamily.bodyMedium,
    fontSize: TYPOGRAPHY.fontSize.sm,
    color: COLORS.textSecondary,
    textAlign: 'center',
  },
  controls: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: SPACING.lg,
    marginTop: SPACING.xl,
    marginBottom: SPACING.xl,
  },
  controlButton: {
    paddingHorizontal: SPACING.xl,
    paddingVertical: SPACING.md,
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.full,
    borderWidth: 1,
    borderColor: COLORS.border,
    minWidth: 120,
    alignItems: 'center',
  },
  controlButtonActive: {
    borderColor: COLORS.neonAmber,
    backgroundColor: `${COLORS.neonAmber}22`,
  },
  controlButtonText: {
    fontFamily: TYPOGRAPHY.fontFamily.headingMedium,
    fontSize: TYPOGRAPHY.fontSize.sm,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  instruction: {
    paddingHorizontal: SPACING.lg,
  },
  instructionText: {
    fontFamily: TYPOGRAPHY.fontFamily.body,
    fontSize: TYPOGRAPHY.fontSize.md,
    color: COLORS.textSecondary,
    textAlign: 'center',
    lineHeight: TYPOGRAPHY.fontSize.md * TYPOGRAPHY.lineHeight.relaxed,
  },
});
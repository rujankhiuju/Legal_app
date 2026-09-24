import React, { useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import Animated, { useSharedValue, withSpring, withDelay, withTiming, useAnimatedStyle, runOnJS } from 'react-native-reanimated';
import { SafeContainer } from '../../components/layout/SafeContainer';
import { useGameStore } from '../../store/gameStore';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY } from '../../constants/theme';

export default function HandoffScreen() {
  const { next } = useLocalSearchParams<{ next: string }>();
  const nextIndex = parseInt(next || '0', 10);

  const { players } = useGameStore();
  const nextPlayer = players[nextIndex];

  const opacity = useSharedValue(0);
  const scale = useSharedValue(0.8);
  const translateY = useSharedValue(50);
  const pulseScale = useSharedValue(1);

  const containerStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [
      { translateY: translateY.value },
      { scale: scale.value },
    ],
  }));

  const pulseStyle = useAnimatedStyle(() => ({
    transform: [{ scale: pulseScale.value }],
  }));

  useEffect(() => {
    opacity.value = withDelay(100, withSpring(1, { damping: 15, stiffness: 100 }));
    scale.value = withDelay(100, withSpring(1, { damping: 15, stiffness: 100 }));
    translateY.value = withDelay(100, withSpring(0, { damping: 15, stiffness: 100 }));

    pulseScale.value = withSpring(1.1, { damping: 10, stiffness: 80 }, () => {
      pulseScale.value = withSpring(1, { damping: 10, stiffness: 80 });
    });

    const timer = setTimeout(() => {
      router.push(`/reveal/card?player=${nextIndex}`);
    }, 2500);

    return () => clearTimeout(timer);
  }, [nextIndex]);

  if (!nextPlayer) {
    return null;
  }

  return (
    <SafeContainer avoidKeyboard={false}>
      <Animated.View style={[styles.container, containerStyle]}>
        <View style={styles.content}>
          <Animated.View style={[styles.iconContainer, pulseStyle]}>
            <View style={[styles.icon, { backgroundColor: COLORS.neonCyan }]} />
          </Animated.View>
          
          <Text style={styles.title}>PASS TO</Text>
          
          <Text style={styles.playerName}>{nextPlayer.name}</Text>
          
          <Text style={styles.subtitle}>Player {nextIndex + 1} of {players.length}</Text>
          
          <View style={styles.instruction}>
            <Text style={styles.instructionText}>
              Hand the phone to {nextPlayer.name} and tap their card to reveal
            </Text>
          </View>
        </View>
      </Animated.View>
    </SafeContainer>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: SPACING.xl,
  },
  content: {
    alignItems: 'center',
    width: '100%',
  },
  iconContainer: {
    marginBottom: SPACING.xl,
  },
  icon: {
    width: 80,
    height: 80,
    borderRadius: 40,
    borderWidth: 3,
    borderColor: COLORS.neonCyan,
  },
  title: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.md,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 4,
    marginBottom: SPACING.md,
    textAlign: 'center',
  },
  playerName: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.xxxl,
    color: COLORS.neonCyan,
    textAlign: 'center',
    marginBottom: SPACING.sm,
  },
  subtitle: {
    fontFamily: TYPOGRAPHY.fontFamily.bodyMedium,
    fontSize: TYPOGRAPHY.fontSize.md,
    color: COLORS.textSecondary,
    textAlign: 'center',
    marginBottom: SPACING.xl,
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
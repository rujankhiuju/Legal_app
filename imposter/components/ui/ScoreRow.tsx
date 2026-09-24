import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Animated, { useSharedValue, withSpring, withDelay, useAnimatedStyle } from 'react-native-reanimated';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY } from '../../constants/theme';

interface ScoreRowProps {
  playerName: string;
  totalScore: number;
  roundScore: number;
  role?: 'civilian' | 'imposter';
  isWinner?: boolean;
  neonColor?: string;
  index?: number;
}

export const ScoreRow: React.FC<ScoreRowProps> = ({
  playerName,
  totalScore,
  roundScore,
  role,
  isWinner = false,
  neonColor = COLORS.neonCyan,
  index = 0,
}) => {
  const opacity = useSharedValue(0);
  const translateX = useSharedValue(30);
  const scale = useSharedValue(0.9);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [
      { translateX: translateX.value },
      { scale: scale.value },
    ],
  }));

  React.useEffect(() => {
    opacity.value = withDelay(index * 80, withSpring(1, { damping: 15, stiffness: 120 }));
    translateX.value = withDelay(index * 80, withSpring(0, { damping: 15, stiffness: 120 }));
    scale.value = withDelay(index * 80, withSpring(1, { damping: 15, stiffness: 120 }));
  }, [index]);

  const formatScore = (score: number) => score % 1 === 0 ? score.toString() : score.toFixed(1);

  const roleColors = {
    civilian: COLORS.success,
    imposter: COLORS.error,
  };

  return (
    <Animated.View style={[animatedStyle, styles.row]}>
      <View style={styles.info}>
        <View style={styles.nameContainer}>
          <Text style={styles.nameText}>{playerName}</Text>
          {role && (
            <View style={[styles.roleBadge, { backgroundColor: roleColors[role] }]}>
              <Text style={styles.roleText}>{role.toUpperCase()}</Text>
            </View>
          )}
          {isWinner && (
            <View style={[styles.winnerBadge, { backgroundColor: neonColor }]}>
              <Text style={styles.winnerText}>WINNER</Text>
            </View>
          )}
        </View>
      </View>
      <View style={styles.scores}>
        <View style={styles.scoreColumn}>
          <Text style={styles.scoreLabel}>ROUND</Text>
          <Text style={[
            styles.scoreValue,
            { color: roundScore > 0 ? COLORS.success : COLORS.textSecondary },
          ]}>
            {roundScore > 0 ? '+' : ''}{formatScore(roundScore)}
          </Text>
        </View>
        <View style={styles.scoreColumn}>
          <Text style={styles.scoreLabel}>TOTAL</Text>
          <Text style={[styles.scoreValue, { color: neonColor }]}>
            {formatScore(totalScore)}
          </Text>
        </View>
      </View>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: SPACING.lg,
    paddingVertical: SPACING.md,
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginVertical: SPACING.xs,
  },
  info: {
    flex: 1,
  },
  nameContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.sm,
    flexWrap: 'wrap',
  },
  nameText: {
    fontFamily: TYPOGRAPHY.fontFamily.headingMedium,
    fontSize: TYPOGRAPHY.fontSize.md,
    color: COLORS.textPrimary,
  },
  roleBadge: {
    paddingHorizontal: SPACING.sm,
    paddingVertical: SPACING.xs,
    borderRadius: RADIUS.full,
  },
  roleText: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.xs,
    color: COLORS.textOnNeon,
  },
  winnerBadge: {
    paddingHorizontal: SPACING.sm,
    paddingVertical: SPACING.xs,
    borderRadius: RADIUS.full,
  },
  winnerText: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.xs,
    color: COLORS.textOnNeon,
  },
  scores: {
    flexDirection: 'row',
    gap: SPACING.xl,
  },
  scoreColumn: {
    alignItems: 'flex-end',
  },
  scoreLabel: {
    fontFamily: TYPOGRAPHY.fontFamily.body,
    fontSize: TYPOGRAPHY.fontSize.xs,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  scoreValue: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.lg,
    lineHeight: TYPOGRAPHY.fontSize.lg * TYPOGRAPHY.lineHeight.tight,
  },
});
import React from 'react';
import { View, StyleSheet, Text, Pressable } from 'react-native';
import Animated, { useSharedValue, withSpring, useAnimatedStyle } from 'react-native-reanimated';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY, TOUCH_TARGET } from '../../constants/theme';

interface VoteButtonProps {
  playerName: string;
  isSelected: boolean;
  voteCount: number;
  onPress: () => void;
  disabled?: boolean;
  isRevealing?: boolean;
  revealRole?: 'civilian' | 'imposter';
  neonColor?: string;
}

export const VoteButton: React.FC<VoteButtonProps> = ({
  playerName,
  isSelected,
  voteCount,
  onPress,
  disabled = false,
  isRevealing = false,
  revealRole,
  neonColor = COLORS.neonCyan,
}) => {
  const scale = useSharedValue(1);
  const glow = useSharedValue(0);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
    shadowColor: neonColor,
    shadowOpacity: glow.value * 0.5,
    shadowRadius: glow.value * 20,
    shadowOffset: { width: 0, height: 0 },
    elevation: glow.value * 10,
  }));

  const handlePressIn = () => {
    if (!disabled) {
      scale.value = withSpring(0.96, { damping: 15, stiffness: 200 });
    }
  };

  const handlePressOut = () => {
    if (!disabled) {
      scale.value = withSpring(1, { damping: 15, stiffness: 200 });
    }
  };

  React.useEffect(() => {
    if (isRevealing && revealRole === 'imposter') {
      glow.value = withSpring(1, { damping: 10, stiffness: 80 });
    } else if (isRevealing && revealRole === 'civilian') {
      glow.value = withSpring(0, { damping: 10, stiffness: 80 });
    } else if (isSelected) {
      glow.value = withSpring(0.5, { damping: 10, stiffness: 80 });
    } else {
      glow.value = withSpring(0, { damping: 10, stiffness: 80 });
    }
  }, [isSelected, isRevealing, revealRole]);

  const backgroundColor = isRevealing
    ? revealRole === 'imposter'
      ? COLORS.error
      : COLORS.success
    : isSelected
    ? `${neonColor}33`
    : COLORS.surfaceElevated;

  const borderColor = isRevealing
    ? revealRole === 'imposter'
      ? COLORS.error
      : COLORS.success
    : isSelected
    ? neonColor
    : COLORS.border;

  return (
    <Animated.View style={[animatedStyle, styles.container]}>
      <Pressable
        onPress={onPress}
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
        disabled={disabled || isRevealing}
        style={({ pressed }) => [
          styles.button,
          {
            backgroundColor,
            borderColor,
            borderWidth: isRevealing || isSelected ? 3 : 2,
            opacity: disabled || isRevealing ? 0.7 : pressed ? 0.9 : 1,
            minHeight: TOUCH_TARGET.comfortable,
          },
        ]}
      >
        <View style={styles.content}>
          <Text style={[
            styles.nameText,
            { color: isRevealing ? COLORS.textOnNeon : COLORS.textPrimary },
          ]}>
            {playerName}
          </Text>
          <View style={styles.voteCountContainer}>
            <Text style={[
              styles.voteCountText,
              { color: isRevealing ? COLORS.textOnNeon : COLORS.textSecondary },
            ]}>
              {voteCount} vote{voteCount !== 1 ? 's' : ''}
            </Text>
          </View>
        </View>
        {isRevealing && revealRole === 'imposter' && (
          <Text style={styles.revealBadge}>
            IMPOSTER
          </Text>
        )}
      </Pressable>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    marginVertical: SPACING.xs,
  },
  button: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: SPACING.lg,
    paddingVertical: SPACING.md,
    borderRadius: RADIUS.lg,
    minHeight: TOUCH_TARGET.comfortable,
  },
  content: {
    flex: 1,
  },
  nameText: {
    fontFamily: TYPOGRAPHY.fontFamily.headingMedium,
    fontSize: TYPOGRAPHY.fontSize.lg,
  },
  voteCountContainer: {
    marginTop: SPACING.xs,
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.xs,
  },
  voteCountText: {
    fontFamily: TYPOGRAPHY.fontFamily.bodyMedium,
    fontSize: TYPOGRAPHY.fontSize.sm,
  },
  revealBadge: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.xs,
    color: COLORS.textOnNeon,
    backgroundColor: COLORS.error,
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.xs,
    borderRadius: RADIUS.full,
    marginLeft: SPACING.md,
  },
});
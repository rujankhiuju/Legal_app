import React from 'react';
import { Pressable, Text, StyleSheet, View } from 'react-native';
import Animated, { useSharedValue, withSpring, useAnimatedStyle } from 'react-native-reanimated';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY, TOUCH_TARGET } from '../../constants/theme';

interface NeonButtonProps {
  title: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
  disabled?: boolean;
  loading?: boolean;
  fullWidth?: boolean;
  neonColor?: string;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  style?: any;
}

export const NeonButton: React.FC<NeonButtonProps> = ({
  title,
  onPress,
  variant = 'primary',
  disabled = false,
  loading = false,
  fullWidth = false,
  neonColor = COLORS.neonCyan,
  leftIcon,
  rightIcon,
  style,
}) => {
  const scale = useSharedValue(1);
  const glow = useSharedValue(0);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
    shadowColor: variant === 'ghost' ? 'transparent' : neonColor,
    shadowOpacity: glow.value * 0.6,
    shadowRadius: glow.value * 24,
    shadowOffset: { width: 0, height: 0 },
    elevation: glow.value * 12,
  }));

  const handlePressIn = () => {
    if (!disabled && !loading) {
      scale.value = withSpring(0.97, { damping: 15, stiffness: 200 });
      glow.value = withSpring(0.8, { damping: 10, stiffness: 100 });
    }
  };

  const handlePressOut = () => {
    if (!disabled && !loading) {
      scale.value = withSpring(1, { damping: 15, stiffness: 200 });
      glow.value = withSpring(variant === 'ghost' ? 0 : 0.3, { damping: 10, stiffness: 100 });
    }
  };

  const baseStyles = [
    styles.button,
    variantStyles[variant](neonColor),
    fullWidth && styles.fullWidth,
    style,
  ];

  const textColor = variant === 'primary' || variant === 'danger'
    ? COLORS.textOnNeon
    : variant === 'secondary'
    ? neonColor
    : COLORS.textSecondary;

  return (
    <Animated.View style={[animatedStyle, styles.container]}>
      <Pressable
        onPress={onPress}
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
        disabled={disabled || loading}
        style={({ pressed }) => [
          ...baseStyles,
          {
            opacity: disabled || loading ? 0.5 : pressed ? 0.9 : 1,
            minHeight: TOUCH_TARGET.comfortable,
          },
        ]}
        accessibilityRole="button"
      >
        {loading ? (
          <View style={styles.loadingContainer}>
            <AnimatedLoadingSpinner color={textColor} />
            <Text style={[styles.loadingText, { color: textColor }]}>Loading...</Text>
          </View>
        ) : (
          <View style={styles.content}>
            {leftIcon && <View style={styles.iconLeft}>{leftIcon}</View>}
            <Text style={[
              styles.titleText,
              { color: textColor },
            ]}>
              {title}
            </Text>
            {rightIcon && <View style={styles.iconRight}>{rightIcon}</View>}
          </View>
        )}
      </Pressable>
    </Animated.View>
  );
};

const AnimatedLoadingSpinner = Animated.createAnimatedComponent(
  ({ color }: { color: string }) => (
    <View style={[styles.spinner, { borderTopColor: color }]} />
  )
);

const variantStyles = {
  primary: (neonColor: string) => ({
    backgroundColor: neonColor,
    borderWidth: 0,
  }),
  secondary: (neonColor: string) => ({
    backgroundColor: `${neonColor}1A`,
    borderWidth: 2,
    borderColor: neonColor,
  }),
  danger: (neonColor: string) => ({
    backgroundColor: COLORS.error,
    borderWidth: 0,
  }),
  ghost: (neonColor: string) => ({
    backgroundColor: 'transparent',
    borderWidth: 2,
    borderColor: COLORS.border,
  }),
};

const styles = StyleSheet.create({
  container: {
    borderRadius: RADIUS.lg,
    overflow: 'hidden',
  },
  button: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: SPACING.xl,
    paddingVertical: SPACING.md,
    borderRadius: RADIUS.lg,
    minHeight: TOUCH_TARGET.comfortable,
    gap: SPACING.sm,
  },
  fullWidth: {
    width: '100%',
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: SPACING.sm,
  },
  iconLeft: {
    marginRight: SPACING.xs,
  },
  iconRight: {
    marginLeft: SPACING.xs,
  },
  titleText: {
    fontFamily: TYPOGRAPHY.fontFamily.headingMedium,
    fontSize: TYPOGRAPHY.fontSize.md,
    lineHeight: TYPOGRAPHY.fontSize.md * TYPOGRAPHY.lineHeight.tight,
  },
  loadingContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.sm,
  },
  loadingText: {
    fontFamily: TYPOGRAPHY.fontFamily.bodyMedium,
    fontSize: TYPOGRAPHY.fontSize.md,
  },
  spinner: {
    width: 20,
    height: 20,
    borderWidth: 2,
    borderColor: 'transparent',
    borderTopColor: COLORS.textPrimary,
    borderRadius: 10,
  },
});
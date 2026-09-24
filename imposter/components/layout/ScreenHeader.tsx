import React from 'react';
import { View, Text, StyleSheet, Pressable } from 'react-native';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY, TOUCH_TARGET } from '../../constants/theme';

interface ScreenHeaderProps {
  title: string;
  onBack?: () => void;
  onClose?: () => void;
  showBack?: boolean;
  showClose?: boolean;
  neonColor?: string;
  rightContent?: React.ReactNode;
}

export const ScreenHeader: React.FC<ScreenHeaderProps> = ({
  title,
  onBack,
  onClose,
  showBack = false,
  showClose = false,
  neonColor = COLORS.neonCyan,
  rightContent,
}) => {
  return (
    <View style={styles.container}>
      <View style={styles.left}>
        {showBack && onBack && (
          <Pressable
            onPress={onBack}
            style={styles.backButton}
            accessibilityLabel="Go back"
            accessibilityRole="button"
            hitSlop={TOUCH_TARGET.minimum}
          >
            <Text style={[styles.backText, { color: neonColor }]}>←</Text>
          </Pressable>
        )}
        {showClose && onClose && (
          <Pressable
            onPress={onClose}
            style={styles.closeButton}
            accessibilityLabel="Close"
            accessibilityRole="button"
            hitSlop={TOUCH_TARGET.minimum}
          >
            <Text style={[styles.closeText, { color: COLORS.textSecondary }]}>✕</Text>
          </Pressable>
        )}
      </View>
      <Text style={[
        styles.title,
        { color: COLORS.textPrimary },
      ]}>
        {title}
      </Text>
      <View style={[styles.right, { width: showBack || showClose ? 48 : 0 }]}>
        {rightContent}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: SPACING.lg,
    paddingVertical: SPACING.md,
    minHeight: 60,
  },
  left: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.sm,
  },
  right: {
    width: 48,
    justifyContent: 'flex-end',
  },
  backButton: {
    padding: SPACING.sm,
  },
  backText: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.xl,
    lineHeight: TYPOGRAPHY.fontSize.xl,
  },
  closeButton: {
    padding: SPACING.sm,
  },
  closeText: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.xl,
    lineHeight: TYPOGRAPHY.fontSize.xl,
  },
  title: {
    fontFamily: TYPOGRAPHY.fontFamily.headingMedium,
    fontSize: TYPOGRAPHY.fontSize.lg,
    textAlign: 'center',
    flex: 1,
  },
});
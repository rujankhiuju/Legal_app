import React from 'react';
import { View, TextInput, StyleSheet, Text, Animated, TextInputProps } from 'react-native';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY, TOUCH_TARGET } from '../../constants/theme';

interface InputFieldProps extends TextInputProps {
  label?: string;
  error?: string;
  helperText?: string;
  neonColor?: string;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  value?: string;
}

export const InputField: React.FC<InputFieldProps> = ({
  label,
  error,
  helperText,
  neonColor = COLORS.neonCyan,
  leftIcon,
  rightIcon,
  style,
  ...props
}) => {
  const borderColor = error ? COLORS.error : neonColor;
  const textColor = error ? COLORS.error : COLORS.textSecondary;

  return (
    <View style={[styles.container, style]}>
      {label && (
        <Text style={styles.label}>{label}</Text>
      )}
      <View style={styles.inputWrapper}>
        {leftIcon && (
          <View style={styles.iconLeft}>
            {leftIcon}
          </View>
        )}
        <TextInput
          style={[
            styles.input,
            {
              borderColor,
              color: COLORS.textPrimary,
              paddingLeft: leftIcon ? SPACING.md : SPACING.lg,
              paddingRight: rightIcon ? SPACING.md : SPACING.lg,
              minHeight: TOUCH_TARGET.comfortable,
            },
          ]}
          {...props}
          placeholderTextColor={COLORS.textMuted}
          selectionColor={neonColor}
          cursorColor={neonColor}
        />
        {rightIcon && (
          <View style={styles.iconRight}>
            {rightIcon}
          </View>
        )}
      </View>
      {error && (
        <Text style={[styles.errorText, { color: COLORS.error }]}>
          {error}
        </Text>
      )}
      {helperText && !error && (
        <Text style={[styles.helperText, { color: textColor }]}>
          {helperText}
        </Text>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    gap: SPACING.xs,
    width: '100%',
  },
  label: {
    fontFamily: TYPOGRAPHY.fontFamily.bodyMedium,
    fontSize: TYPOGRAPHY.fontSize.sm,
    color: COLORS.textSecondary,
    marginBottom: SPACING.xs,
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.md,
    borderWidth: 2,
  },
  input: {
    flex: 1,
    fontFamily: TYPOGRAPHY.fontFamily.body,
    fontSize: TYPOGRAPHY.fontSize.md,
    paddingVertical: SPACING.md,
  },
  iconLeft: {
    paddingLeft: SPACING.md,
  },
  iconRight: {
    paddingRight: SPACING.md,
  },
  errorText: {
    fontFamily: TYPOGRAPHY.fontFamily.body,
    fontSize: TYPOGRAPHY.fontSize.xs,
    marginTop: SPACING.xs,
  },
  helperText: {
    fontFamily: TYPOGRAPHY.fontFamily.body,
    fontSize: TYPOGRAPHY.fontSize.xs,
    marginTop: SPACING.xs,
  },
});
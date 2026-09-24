import React from 'react';
import { View, StyleSheet, Pressable, Text } from 'react-native';
import Animated, { useSharedValue, withSpring, useAnimatedStyle } from 'react-native-reanimated';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY, NEON_PALETTE, TOUCH_TARGET } from '../../constants/theme';

interface NeonColorPickerProps {
  selectedColor: string;
  onSelect: (color: string) => void;
  columns?: number;
  showLabels?: boolean;
}

export const NeonColorPicker: React.FC<NeonColorPickerProps> = ({
  selectedColor,
  onSelect,
  columns = 5,
  showLabels = false,
}) => {
  const scales = NEON_PALETTE.map(() => useSharedValue(1));
  const glows = NEON_PALETTE.map(() => useSharedValue(0));

  const itemsPerRow = columns;
  const rowCount = Math.ceil(NEON_PALETTE.length / itemsPerRow);

  const renderColorItem = (color: string, index: number) => {
    const isSelected = selectedColor === color;
    const scale = scales[index];
    const glow = glows[index];

    const animatedStyle = useAnimatedStyle(() => ({
      transform: [{ scale: scale.value }],
      shadowColor: color,
      shadowOpacity: glow.value * 0.6,
      shadowRadius: glow.value * 16,
      shadowOffset: { width: 0, height: 0 },
      elevation: glow.value * 8,
      borderWidth: isSelected ? 3 : 0,
      borderColor: COLORS.textPrimary,
    }));

    React.useEffect(() => {
      if (isSelected) {
        scale.value = withSpring(1.05, { damping: 10, stiffness: 80 });
        glow.value = withSpring(1, { damping: 10, stiffness: 80 });
      } else {
        scale.value = withSpring(1, { damping: 15, stiffness: 120 });
        glow.value = withSpring(0, { damping: 15, stiffness: 120 });
      }
    }, [isSelected]);

    return (
      <Animated.View key={color} style={[animatedStyle, styles.colorItem]}>
        <Pressable
          onPress={() => onSelect(color)}
          onPressIn={() => {
            scale.value = withSpring(0.95, { damping: 15, stiffness: 200 });
          }}
          onPressOut={() => {
            scale.value = withSpring(isSelected ? 1.05 : 1, { damping: 15, stiffness: 120 });
          }}
          style={({ pressed }) => [
            styles.colorButton,
            {
              backgroundColor: color,
              opacity: pressed ? 0.9 : 1,
              minHeight: TOUCH_TARGET.large,
              minWidth: TOUCH_TARGET.large,
            },
          ]}
          accessibilityLabel={`Select ${color} neon color`}
          accessibilityRole="button"
          accessibilityState={{ selected: isSelected }}
        />
        {showLabels && (
          <Text style={styles.colorLabel} numberOfLines={1}>
            {color}
          </Text>
        )}
      </Animated.View>
    );
  };

  const rows = [];
  for (let i = 0; i < rowCount; i++) {
    const rowItems = NEON_PALETTE.slice(i * itemsPerRow, (i + 1) * itemsPerRow);
    rows.push(
      <View key={i} style={styles.colorRow}>
        {rowItems.map((color, j) => renderColorItem(color, i * itemsPerRow + j))}
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {rows}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    gap: SPACING.md,
  },
  colorRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: SPACING.md,
    flexWrap: 'wrap',
  },
  colorItem: {
    alignItems: 'center',
    gap: SPACING.xs,
  },
  colorButton: {
    width: 56,
    height: 56,
    borderRadius: RADIUS.full,
    alignItems: 'center',
    justifyContent: 'center',
  },
  colorLabel: {
    fontFamily: TYPOGRAPHY.fontFamily.body,
    fontSize: TYPOGRAPHY.fontSize.xs,
    color: COLORS.textMuted,
    textAlign: 'center',
  },
});
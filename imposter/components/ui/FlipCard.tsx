import React from 'react';
import { View, StyleSheet, Text, Image } from 'react-native';
import Animated, { useSharedValue, withSpring, useAnimatedStyle } from 'react-native-reanimated';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY, CARD, SHADOWS } from '../../constants/theme';

interface FlipCardProps {
  children: React.ReactNode;
  backChildren: React.ReactNode;
  isFlipped: boolean;
  onFlip?: () => void;
  style?: any;
}

export const FlipCard: React.FC<FlipCardProps> = ({
  children,
  backChildren,
  isFlipped,
  onFlip,
  style,
}) => {
  const flip = useSharedValue(isFlipped ? 180 : 0);

  React.useEffect(() => {
    flip.value = withSpring(isFlipped ? 180 : 0, { damping: 15, stiffness: 150 });
  }, [isFlipped]);

  const animatedStyle = useAnimatedStyle(() => {
    const rotateY = flip.value;
    return {
      transform: [
        { perspective: 1000 },
        { rotateY: `${rotateY}deg` },
      ],
    };
  });

  const frontStyle = useAnimatedStyle(() => {
    const rotateY = flip.value;
    const opacity = rotateY > 90 ? 0 : 1;
    return {
      opacity,
      transform: [
        { perspective: 1000 },
        { rotateY: `${rotateY}deg` },
      ],
      backfaceVisibility: 'hidden',
    };
  });

  const backStyle = useAnimatedStyle(() => {
    const rotateY = flip.value + 180;
    const opacity = rotateY > 90 ? 0 : 1;
    return {
      opacity,
      transform: [
        { perspective: 1000 },
        { rotateY: `${rotateY}deg` },
      ],
      backfaceVisibility: 'hidden',
    };
  });

  return (
    <Animated.View style={[styles.container, style, animatedStyle]}>
      <Animated.View style={[styles.cardFace, styles.front, frontStyle]}>
        {children}
      </Animated.View>
      <Animated.View style={[styles.cardFace, styles.back, backStyle]}>
        {backChildren}
      </Animated.View>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: CARD.width,
    height: CARD.height,
    maxWidth: CARD.maxWidth,
    maxHeight: CARD.maxHeight,
    ...SHADOWS.card,
  },
  cardFace: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    borderRadius: CARD.borderRadius,
    backgroundColor: COLORS.surfaceElevated,
    borderWidth: 2,
    borderColor: COLORS.border,
    justifyContent: 'center',
    alignItems: 'center',
    padding: CARD.borderRadius,
  },
  front: {
    zIndex: 2,
  },
  back: {
    zIndex: 1,
  },
});
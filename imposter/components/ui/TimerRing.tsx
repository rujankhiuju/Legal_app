import React from 'react';
import { View, StyleSheet, Text } from 'react-native';
import Svg, { Circle } from 'react-native-svg';
import Animated, { useSharedValue, withTiming, withSpring, useAnimatedProps } from 'react-native-reanimated';
import { COLORS, SPACING, TYPOGRAPHY, TIMER_RING } from '../../constants/theme';

interface TimerRingProps {
  duration: number;
  progress: number;
  isPaused?: boolean;
  onComplete?: () => void;
  size?: number;
  strokeWidth?: number;
  color?: string;
  warningColor?: string;
  warningThreshold?: number;
}

export const TimerRing: React.FC<TimerRingProps> = ({
  duration,
  progress,
  isPaused,
  onComplete,
  size = TIMER_RING.size,
  strokeWidth = TIMER_RING.strokeWidth,
  color = COLORS.neonCyan,
  warningColor = COLORS.neonPink,
  warningThreshold = 10,
}) => {
  const remaining = duration * (1 - progress);
  const isWarning = remaining <= warningThreshold && remaining > 0;

  const animatedProgress = useSharedValue(progress);
  const animatedColor = useSharedValue(color);

  React.useEffect(() => {
    animatedProgress.value = withTiming(progress, { duration: isPaused ? 0 : 100 });
  }, [progress, isPaused]);

  React.useEffect(() => {
    if (isWarning) {
      animatedColor.value = withSpring(warningColor, { damping: 10, stiffness: 100 });
    } else {
      animatedColor.value = withSpring(color, { damping: 10, stiffness: 100 });
    }
  }, [isWarning, color, warningColor]);

  const circumference = 2 * Math.PI * (size / 2 - strokeWidth / 2);
  const offset = circumference * (1 - animatedProgress.value);

  const circleProps = useAnimatedProps(() => ({
    strokeDashoffset: offset,
    stroke: animatedColor.value,
  }));

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <View style={styles.container}>
      <Svg width={size} height={size}>
        <Circle
          cx={size / 2}
          cy={size / 2}
          r={size / 2 - strokeWidth / 2}
          stroke={COLORS.border}
          strokeWidth={strokeWidth}
          fill="transparent"
        />
        <AnimatedCircle
          cx={size / 2}
          cy={size / 2}
          r={size / 2 - strokeWidth / 2}
          strokeWidth={strokeWidth}
          strokeDasharray={circumference}
          animatedProps={circleProps}
        />
      </Svg>
      <View style={styles.timeContainer}>
        <Text style={[
          styles.timeText,
          { fontSize: size * 0.15 },
          isWarning && styles.warningText
        ]}>
          {formatTime(remaining)}
        </Text>
        <Text style={[
          styles.labelText,
          { fontSize: size * 0.05 }
        ]}>
          {isPaused ? 'PAUSED' : 'DISCUSSION'}
        </Text>
      </View>
    </View>
  );
};

const AnimatedCircle = Animated.createAnimatedComponent(Circle);

const styles = StyleSheet.create({
  container: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  timeContainer: {
    position: 'absolute',
    justifyContent: 'center',
    alignItems: 'center',
  },
  timeText: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    color: COLORS.textPrimary,
    lineHeight: 1.1,
  },
  warningText: {
    color: COLORS.neonPink,
  },
  labelText: {
    fontFamily: TYPOGRAPHY.fontFamily.body,
    color: COLORS.textSecondary,
    marginTop: 4,
  },
});
import { useSharedValue, withTiming, withSpring, useAnimatedStyle, runOnJS } from 'react-native-reanimated';
import { COLORS } from '../../constants/theme';

export const useTimerRing = (duration: number) => {
  const progress = useSharedValue(0);
  const color = useSharedValue(COLORS.neonCyan);
  const isPaused = useSharedValue(false);
  const remainingTime = useSharedValue(duration);

  const start = () => {
    progress.value = withTiming(1, { duration: duration * 1000 }, (finished) => {
      if (finished) {
        runOnJS(() => {})();
      }
    });
    isPaused.value = false;
  };

  const pause = () => {
    isPaused.value = true;
    progress.value = progress.value;
  };

  const resume = () => {
    const remaining = duration * (1 - progress.value);
    progress.value = withTiming(1, { duration: remaining * 1000 });
    isPaused.value = false;
  };

  const reset = () => {
    progress.value = 0;
    color.value = COLORS.neonCyan;
    remainingTime.value = duration;
    isPaused.value = false;
  };

  const updateRemaining = (seconds: number) => {
    remainingTime.value = seconds;
    const progressValue = 1 - seconds / duration;
    progress.value = progressValue;
    
    if (seconds <= 10 && seconds > 0) {
      color.value = withSpring(COLORS.neonPink, { damping: 10, stiffness: 100 });
    }
  };

  const animatedStyle = useAnimatedStyle(() => {
    const circumference = 2 * Math.PI * 45;
    return {
      strokeDashoffset: circumference * (1 - progress.value),
      stroke: color.value,
    } as any;
  });

  return {
    progress,
    color,
    isPaused,
    remainingTime,
    start,
    pause,
    resume,
    reset,
    updateRemaining,
    animatedStyle,
  };
};

const CIRCUMFERENCE = 2 * Math.PI * 45;
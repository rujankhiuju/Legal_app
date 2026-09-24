import { useSharedValue, withSpring, withDelay, useAnimatedStyle } from 'react-native-reanimated';

export const useStaggeredReveal = (count: number, delay: number = 80) => {
  const values = Array.from({ length: count }, () => useSharedValue(0));

  const start = () => {
    values.forEach((value, index) => {
      value.value = withDelay(index * delay, withSpring(1, { damping: 15, stiffness: 120 }));
    });
  };

  const reset = () => {
    values.forEach((value) => {
      value.value = 0;
    });
  };

  const getAnimatedStyle = (index: number) => {
    const value = values[index];
    if (!value) return {};

    return useAnimatedStyle(() => ({
      opacity: value.value,
      transform: [
        { translateY: withSpring(20 * (1 - value.value), { damping: 15, stiffness: 120 }) },
        { scale: withSpring(0.9 + 0.1 * value.value, { damping: 15, stiffness: 120 }) },
      ],
    }));
  };

  return { start, reset, getAnimatedStyle };
};

export const useStaggeredScale = (count: number, delay: number = 60) => {
  const values = Array.from({ length: count }, () => useSharedValue(0));

  const start = () => {
    values.forEach((value, index) => {
      value.value = withDelay(index * delay, withSpring(1, { damping: 12, stiffness: 100 }));
    });
  };

  const reset = () => {
    values.forEach((value) => {
      value.value = 0;
    });
  };

  const getAnimatedStyle = (index: number) => {
    const value = values[index];
    if (!value) return {};

    return useAnimatedStyle(() => ({
      transform: [{ scale: withSpring(value.value, { damping: 12, stiffness: 100 }) }],
    }));
  };

  return { start, reset, getAnimatedStyle };
};
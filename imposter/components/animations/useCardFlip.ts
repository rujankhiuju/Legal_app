import { useSharedValue, withSpring, withTiming, useAnimatedStyle, runOnUI } from 'react-native-reanimated';

export const useCardFlip = () => {
  const flip = useSharedValue(0);
  const isFlipped = useSharedValue(false);

  const flipCard = () => {
    const target = flip.value === 0 ? 180 : 0;
    flip.value = withSpring(target, { damping: 15, stiffness: 150 });
    isFlipped.value = !isFlipped.value;
  };

  const resetFlip = () => {
    flip.value = withSpring(0, { damping: 15, stiffness: 150 });
    isFlipped.value = false;
  };

  const animatedStyle = useAnimatedStyle(() => {
    const rotateY = flip.value;
    const backfaceVisibility = rotateY > 90 ? 'hidden' : 'visible';
    
    return {
      transform: [
        { perspective: 1000 },
        { rotateY: `${rotateY}deg` },
      ],
      backfaceVisibility,
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

  return {
    flip,
    isFlipped,
    flipCard,
    resetFlip,
    animatedStyle,
    frontStyle,
    backStyle,
  };
};
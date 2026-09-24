import { Dimensions, Platform } from 'react-native';

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window');

export const LAYOUT = {
  screenWidth: SCREEN_WIDTH,
  screenHeight: SCREEN_HEIGHT,
  isSmallScreen: SCREEN_WIDTH < 375,
  isLargeScreen: SCREEN_WIDTH >= 414,
  headerHeight: Platform.OS === 'ios' ? 44 : 56,
  tabBarHeight: Platform.OS === 'ios' ? 83 : 72,
};

export const TOUCH_TARGET = {
  minimum: 48,
  comfortable: 56,
  large: 64,
};

export const CARD = {
  width: SCREEN_WIDTH * 0.85,
  height: SCREEN_HEIGHT * 0.55,
  maxWidth: 360,
  maxHeight: 500,
  borderRadius: 24,
};

export const TIMER_RING = {
  size: Math.min(SCREEN_WIDTH, SCREEN_HEIGHT) * 0.6,
  strokeWidth: 12,
  maxSize: 320,
};

export const SPACING = {
  screenPadding: 24,
  cardPadding: 20,
  sectionGap: 32,
  itemGap: 16,
};
import React from 'react';
import { Stack } from 'expo-router';
import { useFonts } from 'expo-font';
import * as SplashScreen from 'expo-splash-screen';
import { SpaceGrotesk_400Regular, SpaceGrotesk_500Medium, SpaceGrotesk_600SemiBold, SpaceGrotesk_700Bold } from '@expo-google-fonts/space-grotesk';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { COLORS } from '../constants/theme';

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [fontsLoaded] = useFonts({
    SpaceGrotesk_400Regular,
    SpaceGrotesk_500Medium,
    SpaceGrotesk_600SemiBold,
    SpaceGrotesk_700Bold,
  });

  React.useEffect(() => {
    if (fontsLoaded) {
      SplashScreen.hideAsync();
    }
  }, [fontsLoaded]);

  if (!fontsLoaded) {
    return null;
  }

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <Stack
        screenOptions={{
          headerShown: false,
        }}
      >
        <Stack.Screen name="index" options={{ presentation: 'card' }} />
        <Stack.Screen name="setup/index" options={{ presentation: 'card' }} />
        <Stack.Screen name="setup/player-names" options={{ presentation: 'card' }} />
        <Stack.Screen name="setup/settings" options={{ presentation: 'card' }} />
        <Stack.Screen name="reveal/card" options={{ presentation: 'card' }} />
        <Stack.Screen name="reveal/handoff" options={{ presentation: 'card' }} />
        <Stack.Screen name="discussion/timer" options={{ presentation: 'card' }} />
        <Stack.Screen name="voting/index" options={{ presentation: 'card' }} />
        <Stack.Screen name="results/index" options={{ presentation: 'card' }} />
        <Stack.Screen name="manage/categories" options={{ presentation: 'card' }} />
        <Stack.Screen name="manage/words" options={{ presentation: 'card' }} />
      </Stack>
    </GestureHandlerRootView>
  );
}
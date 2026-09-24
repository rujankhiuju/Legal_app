import AsyncStorage from '@react-native-async-storage/async-storage';

const STORAGE_KEYS = {
  GAME_STATE: 'imposter-game-store',
  SETTINGS: 'imposter-settings-store',
  CATEGORIES: 'imposter-category-store',
  SCORES: 'imposter-score-store',
} as const;

export const clearAllData = async (): Promise<void> => {
  await Promise.all(
    Object.values(STORAGE_KEYS).map((key) => AsyncStorage.removeItem(key))
  );
};

export const clearGameState = async (): Promise<void> => {
  await AsyncStorage.removeItem(STORAGE_KEYS.GAME_STATE);
};

export const getStorageSize = async (): Promise<number> => {
  const keys = await AsyncStorage.getAllKeys();
  let total = 0;
  for (const key of keys) {
    const value = await AsyncStorage.getItem(key);
    total += value?.length ?? 0;
  }
  return total;
};

export const exportData = async (): Promise<string> => {
  const keys = await AsyncStorage.getAllKeys();
  const items: [string, string][] = [];
  for (const key of keys) {
    const value = await AsyncStorage.getItem(key);
    if (value !== null) {
      items.push([key, value]);
    }
  }
  return JSON.stringify(Object.fromEntries(items), null, 2);
};

export const importData = async (json: string): Promise<void> => {
  const data = JSON.parse(json);
  const entries = Object.entries(data) as [string, string][];
  for (const [key, value] of entries) {
    await AsyncStorage.setItem(key, value);
  }
};
import { Audio } from 'expo-av';
import { useSettingsStore } from '../store/settingsStore';

type SoundName = 'flip' | 'timerWarning' | 'voteSubmit' | 'reveal' | 'win' | 'lose';

const SOUND_FILES: Record<SoundName, string> = {
  flip: require('../assets/sounds/flip.mp3'),
  timerWarning: require('../assets/sounds/timer-warning.mp3'),
  voteSubmit: require('../assets/sounds/vote-submit.mp3'),
  reveal: require('../assets/sounds/reveal.mp3'),
  win: require('../assets/sounds/win.mp3'),
  lose: require('../assets/sounds/lose.mp3'),
};

let soundCache: Record<SoundName, Audio.Sound | null> = {
  flip: null,
  timerWarning: null,
  voteSubmit: null,
  reveal: null,
  win: null,
  lose: null,
};

let isLoaded = false;

export const preloadSounds = async (): Promise<void> => {
  if (isLoaded) return;
  
  await Promise.all(
    Object.entries(SOUND_FILES).map(async ([name, file]) => {
      try {
        const { sound } = await Audio.Sound.createAsync(file as any, {
          shouldPlay: false,
          isLooping: false,
          volume: 0.7,
        });
        soundCache[name as SoundName] = sound;
      } catch (error) {
        console.warn(`Failed to load sound: ${name}`, error);
      }
    })
  );
  isLoaded = true;
};

export const unloadSounds = async (): Promise<void> => {
  await Promise.all(
    Object.values(soundCache).map(async (sound) => {
      if (sound) {
        try {
          await sound.unloadAsync();
        } catch (error) {
          console.warn('Failed to unload sound', error);
        }
      }
    })
  );
  soundCache = {
    flip: null,
    timerWarning: null,
    voteSubmit: null,
    reveal: null,
    win: null,
    lose: null,
  };
  isLoaded = false;
};

export const playSound = async (name: SoundName): Promise<void> => {
  const enableSounds = useSettingsStore.getState().enableSounds;
  if (!enableSounds) return;

  const sound = soundCache[name];
  if (sound) {
    try {
      await sound.replayAsync();
    } catch (error) {
      console.warn(`Failed to play sound: ${name}`, error);
    }
  }
};

export const useSound = () => {
  const enableSounds = useSettingsStore((s) => s.enableSounds);

  const play = async (name: SoundName) => {
    if (!enableSounds) return;
    await playSound(name);
  };

  return { play, preloadSounds, unloadSounds };
};
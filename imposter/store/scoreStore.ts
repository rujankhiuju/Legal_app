import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { SessionScore, GameHistoryEntry, GameSettings } from '../types';

type ScoreStore = {
  sessionScores: SessionScore[];
  history: GameHistoryEntry[];
  addSessionScore: (score: SessionScore) => void;
  updateSessionScore: (playerId: number, points: number) => void;
  getSessionScores: () => SessionScore[];
  resetSessionScores: () => void;
  saveGameToHistory: (settings: GameSettings, scores: SessionScore[], winner: 'imposters' | 'civilians') => void;
  getHistory: () => GameHistoryEntry[];
  clearHistory: () => void;
};

export const useScoreStore = create<ScoreStore>()(
  persist(
    (set, get) => ({
      sessionScores: [],
      history: [],

      addSessionScore: (score) =>
        set((state) => ({
          sessionScores: [...state.sessionScores, score],
        })),

      updateSessionScore: (playerId, points) =>
        set((state) => ({
          sessionScores: state.sessionScores.map((s) =>
            s.playerId === playerId ? { ...s, totalScore: s.totalScore + points } : s
          ),
        })),

      getSessionScores: () => get().sessionScores,

      resetSessionScores: () => set({ sessionScores: [] }),

      saveGameToHistory: (settings, scores, winner) =>
        set((state) => ({
          history: [
            {
              id: `game_${Date.now()}`,
              date: Date.now(),
              settings,
              scores,
              winner,
            },
            ...state.history.slice(0, 49),
          ],
        })),

      getHistory: () => get().history,

      clearHistory: () => set({ history: [] }),
    }),
    {
      name: 'imposter-score-store',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
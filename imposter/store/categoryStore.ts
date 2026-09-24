import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Category } from '../types';
import { BUILTIN_CATEGORIES, NEON_PALETTE } from '../constants/theme';

type CategoryStore = {
  categories: Category[];
  customWordsByCategory: Record<string, string[]>;
  addCategory: (category: Omit<Category, 'id' | 'isCustom'>) => string;
  updateCategory: (id: string, updates: Partial<Category>) => void;
  deleteCategory: (id: string) => void;
  addWord: (categoryId: string, word: string) => void;
  removeWord: (categoryId: string, word: string) => void;
  getCategory: (id: string) => Category | undefined;
  getAllWords: (categoryId: string) => string[];
  getNeonPalette: () => string[];
  resetCategories: () => void;
};

const initialCategories = [...BUILTIN_CATEGORIES];

export const useCategoryStore = create<CategoryStore>()(
  persist(
    (set, get) => ({
      categories: initialCategories,
      customWordsByCategory: {},

      addCategory: (category) => {
        const id = `custom_${Date.now()}`;
        const newCategory: Category = {
          ...category,
          id,
          isCustom: true,
        };
        set((state) => ({
          categories: [...state.categories, newCategory],
        }));
        return id;
      },

      updateCategory: (id, updates) =>
        set((state) => ({
          categories: state.categories.map((c) =>
            c.id === id ? { ...c, ...updates } : c
          ),
        })),

      deleteCategory: (id) =>
        set((state) => ({
          categories: state.categories.filter((c) => c.id !== id || !c.isCustom),
          customWordsByCategory: Object.fromEntries(
            Object.entries(state.customWordsByCategory).filter(([k]) => k !== id)
          ),
        })),

      addWord: (categoryId, word) =>
        set((state) => {
          const trimmed = word.trim();
          if (!trimmed) return state;
          const existing = state.customWordsByCategory[categoryId] || [];
          if (existing.some((w) => w.toLowerCase() === trimmed.toLowerCase())) {
            return state;
          }
          return {
            customWordsByCategory: {
              ...state.customWordsByCategory,
              [categoryId]: [...existing, trimmed],
            },
          };
        }),

      removeWord: (categoryId, word) =>
        set((state) => ({
          customWordsByCategory: {
            ...state.customWordsByCategory,
            [categoryId]: (state.customWordsByCategory[categoryId] || []).filter(
              (w) => w.toLowerCase() !== word.toLowerCase()
            ),
          },
        })),

      getCategory: (id) => get().categories.find((c) => c.id === id),

      getAllWords: (categoryId) => {
        const category = get().categories.find((c) => c.id === categoryId);
        const customWords = get().customWordsByCategory[categoryId] || [];
        const builtInWords = category?.words || [];
        return [...builtInWords, ...customWords];
      },

      getNeonPalette: () => NEON_PALETTE,

      resetCategories: () =>
        set({
          categories: initialCategories,
          customWordsByCategory: {},
        }),
    }),
    {
      name: 'imposter-category-store',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
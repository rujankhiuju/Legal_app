import { useCategoryStore } from '../store/categoryStore';
import { useGameStore } from '../store/gameStore';

export const useWordPicker = () => {
  const getAllWords = useCategoryStore((s) => s.getAllWords);
  const { settings, usedWords, addUsedWord, setSecretWord, setCategoryHint } = useGameStore();

  const pickWord = (): { word: string; hint: string } => {
    const category = useCategoryStore.getState().getCategory(settings.categoryId);
    if (!category) {
      return { word: 'Mystery', hint: 'Unknown category' };
    }

    const allWords = getAllWords(settings.categoryId);
    const availableWords = allWords.filter((w) => !usedWords.includes(w));

    let selectedWord: string;
    if (availableWords.length === 0) {
      selectedWord = allWords[Math.floor(Math.random() * allWords.length)];
    } else {
      selectedWord = availableWords[Math.floor(Math.random() * availableWords.length)];
    }

    addUsedWord(selectedWord);
    setSecretWord(selectedWord);
    setCategoryHint(category.hintPrefix);

    return {
      word: selectedWord,
      hint: category.hintPrefix,
    };
  };

  const getHintForImposter = (): string => {
    const category = useCategoryStore.getState().getCategory(settings.categoryId);
    return category?.hintPrefix ?? 'It is something...';
  };

  return { pickWord, getHintForImposter };
};
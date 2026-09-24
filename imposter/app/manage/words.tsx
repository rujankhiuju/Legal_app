import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, TextInput, Alert, TouchableOpacity } from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import { SafeContainer } from '../../components/layout/SafeContainer';
import { ScreenHeader } from '../../components/layout/ScreenHeader';
import { NeonButton } from '../../components/ui/NeonButton';
import { InputField } from '../../components/ui/InputField';
import { useCategoryStore } from '../../store/categoryStore';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY } from '../../constants/theme';

export default function ManageWordsScreen() {
  const { category } = useLocalSearchParams<{ category: string }>();
  const { categories, addWord, removeWord, getAllWords } = useCategoryStore();

  const selectedCategory = categories.find(c => c.id === category);
  const [newWord, setNewWord] = useState('');
  const [words, setWords] = useState<string[]>([]);

  useEffect(() => {
    if (selectedCategory) {
      setWords(getAllWords(selectedCategory.id));
    }
  }, [selectedCategory, getAllWords]);

  const handleAddWord = () => {
    if (!newWord.trim()) {
      Alert.alert('Error', 'Word cannot be empty');
      return;
    }
    if (newWord.trim().length > 30) {
      Alert.alert('Error', 'Word must be 30 characters or fewer');
      return;
    }
    if (words.some(w => w.toLowerCase() === newWord.trim().toLowerCase())) {
      Alert.alert('Error', 'This word already exists');
      return;
    }
    if (selectedCategory) {
      addWord(selectedCategory.id, newWord.trim());
      setNewWord('');
    }
  };

  const handleRemoveWord = (word: string) => {
    if (selectedCategory) {
      removeWord(selectedCategory.id, word);
    }
  };

  if (!selectedCategory) {
    return (
      <SafeContainer>
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>Category not found</Text>
        </View>
      </SafeContainer>
    );
  }

  const isBuiltInWord = (word: string) => selectedCategory.words.includes(word);

  return (
    <SafeContainer avoidKeyboard={true}>
      <View style={styles.container}>
        <ScreenHeader 
          title={selectedCategory.name.toUpperCase()} 
          neonColor={selectedCategory.neonColor}
          onBack={() => router.back()}
          showBack
        />

        <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
          <View style={styles.addWordForm}>
            <InputField
              label="Add New Word"
              value={newWord}
              onChangeText={setNewWord}
              placeholder="Enter a word..."
              neonColor={selectedCategory.neonColor}
              onSubmitEditing={handleAddWord}
              returnKeyType="done"
            />
            <NeonButton
              title="Add Word"
              variant="primary"
              onPress={handleAddWord}
              neonColor={selectedCategory.neonColor}
              fullWidth
              style={styles.addButton}
            />
          </View>

          <View style={styles.wordList}>
            <Text style={styles.sectionTitle}>
              WORDS ({words.length})
            </Text>
            {words.length === 0 ? (
              <Text style={styles.emptyText}>No words yet. Add some above!</Text>
            ) : (
              words.map((word, index) => (
                <View key={word} style={styles.wordItem}>
                  <Text style={[
                    styles.wordText,
                    { color: isBuiltInWord(word) ? COLORS.textPrimary : COLORS.neonAmber },
                  ]}>
                    {word}
                    {isBuiltInWord(word) && (
                      <Text style={styles.builtinBadge}>BUILT-IN</Text>
                    )}
                  </Text>
                  {!isBuiltInWord(word) && (
                    <TouchableOpacity
                      onPress={() => handleRemoveWord(word)}
                      style={styles.removeButton}
                      hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                    >
                      <Text style={styles.removeButtonText}>✕</Text>
                    </TouchableOpacity>
                  )}
                </View>
              ))
            )}
          </View>
        </ScrollView>
      </View>
    </SafeContainer>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: SPACING.lg,
    paddingBottom: SPACING.xxl,
    flexGrow: 1,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyText: {
    fontFamily: TYPOGRAPHY.fontFamily.body,
    fontSize: TYPOGRAPHY.fontSize.md,
    color: COLORS.textMuted,
    textAlign: 'center',
  },
  addWordForm: {
    marginBottom: SPACING.xl,
    padding: SPACING.lg,
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.xl,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  addButton: {
    marginTop: SPACING.md,
  },
  wordList: {
    gap: SPACING.sm,
  },
  sectionTitle: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.sm,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 2,
    marginBottom: SPACING.md,
  },
  wordItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: SPACING.md,
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.md,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  wordText: {
    fontFamily: TYPOGRAPHY.fontFamily.bodyMedium,
    fontSize: TYPOGRAPHY.fontSize.md,
    flex: 1,
    flexWrap: 'wrap',
  },
  builtinBadge: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.xs,
    color: COLORS.textMuted,
    marginLeft: SPACING.sm,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  removeButton: {
    padding: SPACING.xs,
  },
  removeButtonText: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.lg,
    color: COLORS.error,
  },
});
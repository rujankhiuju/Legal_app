import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert } from 'react-native';
import { router } from 'expo-router';
import { SafeContainer } from '../../components/layout/SafeContainer';
import { ScreenHeader } from '../../components/layout/ScreenHeader';
import { NeonButton } from '../../components/ui/NeonButton';
import { InputField } from '../../components/ui/InputField';
import { NeonColorPicker } from '../../components/ui/NeonColorPicker';
import { useCategoryStore } from '../../store/categoryStore';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY, NEON_PALETTE } from '../../constants/theme';
import { Category } from '../../types';

export default function ManageCategoriesScreen() {
  const { categories, addCategory, updateCategory, deleteCategory, getNeonPalette } = useCategoryStore();

  const [showCreate, setShowCreate] = useState(false);
  const [editingCategory, setEditingCategory] = useState<string | null>(null);
  const [newCategoryName, setNewCategoryName] = useState('');
  const [newCategoryHint, setNewCategoryHint] = useState('');
  const [newCategoryColor, setNewCategoryColor] = useState(NEON_PALETTE[0]);

  const handleCreate = () => {
    if (!newCategoryName.trim()) {
      Alert.alert('Error', 'Category name cannot be empty');
      return;
    }
    if (!newCategoryHint.trim()) {
      Alert.alert('Error', 'Hint prefix cannot be empty');
      return;
    }
    addCategory({
      name: newCategoryName.trim(),
      hintPrefix: newCategoryHint.trim(),
      neonColor: newCategoryColor,
      words: [],
    });
    setShowCreate(false);
    setNewCategoryName('');
    setNewCategoryHint('');
    setNewCategoryColor(NEON_PALETTE[0]);
  };

  const handleUpdate = (id: string, name: string, hint: string, color: string) => {
    if (!name.trim() || !hint.trim()) return;
    updateCategory(id, { name: name.trim(), hintPrefix: hint.trim(), neonColor: color });
    setEditingCategory(null);
  };

  const handleDelete = (id: string) => {
    Alert.alert('Delete Category', 'Are you sure?', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Delete', style: 'destructive', onPress: () => deleteCategory(id) },
    ]);
  };

  const customCategories = categories.filter(c => c.isCustom);
  const builtinCategories = categories.filter(c => !c.isCustom);

  return (
    <SafeContainer avoidKeyboard={true}>
      <View style={styles.container}>
        <ScreenHeader title="MANAGE CATEGORIES" neonColor={COLORS.neonViolet} onBack={() => router.back()} showBack />

        <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
          {showCreate && (
            <View style={styles.createForm}>
              <Text style={styles.formTitle}>CREATE NEW CATEGORY</Text>
              <InputField
                label="Category Name"
                value={newCategoryName}
                onChangeText={setNewCategoryName}
                placeholder="e.g., Video Games"
                neonColor={newCategoryColor}
              />
              <InputField
                label="Hint Prefix"
                value={newCategoryHint}
                onChangeText={setNewCategoryHint}
                placeholder="e.g., It's a game..."
                neonColor={newCategoryColor}
              />
              <View style={styles.colorPickerSection}>
                <Text style={styles.colorPickerLabel}>NEON COLOR</Text>
                <NeonColorPicker
                  selectedColor={newCategoryColor}
                  onSelect={setNewCategoryColor}
                  columns={5}
                />
              </View>
              <View style={styles.formActions}>
                <NeonButton
                  title="Cancel"
                  variant="ghost"
                  onPress={() => setShowCreate(false)}
                  neonColor={COLORS.textMuted}
                  style={styles.formActionButton}
                />
                <NeonButton
                  title="Create"
                  variant="primary"
                  onPress={handleCreate}
                  neonColor={newCategoryColor}
                  style={styles.formActionButton}
                />
              </View>
            </View>
          )}

          {!showCreate && (
            <NeonButton
              title="+ Create New Category"
              variant="secondary"
              onPress={() => setShowCreate(true)}
              neonColor={COLORS.neonViolet}
              fullWidth
              style={styles.createButton}
            />
          )}

          {builtinCategories.length > 0 && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>BUILT-IN CATEGORIES</Text>
              <View style={styles.categoryList}>
                {builtinCategories.map(category => (
                  <View key={category.id} style={styles.categoryItem}>
                    <View style={[
                      styles.categoryColorDot,
                      { backgroundColor: category.neonColor },
                    ]} />
                    <View style={styles.categoryInfo}>
                      <Text style={styles.categoryName}>{category.name}</Text>
                      <Text style={styles.categoryHint}>Hint: "{category.hintPrefix}"</Text>
                      <Text style={styles.categoryWordCount}>
                        {category.words.length} words
                      </Text>
                    </View>
                    <NeonButton
                      title="Words"
                      variant="ghost"
                      onPress={() => router.push(`/manage/words?category=${category.id}`)}
                      neonColor={category.neonColor}
                      style={styles.wordButton}
                    />
                  </View>
                ))}
              </View>
            </View>
          )}

          {customCategories.length > 0 && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>CUSTOM CATEGORIES</Text>
              <View style={styles.categoryList}>
                {customCategories.map(category => (
                  <View key={category.id} style={styles.categoryItem}>
                    <View style={[
                      styles.categoryColorDot,
                      { backgroundColor: category.neonColor },
                    ]} />
                    <View style={styles.categoryInfo}>
                      <Text style={styles.categoryName}>{category.name}</Text>
                      <Text style={styles.categoryHint}>Hint: "{category.hintPrefix}"</Text>
                      <Text style={styles.categoryWordCount}>
                        {category.words.length} words
                      </Text>
                    </View>
                    <View style={styles.categoryActions}>
                      <NeonButton
                        title="Words"
                        variant="ghost"
                        onPress={() => router.push(`/manage/words?category=${category.id}`)}
                        neonColor={category.neonColor}
                        style={styles.wordButton}
                      />
                      {editingCategory === category.id ? (
                        <EditCategoryForm
                          category={category}
                          onSave={(name, hint, color) => handleUpdate(category.id, name, hint, color)}
                          onCancel={() => setEditingCategory(null)}
                        />
                      ) : (
                        <NeonButton
                          title="Edit"
                          variant="ghost"
                          onPress={() => setEditingCategory(category.id)}
                          neonColor={category.neonColor}
                          style={styles.editButton}
                        />
                      )}
                      <NeonButton
                        title="Delete"
                        variant="danger"
                        onPress={() => handleDelete(category.id)}
                        neonColor={COLORS.error}
                        style={styles.deleteButton}
                      />
                    </View>
                  </View>
                ))}
              </View>
            </View>
          )}
        </ScrollView>
      </View>
    </SafeContainer>
  );
}

interface EditCategoryFormProps {
  category: Category;
  onSave: (name: string, hint: string, color: string) => void;
  onCancel: () => void;
}

const EditCategoryForm = React.memo(({ category, onSave, onCancel }: EditCategoryFormProps) => {
  const [name, setName] = useState(category.name);
  const [hint, setHint] = useState(category.hintPrefix);
  const [color, setColor] = useState(category.neonColor);

  return (
    <View style={styles.editForm}>
      <InputField
        label="Name"
        value={name}
        onChangeText={setName}
        neonColor={color}
      />
      <InputField
        label="Hint Prefix"
        value={hint}
        onChangeText={setHint}
        neonColor={color}
      />
      <View style={styles.colorPickerSection}>
        <Text style={styles.colorPickerLabel}>NEON COLOR</Text>
        <NeonColorPicker
          selectedColor={color}
          onSelect={setColor}
          columns={5}
        />
      </View>
      <View style={styles.formActions}>
        <NeonButton
          title="Cancel"
          variant="ghost"
          onPress={onCancel}
          neonColor={COLORS.textMuted}
          style={styles.formActionButton}
        />
        <NeonButton
          title="Save"
          variant="primary"
          onPress={() => onSave(name, hint, color)}
          neonColor={color}
          style={styles.formActionButton}
        />
      </View>
    </View>
  );
});

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: SPACING.lg,
    paddingBottom: SPACING.xxl,
    flexGrow: 1,
  },
  createForm: {
    marginBottom: SPACING.xl,
    padding: SPACING.lg,
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.xl,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  formTitle: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.sm,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 2,
    marginBottom: SPACING.lg,
  },
  colorPickerSection: {
    marginTop: SPACING.md,
    marginBottom: SPACING.md,
  },
  colorPickerLabel: {
    fontFamily: TYPOGRAPHY.fontFamily.bodyMedium,
    fontSize: TYPOGRAPHY.fontSize.xs,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: SPACING.sm,
  },
  formActions: {
    flexDirection: 'row',
    gap: SPACING.md,
    marginTop: SPACING.md,
  },
  formActionButton: {
    flex: 1,
  },
  createButton: {
    marginBottom: SPACING.xl,
  },
  section: {
    marginBottom: SPACING.xl,
  },
  sectionTitle: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.sm,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 2,
    marginBottom: SPACING.md,
  },
  categoryList: {
    gap: SPACING.md,
  },
  categoryItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: SPACING.md,
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    borderWidth: 1,
    borderColor: COLORS.border,
    gap: SPACING.md,
  },
  categoryColorDot: {
    width: 16,
    height: 16,
    borderRadius: 8,
  },
  categoryInfo: {
    flex: 1,
  },
  categoryName: {
    fontFamily: TYPOGRAPHY.fontFamily.headingMedium,
    fontSize: TYPOGRAPHY.fontSize.md,
    color: COLORS.textPrimary,
  },
  categoryHint: {
    fontFamily: TYPOGRAPHY.fontFamily.body,
    fontSize: TYPOGRAPHY.fontSize.xs,
    color: COLORS.textSecondary,
    marginTop: SPACING.xs,
  },
  categoryWordCount: {
    fontFamily: TYPOGRAPHY.fontFamily.body,
    fontSize: TYPOGRAPHY.fontSize.xs,
    color: COLORS.textMuted,
    marginTop: SPACING.xs,
  },
  categoryActions: {
    flexDirection: 'row',
    gap: SPACING.sm,
  },
  wordButton: {
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.xs,
  },
  editButton: {
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.xs,
  },
  deleteButton: {
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.xs,
  },
  editForm: {
    marginTop: SPACING.md,
    paddingTop: SPACING.md,
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
  },
});
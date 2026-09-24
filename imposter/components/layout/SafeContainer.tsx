import React from 'react';
import { SafeAreaView, KeyboardAvoidingView, Platform, StyleSheet, View } from 'react-native';
import { COLORS, SPACING } from '../../constants/theme';

interface SafeContainerProps {
  children: React.ReactNode;
  style?: any;
  avoidKeyboard?: boolean;
  flex?: boolean;
}

export const SafeContainer: React.FC<SafeContainerProps> = ({
  children,
  style,
  avoidKeyboard = true,
  flex = true,
}) => {
  const content = (
    <View style={[styles.container, flex && styles.flex, style]}>
      {children}
    </View>
  );

  if (avoidKeyboard && Platform.OS === 'ios') {
    return (
      <SafeAreaView style={styles.safeArea}>
        <KeyboardAvoidingView
          behavior="padding"
          style={styles.keyboardAvoiding}
          keyboardVerticalOffset={0}
        >
          {content}
        </KeyboardAvoidingView>
      </SafeAreaView>
    );
  }

  if (avoidKeyboard && Platform.OS === 'android') {
    return (
      <SafeAreaView style={styles.safeArea}>
        <KeyboardAvoidingView
          behavior="height"
          style={styles.keyboardAvoiding}
          keyboardVerticalOffset={0}
        >
          {content}
        </KeyboardAvoidingView>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      {content}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  keyboardAvoiding: {
    flex: 1,
  },
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  flex: {
    flex: 1,
  },
});
import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Pressable } from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import Animated, { useSharedValue, withSpring, useAnimatedStyle, runOnJS } from 'react-native-reanimated';
import { SafeContainer } from '../../components/layout/SafeContainer';
import { NeonButton } from '../../components/ui/NeonButton';
import { useGameStore } from '../../store/gameStore';
import { useGameFlow } from '../../hooks/useGameFlow';
import { useHaptics } from '../../hooks/useHaptics';
import { useSound } from '../../hooks/useSound';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY, CARD } from '../../constants/theme';

export default function RevealCardScreen() {
  const { player } = useLocalSearchParams<{ player: string }>();
  const playerIndex = parseInt(player || '0', 10);

  const { players, currentPlayerIndex, phase, settings } = useGameStore();
  const { beginReveal, proceedToNextPlayer } = useGameFlow();
  const { trigger: haptic } = useHaptics();
  const { play } = useSound();

  const currentPlayer = players[playerIndex];
  const isCurrentTurn = playerIndex === currentPlayerIndex;

  const [revealed, setRevealed] = useState(false);
  const [revealData, setRevealData] = useState<{ word: string; hint: string; isImposter: boolean } | null>(null);

  const flip = useSharedValue(0);
  const scale = useSharedValue(1);

  const cardStyle = useAnimatedStyle(() => ({
    transform: [
      { perspective: 1000 },
      { rotateY: `${flip.value}deg` },
      { scale: scale.value },
    ],
  }));

  const frontStyle = useAnimatedStyle(() => {
    const rotateY = flip.value;
    return {
      opacity: rotateY > 90 ? 0 : 1,
      transform: [
        { perspective: 1000 },
        { rotateY: `${rotateY}deg` },
      ],
      backfaceVisibility: 'hidden',
    };
  });

  const backStyle = useAnimatedStyle(() => {
    const rotateY = flip.value + 180;
    return {
      opacity: rotateY > 90 ? 0 : 1,
      transform: [
        { perspective: 1000 },
        { rotateY: `${rotateY}deg` },
      ],
      backfaceVisibility: 'hidden',
    };
  });

  useEffect(() => {
    if (isCurrentTurn && !revealed) {
      const data = beginReveal();
      setRevealData(data);
      flip.value = withSpring(180, { damping: 15, stiffness: 150 }, (finished) => {
        if (finished) {
          runOnJS(setRevealed)(true);
        }
      });
    } else if (!isCurrentTurn) {
      setRevealed(false);
      setRevealData(null);
      flip.value = 0;
    }
  }, [isCurrentTurn, playerIndex]);

  const handleCardPress = () => {
    if (!isCurrentTurn) return;
    if (!revealed) {
      const data = beginReveal();
      setRevealData(data);
      flip.value = withSpring(180, { damping: 15, stiffness: 150 }, (finished) => {
        if (finished) {
          runOnJS(setRevealed)(true);
        }
      });
    }
  };

  const handleNext = () => {
    const hasNext = proceedToNextPlayer();
    if (hasNext) {
      router.push(`/reveal/handoff?next=${playerIndex + 1}`);
    } else {
      router.push('/discussion/timer');
    }
  };

  if (!currentPlayer) {
    return null;
  }

  const isImposter = currentPlayer.role === 'imposter';
  const neonColor = settings.categoryId 
    ? useGameStore.getState().settings.categoryId 
    : 'movies';

  return (
    <SafeContainer avoidKeyboard={false}>
      <View style={styles.container}>
        <View style={styles.header}>
          <Text style={styles.playerLabel}>PLAYER {playerIndex + 1} OF {players.length}</Text>
          <Text style={[
            styles.playerName,
            { color: neonColor },
          ]}>
            {currentPlayer.name}
          </Text>
        </View>

        <View style={styles.cardContainer}>
          <Pressable onPress={handleCardPress}>
            <Animated.View style={[styles.card, cardStyle, styles.cardFaceContainer]}>
              <Animated.View style={[styles.cardFace, styles.front, frontStyle]}>
                <View style={styles.cardBack}>
                  <Text style={styles.cardBackText}>TAP TO REVEAL</Text>
                  <View style={styles.cardPattern}>
                    {[...Array(5)].map((_, i) => (
                      <View key={i} style={styles.patternLine} />
                    ))}
                  </View>
                </View>
              </Animated.View>

              <Animated.View style={[styles.cardFace, styles.back, backStyle]}>
                {revealData && (
                <View style={styles.revealedContent}>
                  {revealData.isImposter ? (
                    <View style={styles.imposterReveal}>
                      <Text style={styles.imposterLabel}>YOU ARE THE</Text>
                      <Text style={[
                        styles.imposterTitle,
                        { color: COLORS.error },
                      ]}>
                        IMPOSTER
                      </Text>
                      <View style={styles.hintContainer}>
                        <Text style={styles.hintLabel}>YOUR HINT:</Text>
                        <Text style={[
                          styles.hintText,
                          { color: COLORS.neonAmber },
                        ]}>
                          {revealData.hint}
                        </Text>
                      </View>
                    </View>
                  ) : (
                    <View style={styles.civilianReveal}>
                      <Text style={styles.wordLabel}>YOUR WORD:</Text>
                      <Text style={[
                        styles.wordText,
                        { color: neonColor },
                      ]}>
                        {revealData.word}
                      </Text>
                      <View style={styles.hintContainer}>
                        <Text style={styles.hintLabel}>CATEGORY:</Text>
                        <Text style={[
                          styles.hintText,
                          { color: COLORS.textSecondary },
                        ]}>
                          {revealData.hint}
                        </Text>
                      </View>
                    </View>
                  )}
                </View>
              )}
            </Animated.View>
          </Animated.View>
        </Pressable>
        </View>

        <View style={styles.instruction}>
          <Text style={styles.instructionText}>
            {revealed ? 'Memorize, then pass to next player' : 'Tap card to reveal your role'}
          </Text>
        </View>

        {revealed && isCurrentTurn && (
          <NeonButton
            title={playerIndex === players.length - 1 ? 'Start Discussion' : 'Pass to Next Player'}
            variant="primary"
            onPress={handleNext}
            neonColor={neonColor}
            fullWidth
            style={styles.nextButton}
          />
        )}
      </View>
    </SafeContainer>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingHorizontal: SPACING.lg,
    justifyContent: 'center',
  },
  header: {
    alignItems: 'center',
    marginBottom: SPACING.xl,
  },
  playerLabel: {
    fontFamily: TYPOGRAPHY.fontFamily.body,
    fontSize: TYPOGRAPHY.fontSize.xs,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 2,
    marginBottom: SPACING.xs,
  },
  playerName: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.xxl,
    textAlign: 'center',
  },
  cardContainer: {
    alignItems: 'center',
    marginBottom: SPACING.xl,
  },
  card: {
    width: CARD.width,
    height: CARD.height,
    maxWidth: CARD.maxWidth,
    maxHeight: CARD.maxHeight,
    borderRadius: CARD.borderRadius,
  },
  cardFaceContainer: {
    width: CARD.width,
    height: CARD.height,
    maxWidth: CARD.maxWidth,
    maxHeight: CARD.maxHeight,
    borderRadius: CARD.borderRadius,
  },
  cardFace: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    borderRadius: CARD.borderRadius,
    backgroundColor: COLORS.surfaceElevated,
    borderWidth: 2,
    borderColor: COLORS.border,
    justifyContent: 'center',
    alignItems: 'center',
    padding: CARD.borderRadius,
  },
  front: {
    zIndex: 2,
  },
  back: {
    zIndex: 1,
  },
  cardBack: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  cardBackText: {
    fontFamily: TYPOGRAPHY.fontFamily.headingMedium,
    fontSize: TYPOGRAPHY.fontSize.lg,
    color: COLORS.textSecondary,
    marginBottom: SPACING.lg,
  },
  cardPattern: {
    width: '100%',
    height: '100%',
    justifyContent: 'space-between',
  },
  patternLine: {
    height: 1,
    backgroundColor: COLORS.borderLight,
    borderRadius: 1,
  },
  revealedContent: {
    width: '100%',
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
    padding: SPACING.lg,
  },
  imposterReveal: {
    alignItems: 'center',
  },
  imposterLabel: {
    fontFamily: TYPOGRAPHY.fontFamily.bodyMedium,
    fontSize: TYPOGRAPHY.fontSize.md,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 2,
    marginBottom: SPACING.sm,
  },
  imposterTitle: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.xxxl,
    textAlign: 'center',
    lineHeight: TYPOGRAPHY.fontSize.xxxl * 1.1,
    marginBottom: SPACING.xl,
  },
  civilianReveal: {
    alignItems: 'center',
  },
  wordLabel: {
    fontFamily: TYPOGRAPHY.fontFamily.bodyMedium,
    fontSize: TYPOGRAPHY.fontSize.md,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 2,
    marginBottom: SPACING.sm,
  },
  wordText: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.xxxl,
    textAlign: 'center',
    lineHeight: TYPOGRAPHY.fontSize.xxxl * 1.1,
    marginBottom: SPACING.xl,
  },
  hintContainer: {
    alignItems: 'center',
    paddingTop: SPACING.lg,
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
    width: '100%',
  },
  hintLabel: {
    fontFamily: TYPOGRAPHY.fontFamily.bodyMedium,
    fontSize: TYPOGRAPHY.fontSize.sm,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: SPACING.xs,
  },
  hintText: {
    fontFamily: TYPOGRAPHY.fontFamily.headingMedium,
    fontSize: TYPOGRAPHY.fontSize.lg,
    textAlign: 'center',
  },
  instruction: {
    alignItems: 'center',
    marginBottom: SPACING.xl,
    paddingHorizontal: SPACING.lg,
  },
  instructionText: {
    fontFamily: TYPOGRAPHY.fontFamily.body,
    fontSize: TYPOGRAPHY.fontSize.sm,
    color: COLORS.textMuted,
    textAlign: 'center',
  },
  nextButton: {
    marginTop: SPACING.md,
    maxWidth: 320,
  },
});
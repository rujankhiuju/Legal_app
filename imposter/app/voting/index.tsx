import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { SafeContainer } from '../../components/layout/SafeContainer';
import { ScreenHeader } from '../../components/layout/ScreenHeader';
import { NeonButton } from '../../components/ui/NeonButton';
import { VoteButton } from '../../components/ui/VoteButton';
import { useGameStore } from '../../store/gameStore';
import { useHaptics } from '../../hooks/useHaptics';
import { useSound } from '../../hooks/useSound';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY } from '../../constants/theme';

export default function VotingScreen() {
  const { players, settings, phase, setPhase } = useGameStore();
  const { trigger: haptic } = useHaptics();
  const { play } = useSound();

  const [voted, setVoted] = useState(false);
  const [showResults, setShowResults] = useState(false);
  const [revealIndex, setRevealIndex] = useState(0);

  const alivePlayers = players.filter(p => !p.hasVoted || showResults);
  const allVoted = players.every(p => p.hasVoted);

  useEffect(() => {
    if (allVoted && !voted) {
      setVoted(true);
    }
  }, [allVoted, voted]);

  useEffect(() => {
    if (showResults) {
      const timer = setInterval(() => {
        setRevealIndex((prev) => {
          if (prev >= players.length - 1) {
            clearInterval(timer);
            return prev;
          }
          return prev + 1;
        });
      }, 600);
      return () => clearInterval(timer);
    }
  }, [showResults, players.length]);

  const handleVote = (voterId: number, targetId: number) => {
    if (voted || showResults) return;
    
    useGameStore.getState().setVote(voterId, targetId);
    useGameStore.getState().incrementVotes(targetId);
    haptic('light');
    play('voteSubmit');
  };

  const handleReveal = () => {
    if (!allVoted) return;
    setShowResults(true);
    haptic('heavy');
    play('reveal');
  };

  const handleFinish = () => {
    router.push('/results');
  };

  const sortedPlayers = [...players].sort((a, b) => b.votesReceived - a.votesReceived);

  return (
    <SafeContainer avoidKeyboard={false}>
      <View style={styles.container}>
        <ScreenHeader 
          title="VOTING" 
          neonColor={COLORS.neonPink}
        />
        
        <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
          <View style={styles.playersList}>
            {sortedPlayers.map((player, index) => (
              <VoteButton
                key={player.id}
                playerName={player.name}
                isSelected={false}
                voteCount={player.votesReceived}
                onPress={() => handleVote(player.id, player.id)}
                disabled={voted || showResults}
                isRevealing={showResults && revealIndex >= index}
                revealRole={showResults && revealIndex >= index ? player.role : undefined}
                neonColor={COLORS.neonPink}
              />
            ))}
          </View>

          {!showResults && !allVoted && (
            <Text style={styles.instruction}>
              Tap a player to vote for them
            </Text>
          )}

          {!showResults && allVoted && (
            <NeonButton
              title="Reveal Votes"
              variant="primary"
              onPress={handleReveal}
              neonColor={COLORS.neonPink}
              fullWidth
              style={styles.revealButton}
            />
          )}

          {showResults && (
            <NeonButton
              title="See Results"
              variant="primary"
              onPress={handleFinish}
              neonColor={COLORS.neonPink}
              fullWidth
              style={styles.revealButton}
            />
          )}
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
  playersList: {
    marginBottom: SPACING.xl,
  },
  instruction: {
    textAlign: 'center',
    fontFamily: TYPOGRAPHY.fontFamily.body,
    fontSize: TYPOGRAPHY.fontSize.md,
    color: COLORS.textMuted,
    marginBottom: SPACING.xl,
    paddingHorizontal: SPACING.lg,
  },
  revealButton: {
    marginTop: SPACING.lg,
    maxWidth: 320,
    alignSelf: 'center',
  },
});
import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert } from 'react-native';
import { router } from 'expo-router';
import { SafeContainer } from '../../components/layout/SafeContainer';
import { NeonButton } from '../../components/ui/NeonButton';
import { ScoreRow } from '../../components/ui/ScoreRow';
import { useGameStore } from '../../store/gameStore';
import { useScoreStore } from '../../store/scoreStore';
import { useSettingsStore } from '../../store/settingsStore';
import { useHaptics } from '../../hooks/useHaptics';
import { useSound } from '../../hooks/useSound';
import { calculateRoundScores, determineWinner } from '../../utils/scoring';
import { COLORS, SPACING, RADIUS, TYPOGRAPHY } from '../../constants/theme';

export default function ResultsScreen() {
  const { 
    players, 
    settings, 
    round, 
    phase, 
    resetGame, 
    resetSession,
    setPlayers,
  } = useGameStore();
  const { sessionScores, addSessionScore, resetSessionScores, saveGameToHistory } = useScoreStore();
  const { firstLaunch, setFirstLaunch } = useSettingsStore();
  const { trigger: haptic } = useHaptics();
  const { play } = useSound();

  const [scored, setScored] = useState(false);
  const [winner, setWinner] = useState<'imposters' | 'civilians'>('civilians');

  useEffect(() => {
    if (!scored) {
      const updatedPlayers = calculateRoundScores(players, settings);
      const gameWinner = determineWinner(updatedPlayers);
      
      setPlayers(updatedPlayers);
      setWinner(gameWinner);
      
      const scores = updatedPlayers.map(p => ({
        playerId: p.id,
        playerName: p.name,
        totalScore: p.totalScore,
        roundsPlayed: round,
      }));
      
      saveGameToHistory(settings, scores, gameWinner);
      setScored(true);
      
      haptic(gameWinner === 'imposters' ? 'warning' : 'success');
      play(gameWinner === 'imposters' ? 'lose' : 'win');
    }
  }, [scored, players, settings, round]);

  const handleNextRound = () => {
    setScored(false);
    resetGame();
    router.push('/reveal/card');
  };

  const handleEndParty = () => {
    Alert.alert(
      'End Party?',
      'This will reset all scores and start a new session.',
      [
        { text: 'Cancel', style: 'cancel' },
        { 
          text: 'End Party', 
          style: 'destructive',
          onPress: () => {
            resetSession();
            resetSessionScores();
            setFirstLaunch(false);
            router.replace('/');
          }
        },
      ]
    );
  };

  const imposters = players.filter(p => p.role === 'imposter');
  const winnerColor = winner === 'imposters' ? COLORS.error : COLORS.success;
  const winnerText = winner === 'imposters' ? 'IMPOSTERS WIN' : 'CIVILIANS WIN';

  const sortedPlayers = [...players].sort((a, b) => b.totalScore - a.totalScore);

  return (
    <SafeContainer avoidKeyboard={false}>
      <View style={styles.container}>
        <View style={styles.header}>
          <View style={[styles.winnerBanner, { backgroundColor: `${winnerColor}33`, borderColor: winnerColor }]}>
            <Text style={[styles.winnerText, { color: winnerColor }]}>
              {winnerText}
            </Text>
            <Text style={styles.roundText}>
              Round {round} Complete
            </Text>
          </View>
        </View>

        <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
          <View style={styles.reveals}>
            {players.map((player, index) => (
              <View key={player.id} style={styles.revealCard}>
                <View style={[
                  styles.revealRole,
                  { backgroundColor: player.role === 'imposter' ? COLORS.error : COLORS.success },
                ]}>
                  <Text style={styles.revealRoleText}>
                    {player.role.toUpperCase()}
                  </Text>
                </View>
                <Text style={styles.revealName}>{player.name}</Text>
                <Text style={styles.revealWord}>
                  {player.role === 'imposter' ? '—' : player.word}
                </Text>
                <Text style={[
                  styles.revealVotes,
                  { color: player.votesReceived > 0 ? COLORS.neonPink : COLORS.textMuted },
                ]}>
                  {player.votesReceived} vote{player.votesReceived !== 1 ? 's' : ''}
                </Text>
              </View>
            ))}
          </View>

          <View style={styles.scoresSection}>
            <Text style={styles.sectionTitle}>SCORES</Text>
            {sortedPlayers.map((player, index) => (
              <ScoreRow
                key={player.id}
                playerName={player.name}
                totalScore={player.totalScore}
                roundScore={player.roundScore}
                role={player.role}
                isWinner={player.role === (winner === 'imposters' ? 'imposter' : 'civilian') && player.votesReceived === 0}
                neonColor={winnerColor}
                index={index}
              />
            ))}
          </View>
        </ScrollView>

        <View style={styles.actions}>
          <NeonButton
            title="Next Round"
            variant="primary"
            onPress={handleNextRound}
            neonColor={winnerColor}
            style={styles.actionButton}
          />
          <NeonButton
            title="End Party"
            variant="ghost"
            onPress={handleEndParty}
            neonColor={COLORS.textMuted}
            style={styles.actionButton}
          />
        </View>
      </View>
    </SafeContainer>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    paddingHorizontal: SPACING.lg,
    paddingTop: SPACING.lg,
    paddingBottom: SPACING.xl,
  },
  winnerBanner: {
    padding: SPACING.xl,
    borderRadius: RADIUS.xl,
    borderWidth: 2,
    alignItems: 'center',
  },
  winnerText: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.xxxl,
    textAlign: 'center',
    lineHeight: TYPOGRAPHY.fontSize.xxxl * 1.1,
    marginBottom: SPACING.sm,
  },
  roundText: {
    fontFamily: TYPOGRAPHY.fontFamily.bodyMedium,
    fontSize: TYPOGRAPHY.fontSize.md,
    color: COLORS.textSecondary,
  },
  scrollContent: {
    paddingHorizontal: SPACING.lg,
    paddingBottom: SPACING.xxl,
  },
  reveals: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: SPACING.md,
    justifyContent: 'center',
    marginBottom: SPACING.xl,
  },
  revealCard: {
    width: 140,
    padding: SPACING.md,
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    borderWidth: 1,
    borderColor: COLORS.border,
    alignItems: 'center',
  },
  revealRole: {
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.xs,
    borderRadius: RADIUS.full,
    marginBottom: SPACING.sm,
  },
  revealRoleText: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.xs,
    color: COLORS.textOnNeon,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  revealName: {
    fontFamily: TYPOGRAPHY.fontFamily.headingMedium,
    fontSize: TYPOGRAPHY.fontSize.md,
    color: COLORS.textPrimary,
    marginBottom: SPACING.xs,
  },
  revealWord: {
    fontFamily: TYPOGRAPHY.fontFamily.body,
    fontSize: TYPOGRAPHY.fontSize.sm,
    color: COLORS.textSecondary,
    marginBottom: SPACING.xs,
  },
  revealVotes: {
    fontFamily: TYPOGRAPHY.fontFamily.bodyMedium,
    fontSize: TYPOGRAPHY.fontSize.xs,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  scoresSection: {
    marginTop: SPACING.xl,
  },
  sectionTitle: {
    fontFamily: TYPOGRAPHY.fontFamily.heading,
    fontSize: TYPOGRAPHY.fontSize.sm,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 2,
    marginBottom: SPACING.md,
  },
  actions: {
    paddingHorizontal: SPACING.lg,
    paddingVertical: SPACING.lg,
    gap: SPACING.md,
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
  },
  actionButton: {
    width: '100%',
    maxWidth: 320,
    alignSelf: 'center',
  },
});
import { useGameStore } from '../store/gameStore';
import { useCategoryStore } from '../store/categoryStore';
import { useScoreStore } from '../store/scoreStore';
import { useSettingsStore } from '../store/settingsStore';
import { useWordPicker } from './useWordPicker';
import { useHaptics } from './useHaptics';
import { useSound } from './useSound';
import { calculateRoundScores, determineWinner } from '../utils/scoring';
import { validateSettings } from '../utils/validation';

export const useGameFlow = () => {
  const {
    settings,
    players,
    phase,
    round,
    currentPlayerIndex,
    setPhase,
    setPlayers,
    setCurrentPlayerIndex,
    setRound,
    assignRoles,
    resetGame,
    resetSession,
    calculateScores: storeCalculateScores,
    nextPlayer,
  } = useGameStore();

  const { pickWord, getHintForImposter } = useWordPicker();
  const { trigger: haptic } = useHaptics();
  const { play: playSound } = useSound();
  const { sessionScores, addSessionScore, resetSessionScores, saveGameToHistory } = useScoreStore();
  const { firstLaunch, setFirstLaunch } = useSettingsStore();

  const startGame = (): { valid: boolean; errors: string[] } => {
    const validation = validateSettings(settings);
    if (!validation.valid) {
      return validation;
    }

    const newPlayers = players.map((p, i) => ({
      ...p,
      id: i,
      name: p.name || `Player ${i + 1}`,
      totalScore: sessionScores[i]?.totalScore ?? 0,
    }));

    setPlayers(newPlayers);
    assignRoles();
    setPhase('reveal');
    setCurrentPlayerIndex(0);
    setRound(1);

    return { valid: true, errors: [] };
  };

  const beginReveal = (): { word: string; hint: string; isImposter: boolean } => {
    const currentPlayer = players[currentPlayerIndex];
    const { word, hint } = pickWord();
    const isImposter = currentPlayer.role === 'imposter';

    haptic('medium');
    playSound('flip');

    return {
      word: isImposter ? '' : word,
      hint: isImposter ? getHintForImposter() : hint,
      isImposter,
    };
  };

  const proceedToNextPlayer = (): boolean => {
    const hasNext = nextPlayer();
    if (!hasNext) {
      haptic('heavy');
      playSound('reveal');
      setPhase('discussion');
    } else {
      haptic('light');
    }
    return hasNext;
  };

  const startDiscussion = () => {
    setPhase('discussion');
  };

  const startVoting = () => {
    setPhase('voting');
  };

  const castVote = (voterId: number, targetId: number) => {
    useGameStore.getState().setVote(voterId, targetId);
    useGameStore.getState().incrementVotes(targetId);
    haptic('light');
    playSound('voteSubmit');
  };

  const finishVoting = () => {
    storeCalculateScores();
    const winner = determineWinner(useGameStore.getState().players);
    
    const updatedPlayers = useGameStore.getState().players;
    const scores: Array<{ playerId: number; playerName: string; totalScore: number; roundsPlayed: number }> = 
      updatedPlayers.map((p) => ({
        playerId: p.id,
        playerName: p.name,
        totalScore: p.totalScore,
        roundsPlayed: round,
      }));

    saveGameToHistory(settings, scores, winner);
    
    haptic(winner === 'imposters' ? 'warning' : 'success');
    playSound(winner === 'imposters' ? 'lose' : 'win');
    
    setPhase('results');
  };

  const nextRound = () => {
    resetGame();
    haptic('medium');
  };

  const endParty = () => {
    resetSession();
    resetSessionScores();
    setFirstLaunch(false);
    haptic('heavy');
  };

  const checkFirstLaunch = () => firstLaunch;

  return {
    startGame,
    beginReveal,
    proceedToNextPlayer,
    startDiscussion,
    startVoting,
    castVote,
    finishVoting,
    nextRound,
    endParty,
    checkFirstLaunch,
  };
};
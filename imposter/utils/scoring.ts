import { Player, GameSettings } from '../types';
import { GAME_CONSTANTS } from '../constants/game';

export const calculateRoundScores = (
  players: Player[],
  settings: GameSettings
): Player[] => {
  const imposters = players.filter((p) => p.role === 'imposter');
  const impostersCaught = imposters.filter((p) => p.votesReceived > 0);
  const imposterWon = impostersCaught.length === 0;

  return players.map((p) => {
    let roundScore = 0;
    if (p.role === 'imposter') {
      roundScore = imposterWon ? GAME_CONSTANTS.SCORE_IMPOSTER_WIN : 0;
    } else {
      roundScore = imposterWon ? 0 : GAME_CONSTANTS.SCORE_CIVILIAN_WIN;
      const votedForImposter = p.voteTarget && imposters.some((i) => i.id === p.voteTarget);
      if (votedForImposter) {
        roundScore += GAME_CONSTANTS.SCORE_CORRECT_VOTE_BONUS;
      }
    }
    return {
      ...p,
      roundScore,
      totalScore: p.totalScore + roundScore,
    };
  });
};

export const determineWinner = (players: Player[]): 'imposters' | 'civilians' => {
  const imposters = players.filter((p) => p.role === 'imposter');
  const impostersCaught = imposters.filter((p) => p.votesReceived > 0);
  return impostersCaught.length === 0 ? 'imposters' : 'civilians';
};

export const formatScore = (score: number): string => {
  return score % 1 === 0 ? score.toString() : score.toFixed(1);
};
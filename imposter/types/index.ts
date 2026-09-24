export interface Category {
  id: string;
  name: string;
  neonColor: string;
  hintPrefix: string;
  words: string[];
  isCustom: boolean;
}

export interface Player {
  id: number;
  name: string;
  role: 'civilian' | 'imposter';
  word?: string;
  hint?: string;
  votesReceived: number;
  hasVoted: boolean;
  voteTarget?: number;
  roundScore: number;
  totalScore: number;
}

export interface GameSettings {
  playerCount: number;
  imposterCount: number;
  categoryId: string;
  roundTimerSeconds: number;
  enableSounds: boolean;
  enableHaptics: boolean;
  enableAccessibility: boolean;
}

export interface GameState {
  settings: GameSettings;
  players: Player[];
  currentPlayerIndex: number;
  phase: GamePhase;
  round: number;
  secretWord: string;
  categoryHint: string;
  usedWords: string[];
}

export type GamePhase = 'setup' | 'reveal' | 'discussion' | 'voting' | 'results';

export interface StoredSettings {
  enableSounds: boolean;
  enableHaptics: boolean;
  enableAccessibility: boolean;
  firstLaunch: boolean;
}

export interface StoredCategories {
  categories: Category[];
}

export interface SessionScore {
  playerId: number;
  playerName: string;
  totalScore: number;
  roundsPlayed: number;
}

export interface GameHistoryEntry {
  id: string;
  date: number;
  settings: GameSettings;
  scores: SessionScore[];
  winner: 'imposters' | 'civilians';
}
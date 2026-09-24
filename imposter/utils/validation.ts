import { GameSettings } from '../types';
import { GAME_CONSTANTS } from '../constants/game';

export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

export const validateSettings = (settings: GameSettings): ValidationResult => {
  const errors: string[] = [];
  const warnings: string[] = [];

  if (settings.playerCount < GAME_CONSTANTS.MIN_PLAYERS) {
    errors.push(`Minimum ${GAME_CONSTANTS.MIN_PLAYERS} players required`);
  }
  if (settings.playerCount > GAME_CONSTANTS.MAX_PLAYERS) {
    errors.push(`Maximum ${GAME_CONSTANTS.MAX_PLAYERS} players allowed`);
  }

  if (settings.imposterCount < GAME_CONSTANTS.MIN_IMPOSTERS) {
    errors.push(`Minimum ${GAME_CONSTANTS.MIN_IMPOSTERS} imposter required`);
  }
  if (settings.imposterCount > GAME_CONSTANTS.MAX_IMPOSTERS) {
    errors.push(`Maximum ${GAME_CONSTANTS.MAX_IMPOSTERS} imposters allowed`);
  }
  if (settings.imposterCount >= settings.playerCount) {
    errors.push('Imposters must be fewer than total players');
  }
  if (settings.imposterCount > settings.playerCount / 2) {
    warnings.push('Many imposters - game may be very difficult for civilians');
  }

  if (settings.roundTimerSeconds < GAME_CONSTANTS.MIN_TIMER_SECONDS) {
    errors.push(`Timer must be at least ${GAME_CONSTANTS.MIN_TIMER_SECONDS} seconds`);
  }
  if (settings.roundTimerSeconds > GAME_CONSTANTS.MAX_TIMER_SECONDS) {
    errors.push(`Timer cannot exceed ${GAME_CONSTANTS.MAX_TIMER_SECONDS} seconds`);
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  };
};

export const validatePlayerName = (name: string): ValidationResult => {
  const errors: string[] = [];
  if (name.length > GAME_CONSTANTS.MAX_CUSTOM_NAME_LENGTH) {
    errors.push(`Name must be ${GAME_CONSTANTS.MAX_CUSTOM_NAME_LENGTH} characters or fewer`);
  }
  if (!name.trim()) {
    errors.push('Name cannot be empty');
  }
  return { valid: errors.length === 0, errors, warnings: [] };
};

export const validateCustomWord = (word: string, existingWords: string[]): ValidationResult => {
  const errors: string[] = [];
  const warnings: string[] = [];

  const trimmed = word.trim();
  if (!trimmed) {
    errors.push('Word cannot be empty');
  }
  if (trimmed.length > 30) {
    errors.push('Word must be 30 characters or fewer');
  }
  if (existingWords.some((w) => w.toLowerCase() === trimmed.toLowerCase())) {
    errors.push('This word already exists in the category');
  }

  return { valid: errors.length === 0, errors, warnings };
};
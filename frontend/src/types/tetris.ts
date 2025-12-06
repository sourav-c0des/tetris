/**
 * Simple TypeScript types for Tetris Game
 * =======================================
 * Minimal type definitions matching our simplified backend.
 */

export interface Cell {
  x: number;
  y: number;
}

export interface Move {
  piece_type: string;
  column: number;
  height_after: number;
  rows_cleared: number[];
}

export interface GameState {
  sequence: string;
  current_step: number;
  grid: Cell[];
  moves_history: Move[];
  current_height: number;
  status: string;
}

export interface SequenceInfo {
  sequence: string;
  expected_height: number;
  piece_count: number;
}

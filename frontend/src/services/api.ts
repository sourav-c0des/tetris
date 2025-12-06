/**
 * Simple API service for Tetris Game
 * ===================================
 * Direct HTTP calls to our simplified backend.
 * No unnecessary abstractions - just fetch calls.
 */

const API_BASE_URL = (import.meta as any).env.VITE_API_BASE_URL || 'http://localhost:8000';

export const tetrisApi = {
  // Get all available sequences
  getSequences: async () => {
    const response = await fetch(`${API_BASE_URL}/sequences`);
    if (!response.ok) throw new Error('Failed to fetch sequences');
    return response.json();
  },

  // Create a new game
  createGame: async (sequence: string) => {
    const response = await fetch(`${API_BASE_URL}/game/start`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ sequence })
    });
    if (!response.ok) throw new Error('Failed to create game');
    return response.json();
  },

  // Execute next move
  nextMove: async (gameId: string) => {
    const response = await fetch(`${API_BASE_URL}/game/${gameId}/next`, {
      method: 'POST'
    });
    if (!response.ok) throw new Error('Failed to execute move');
    return response.json();
  },

  // Get current game state
  getGameState: async (gameId: string) => {
    const response = await fetch(`${API_BASE_URL}/game/${gameId}`);
    if (!response.ok) throw new Error('Failed to get game state');
    return response.json();
  }
};

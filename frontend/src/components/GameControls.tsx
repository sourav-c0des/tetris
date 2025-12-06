import React from 'react';
import { GameState } from '../types/tetris';

interface GameControlsProps {
  gameState: GameState | null;
  onNextMove: () => void;
  onReset: () => void;
  isLoading: boolean;
}

export const GameControls: React.FC<GameControlsProps> = ({
  gameState,
  onNextMove,
  onReset,
  isLoading,
}) => {
  const canExecuteNext = gameState && gameState.status !== 'completed';

  return (
    <div className="bg-gray-800 p-6 rounded-lg">
      <h2 className="font-bold mb-4" style={{ fontSize: '1.25rem' }}>Game Controls</h2>
      
      {gameState && (
        <div className="mb-4 space-y-2">
          <div className="text-sm">
            <span className="font-semibold">Sequence:</span> {gameState.sequence}
          </div>
          <div className="text-sm">
            <span className="font-semibold">Progress:</span> {gameState.current_step} / {gameState.sequence.split(',').length}
          </div>
          <div className="text-sm">
            <span className="font-semibold">Current Height:</span> {gameState.current_height}
          </div>
          <div className="text-sm">
            <span className="font-semibold">Status:</span> 
            <span className={`ml-1 px-2 py-1 rounded text-xs ${
              gameState.status === 'completed' ? 'bg-green-600' :
              gameState.status === 'in_progress' ? 'bg-blue-600' :
              'bg-gray-600'
            }`}>
              {gameState.status.replace('_', ' ').toUpperCase()}
            </span>
          </div>
          {(() => {
            // Parse the next piece from sequence and current_step
            const moves = gameState.sequence.split(',').map(move => move.trim());
            const nextMove = moves[gameState.current_step];
            if (nextMove && nextMove.length >= 2) {
              const piece = nextMove[0].toUpperCase();
              const column = nextMove.slice(1);
              return (
                <div className="text-sm">
                  <span className="font-semibold">Next Piece:</span> {piece} at column {column}
                </div>
              );
            }
            return null;
          })()}
        </div>
      )}

      <div className="flex gap-3">
        <button
          onClick={onNextMove}
          disabled={!canExecuteNext || isLoading}
          className={canExecuteNext && !isLoading ? 'btn-primary' : ''}
          style={{
            backgroundColor: canExecuteNext && !isLoading ? '#2563eb' : '#666',
            color: canExecuteNext && !isLoading ? 'white' : '#999'
          }}
        >
          {isLoading ? 'Processing...' : 'Next Move'}
        </button>

        <button
          onClick={onReset}
          disabled={isLoading}
          className="btn-secondary"
          style={{
            backgroundColor: isLoading ? '#666' : '#dc2626',
            color: isLoading ? '#999' : 'white'
          }}
        >
          Reset Game
        </button>
      </div>

      {gameState?.status === 'completed' && (
        <div className="mt-4 p-3 bg-green-900 border border-green-600 rounded">
          <h3 className="font-bold text-green-200">Game Completed!</h3>
          <p className="text-green-300 text-sm">Final height: {gameState.current_height}</p>
        </div>
      )}
    </div>
  );
};

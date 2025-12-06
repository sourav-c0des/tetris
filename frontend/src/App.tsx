import { useState } from 'react';
import { QueryClient, QueryClientProvider, useQuery, useMutation } from '@tanstack/react-query';
import { TetrisGrid } from './components/TetrisGrid';
import { GameControls } from './components/GameControls';
import { SequenceSelector } from './components/SequenceSelector';
import { tetrisApi } from './services/api';
import { GameState } from './types/tetris';
import './index.css';

const queryClient = new QueryClient();

function TetrisGame() {
  const [currentGame, setCurrentGame] = useState<GameState | null>(null);
  const [gameId, setGameId] = useState<string | null>(null);

  // Fetch available sequences
  const { data: sequencesData, isLoading: sequencesLoading } = useQuery({
    queryKey: ['sequences'],
    queryFn: tetrisApi.getSequences,
  });

  // Create game mutation
  const createGameMutation = useMutation({
    mutationFn: tetrisApi.createGame,
    onSuccess: (data) => {
      setCurrentGame(data.state);
      setGameId(data.game_id);
    },
    onError: (error) => {
      console.error('Failed to create game:', error);
      alert('Failed to create game. Please check if the backend is running.');
    },
  });

  // Next move mutation
  const nextMoveMutation = useMutation({
    mutationFn: (gameId: string) => tetrisApi.nextMove(gameId),
    onSuccess: (data) => {
      setCurrentGame(data.state);
    },
    onError: (error) => {
      console.error('Failed to execute move:', error);
      alert('Failed to execute move.');
    },
  });

  const handleSelectSequence = (sequence: string) => {
    createGameMutation.mutate(sequence);
  };

  const handleNextMove = () => {
    if (gameId) {
      nextMoveMutation.mutate(gameId);
    }
  };

  const handleReset = () => {
    setCurrentGame(null);
    setGameId(null);
  };

  const isLoading = createGameMutation.isPending || nextMoveMutation.isPending;

  return (
    <div className="bg-gray-900 text-white" style={{ minHeight: '100vh' }}>
      <div className="container">
        <header className="text-center mb-4">
          <h1 className="font-bold mb-4" style={{ fontSize: '2rem' }}>Tetris Game</h1>
        </header>

        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '20px' }}>
          {/* Sequence Selection Panel */}
          <div style={{ width: '100%', maxWidth: '600px' }}>
            {!currentGame ? (
              <SequenceSelector
                sequences={sequencesData?.sequences || []}
                onSelectSequence={handleSelectSequence}
                isLoading={isLoading || sequencesLoading}
              />
            ) : (
              <GameControls
                gameState={currentGame}
                onNextMove={handleNextMove}
                onReset={handleReset}
                isLoading={isLoading}
              />
            )}
          </div>

          {/* Game Grid Panel */}
          <div>
            <div className="text-center">
              {currentGame && (
                <TetrisGrid
                  grid={currentGame.grid}
                  width={10}
                  height={14}
                  className=""
                />
              )}
            </div>
          </div>
        </div>


      </div>
    </div>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <TetrisGame />
    </QueryClientProvider>
  );
}

export default App;

"""
Simple FastAPI backend for Tetris Game
=====================================
This is a minimal, single-file backend implementation.
No unnecessary abstractions - just the core API endpoints.
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
import os
from typing import List, Dict

# Import our simple tetris game
from tetris_game import TetrisGame, calculate_final_height

# Create FastAPI app
app = FastAPI(title="Tetris Game", root_path="/api")

# Enable CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "*",
        "http://localhost:3000",
        "http://localhost:8080",
        "http://aae209c7b115a447c90f37d7272ee388-799182124.us-west-2.elb.amazonaws.com"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Store active games (in production, use a database)
active_games: Dict[str, TetrisGame] = {}

# Request/Response models
class StartGameRequest(BaseModel):
    sequence: str

class SequenceData(BaseModel):
    sequence: str
    expected_height: int
    piece_count: int

class SequencesResponse(BaseModel):
    sequences: List[SequenceData]

# Load predefined sequences from input.txt
def load_sequences() -> List[SequenceData]:
    """Load sequences from input.txt file."""
    sequences = []
    input_file = os.path.join(os.path.dirname(__file__), "input.txt")
    
    try:
        with open(input_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    try:
                        height = calculate_final_height(line)
                        piece_count = len(line.split(',')) if line else 0
                        sequences.append(SequenceData(
                            sequence=line,
                            expected_height=height,
                            piece_count=piece_count
                        ))
                    except Exception:
                        continue  # Skip invalid sequences
    except FileNotFoundError:
        # Return some default sequences if file not found
        default_sequences = ["Q0", "Q0,Q1", "I0,I4", "Q0,Q2,Q4,Q6,Q8"]
        for seq in default_sequences:
            try:
                height = calculate_final_height(seq)
                piece_count = len(seq.split(','))
                sequences.append(SequenceData(
                    sequence=seq,
                    expected_height=height,
                    piece_count=piece_count
                ))
            except Exception:
                continue
    
    return sequences

# API Endpoints
@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "Tetris Game Backend"}

@app.get("/sequences", response_model=SequencesResponse)
async def get_sequences():
    """Get all available sequences."""
    sequences = load_sequences()
    return SequencesResponse(sequences=sequences)

@app.post("/game/start")
async def start_game(request: StartGameRequest):
    """Start a new game with given sequence."""
    try:
        game = TetrisGame(request.sequence)
        game_id = f"game_{len(active_games)}"
        active_games[game_id] = game
        
        return {
            "game_id": game_id,
            "state": game.get_state()
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid sequence: {str(e)}")

@app.post("/game/{game_id}/next")
async def next_move(game_id: str):
    """Execute next move in the game."""
    if game_id not in active_games:
        raise HTTPException(status_code=404, detail="Game not found")
    
    try:
        game = active_games[game_id]
        state = game.next_move()
        return {"state": state}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Move failed: {str(e)}")

@app.get("/game/{game_id}")
async def get_game_state(game_id: str):
    """Get current game state."""
    if game_id not in active_games:
        raise HTTPException(status_code=404, detail="Game not found")
    
    game = active_games[game_id]
    return {"state": game.get_state()}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

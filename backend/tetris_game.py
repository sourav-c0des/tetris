"""
Simple Tetris Game Engine
========================
This is a simplified, single-file implementation of the Tetris game logic.
No unnecessary abstractions - just the core game functionality.
"""
from typing import List, Set, Tuple, Dict
from dataclasses import dataclass

# Constants
WIDTH = 10

# Tetris piece shapes (relative to bottom-left anchor)
SHAPES: Dict[str, List[Tuple[int, int]]] = {
    "Q": [(0, 0), (1, 0), (0, 1), (1, 1)],     # Square
    "I": [(0, 0), (1, 0), (2, 0), (3, 0)],     # Line
    "T": [(0, 1), (1, 1), (2, 1), (1, 0)],     # T-shape
    "Z": [(0, 1), (1, 1), (1, 0), (2, 0)],     # Z-shape
    "S": [(1, 1), (2, 1), (0, 0), (1, 0)],     # S-shape
    "L": [(0, 0), (0, 1), (0, 2), (1, 0)],     # L-shape
    "J": [(1, 0), (1, 1), (1, 2), (0, 0)],     # J-shape
}

Cell = Tuple[int, int]
Grid = Set[Cell]

@dataclass
class Move:
    """A single piece placement move."""
    piece_type: str
    column: int
    height_after: int
    rows_cleared: List[int]

@dataclass
class GameState:
    """Current state of the Tetris game."""
    sequence: str
    current_step: int
    grid: List[Dict[str, int]]  # For JSON serialization: [{"x": 0, "y": 1}, ...]
    moves_history: List[Move]
    current_height: int
    status: str  # "playing" or "completed"

class TetrisGame:
    """Simple Tetris game implementation."""
    
    def __init__(self, sequence: str):
        self.sequence = sequence
        self.moves = self._parse_sequence(sequence)
        self.grid: Grid = set()
        self.current_step = 0
        self.moves_history: List[Move] = []
    
    def _parse_sequence(self, sequence: str) -> List[Tuple[str, int]]:
        """Parse sequence like 'Q0,I4,T2' into [(Q,0), (I,4), (T,2)]."""
        if not sequence.strip():
            return []
        
        moves = []
        for move in sequence.split(','):
            move = move.strip()
            if len(move) >= 2:
                piece_type = move[0].upper()
                try:
                    column = int(move[1:])
                    if piece_type in SHAPES and 0 <= column < WIDTH:
                        moves.append((piece_type, column))
                except ValueError:
                    continue
        return moves
    
    def _get_piece_cells(self, piece_type: str, column: int, row: int) -> List[Cell]:
        """Get all cells occupied by a piece at given position."""
        shape = SHAPES[piece_type]
        return [(column + dx, row + dy) for dx, dy in shape]
    
    def _find_drop_row(self, piece_type: str, column: int) -> int:
        """Find the row where piece would land when dropped from the top."""
        shape = SHAPES[piece_type]

        # Check if piece would fit within horizontal bounds at any row
        piece_cells_at_row_0 = self._get_piece_cells(piece_type, column, 0)
        if any(x < 0 or x >= WIDTH for x, y in piece_cells_at_row_0):
            raise ValueError(f"Piece {piece_type} at column {column} would extend beyond grid boundaries")

        # Find where the piece would land by dropping from the top
        # Start from a high row and work downward until we find where it would stop
        for row in range(99, -1, -1):  # Start from top and work down
            piece_cells = self._get_piece_cells(piece_type, column, row)

            # Check if piece fits within bounds
            if any(x < 0 or x >= WIDTH or y < 0 for x, y in piece_cells):
                continue

            # Check if piece collides with existing blocks
            if any((x, y) in self.grid for x, y in piece_cells):
                continue

            # Check if piece would be supported (can't fall further)
            # Try one row lower to see if it would collide or go out of bounds
            lower_row = row - 1
            if lower_row < 0:
                # Hit the bottom, piece lands here
                return row

            lower_piece_cells = self._get_piece_cells(piece_type, column, lower_row)
            if (any(y < 0 for x, y in lower_piece_cells) or
                any((x, y) in self.grid for x, y in lower_piece_cells)):
                # Would collide or go out of bounds one row lower, so piece lands here
                return row

        raise ValueError(f"Cannot place piece {piece_type} at column {column}")
    
    def _clear_full_rows(self) -> List[int]:
        """Remove full rows and return list of cleared row numbers."""
        if not self.grid:
            return []
        
        # Find all rows that have blocks
        rows_with_blocks = {}
        for x, y in self.grid:
            if y not in rows_with_blocks:
                rows_with_blocks[y] = 0
            rows_with_blocks[y] += 1
        
        # Find full rows (10 blocks)
        full_rows = [row for row, count in rows_with_blocks.items() if count == WIDTH]
        
        if not full_rows:
            return []
        
        # Remove blocks from full rows
        self.grid = {(x, y) for x, y in self.grid if y not in full_rows}
        
        # Drop remaining blocks down
        full_rows.sort()
        new_grid = set()
        for x, y in self.grid:
            drop_distance = sum(1 for full_row in full_rows if full_row < y)
            new_grid.add((x, y - drop_distance))
        self.grid = new_grid
        
        return sorted(full_rows)
    
    def _get_current_height(self) -> int:
        """Get current height of the grid."""
        if not self.grid:
            return 0
        return max(y for x, y in self.grid) + 1
    
    def next_move(self) -> GameState:
        """Execute the next move and return current game state."""
        if self.current_step >= len(self.moves):
            return self.get_state()
        
        piece_type, column = self.moves[self.current_step]
        
        # Find where piece lands
        row = self._find_drop_row(piece_type, column)
        
        # Place the piece
        piece_cells = self._get_piece_cells(piece_type, column, row)
        for cell in piece_cells:
            self.grid.add(cell)
        
        # Clear full rows
        rows_cleared = self._clear_full_rows()
        
        # Record the move
        move = Move(
            piece_type=piece_type,
            column=column,
            height_after=self._get_current_height(),
            rows_cleared=rows_cleared
        )
        self.moves_history.append(move)
        self.current_step += 1
        
        return self.get_state()
    
    def get_state(self) -> GameState:
        """Get current game state for API response."""
        return GameState(
            sequence=self.sequence,
            current_step=self.current_step,
            grid=[{"x": x, "y": y} for x, y in sorted(self.grid)],
            moves_history=self.moves_history,
            current_height=self._get_current_height(),
            status="completed" if self.current_step >= len(self.moves) else "playing"
        )

def calculate_final_height(sequence: str) -> int:
    """Calculate final height for a complete sequence (utility function)."""
    game = TetrisGame(sequence)
    while game.current_step < len(game.moves):
        game.next_move()
    return game.get_state().current_height

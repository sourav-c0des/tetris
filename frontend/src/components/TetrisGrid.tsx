import React from 'react';
import { Cell } from '../types/tetris';

interface TetrisGridProps {
  grid: Cell[];
  width?: number;
  height?: number;
  className?: string;
}



export const TetrisGrid: React.FC<TetrisGridProps> = ({
  grid,
  width = 10,
  height = 14,
  className = '',
}) => {
  // Create a 2D array to represent the grid
  const gridArray = Array(height).fill(null).map(() => Array(width).fill(null));
  
  // Fill the grid with occupied cells
  grid.forEach((cell) => {
    if (cell.y >= 0 && cell.y < height && cell.x >= 0 && cell.x < width) {
      gridArray[height - 1 - cell.y][cell.x] = 'filled'; // Flip Y coordinate for display
    }
  });

  return (
    <div className={`tetris-grid ${className}`}>
      {gridArray.map((row, rowIndex) => (
        <div key={rowIndex} className="tetris-row">
          {row.map((cell, colIndex) => (
            <div
              key={`${rowIndex}-${colIndex}`}
              className={`tetris-cell ${
                cell ? 'bg-white' : 'bg-gray-900'
              }`}
            />
          ))}
        </div>
      ))}
    </div>
  );
};

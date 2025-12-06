import React, { useState } from 'react';
import { SequenceInfo } from '../types/tetris';

interface SequenceSelectorProps {
  sequences: SequenceInfo[];
  onSelectSequence: (sequence: string) => void;
  isLoading: boolean;
}

export const SequenceSelector: React.FC<SequenceSelectorProps> = ({
  sequences,
  onSelectSequence,
  isLoading,
}) => {
  const [selectedSequence, setSelectedSequence] = useState('');
  const [customSequence, setCustomSequence] = useState('');
  const [useCustom, setUseCustom] = useState(false);

  const handleStart = () => {
    const sequence = useCustom ? customSequence : selectedSequence;
    if (sequence.trim()) {
      onSelectSequence(sequence.trim());
    }
  };

  const canStart = useCustom ? customSequence.trim() : selectedSequence;

  return (
    <div className="bg-gray-800 p-6 rounded-lg">
      <h2 className="font-bold mb-4" style={{ fontSize: '1.25rem' }}>Select Tetris Sequence</h2>
      
      <div className="space-y-4">
        {/* Predefined sequences */}
        <div>
          <label className="flex items-center space-x-2 mb-3">
            <input
              type="radio"
              checked={!useCustom}
              onChange={() => setUseCustom(false)}
              className="text-blue-600"
            />
            <span className="font-medium">Choose from predefined sequences:</span>
          </label>
          
          <select
            value={selectedSequence}
            onChange={(e) => setSelectedSequence(e.target.value)}
            disabled={useCustom}
            style={{ opacity: useCustom ? 0.5 : 1 }}
          >
            <option value="">Select a sequence...</option>
            {sequences.map((seq, index) => (
              <option key={index} value={seq.sequence}>
                {seq.sequence}
              </option>
            ))}
          </select>
        </div>

        {/* Custom sequence */}
        <div>
          <label className="flex items-center space-x-2 mb-3">
            <input
              type="radio"
              checked={useCustom}
              onChange={() => setUseCustom(true)}
              className="text-blue-600"
            />
            <span className="font-medium">Enter custom sequence:</span>
          </label>
          
          <div>
            <input
              type="text"
              value={customSequence}
              onChange={(e) => setCustomSequence(e.target.value)}
              onFocus={() => setUseCustom(true)}
              placeholder="e.g., Q0,I4,T2,L1"
              style={{ opacity: !useCustom ? 0.5 : 1 }}
            />
            <p className="text-sm text-gray-400" style={{ marginTop: '4px', fontSize: '12px' }}>
              Format: PieceColumn (e.g., Q0 = Square at column 0, I4 = Line at column 4)
            </p>
          </div>
        </div>

        <button
          onClick={handleStart}
          disabled={!canStart || isLoading}
          style={{
            width: '100%',
            padding: '12px',
            backgroundColor: canStart && !isLoading ? '#16a34a' : '#666',
            color: canStart && !isLoading ? 'white' : '#999',
            borderRadius: '4px',
            border: 'none',
            cursor: canStart && !isLoading ? 'pointer' : 'not-allowed'
          }}
        >
          {isLoading ? 'Starting Game...' : 'Start Game'}
        </button>
      </div>

      {/* Game info */}
      <div style={{ marginTop: '24px', padding: '16px', backgroundColor: '#111827', borderRadius: '8px' }}>
        <p className="text-sm text-gray-400" style={{ marginBottom: '12px' }}>
          Use standard Tetris pieces: Q (Square), I (Line), T, Z, S, L, J shapes
        </p>
        <div style={{ textAlign: 'center' }}>
          <img
            src="/image.png"
            alt="Tetris Pieces"
            style={{
              maxWidth: '100%',
              height: 'auto',
              borderRadius: '4px'
            }}
          />
        </div>
      </div>
    </div>
  );
};

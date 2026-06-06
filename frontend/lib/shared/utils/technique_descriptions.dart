const _descriptions = <String, String>{
  'notes': 'Learn to track candidate digits using pencil marks.',
  'nakedSingles': 'A cell with only one possible digit — place it immediately.',
  'hiddenSingles':
      'A digit that can only go in one cell in a row, column, or box.',
  'lockedCandidates':
      'Candidates locked to one row or column inside a box eliminate peers.',
  'nakedPairs':
      'Two cells sharing the same two candidates lock those digits to those cells.',
  'hiddenPairs': 'Two digits confined to the same two cells in a unit.',
  'nakedTriples': 'Three cells sharing a combined set of three candidates.',
  'hiddenTriples': 'Three digits confined to the same three cells in a unit.',
  'nakedQuadruples': 'Four cells sharing a combined set of four candidates.',
  'hiddenQuadruples': 'Four digits confined to the same four cells in a unit.',
  'xWing':
      'A digit in exactly two rows/columns forms a rectangle that eliminates peers.',
  'swordfish': 'Like X-Wing but spanning three rows and columns.',
  'xyWing':
      'A pivot cell with two candidates links two pincers to eliminate a shared digit.',
  'xyzWing':
      'Like XY-Wing but the pivot shares all three digits with both pincers.',
  'forcedChains':
      'Try both values of a cell and follow the logical consequences.',
};

String techniqueDescription(String id) =>
    _descriptions[id] ?? 'Advanced technique.';

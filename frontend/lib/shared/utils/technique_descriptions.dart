// Short one-liners used in the tutorial list subtitle.
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

// Longer in-lesson intros that reference previously learned techniques.
const _lessonIntros = <String, String>{
  'nakedSingles':
      'Look at the notes you just filled in.\n\n'
      'When only one candidate remains in a cell, that digit has nowhere '
      'else to go — place it immediately.\n\n'
      'Scan the board for a cell with a single pencil mark.',
  'hiddenSingles':
      'Look at the notes you filled in for each unit (row, column, box).\n\n'
      'A hidden single is a digit that appears as a candidate in only one '
      'cell of a unit. Even if that cell has other candidates, this digit '
      'must go there — it has no other home.\n\n'
      'Scan each row, column, and box: if a digit appears in only one '
      "cell's notes, place it.",
};

String techniqueLessonIntro(String id) =>
    _lessonIntros[id] ?? techniqueDescription(id);

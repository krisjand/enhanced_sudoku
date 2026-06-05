// Pre-computed peer-cell map for a standard 9×9 Sudoku grid.
//
// peerCells[row][col] is the list of all 20 cells that share the same row,
// column, or 3×3 box as (row, col), excluding (row, col) itself.
//
// Use this instead of computing peers inline — O(20) iteration vs O(81) scan.

typedef Cell = ({int row, int col});

final List<List<List<Cell>>> peerCells = List.generate(9, (row) {
  return List.generate(9, (col) {
    final peers = <Cell>{};
    for (var c = 0; c < 9; c++) {
      if (c != col) peers.add((row: row, col: c));
    }
    for (var r = 0; r < 9; r++) {
      if (r != row) peers.add((row: r, col: col));
    }
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (var r = br; r < br + 3; r++) {
      for (var c = bc; c < bc + 3; c++) {
        if (r != row || c != col) peers.add((row: r, col: c));
      }
    }
    return List.unmodifiable(peers);
  });
});

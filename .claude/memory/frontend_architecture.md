---
name: frontend-architecture
description: Agreed Flutter frontend architectural decisions and design direction
metadata: 
  node_type: memory
  type: project
  originSessionId: e85d7da1-4335-409b-b17e-9dee62afb032
---

## Stack decisions (locked)

| Concern | Choice | Notes |
|---|---|---|
| State management | Riverpod | Composable, testable, no boilerplate |
| Navigation | go_router | Flutter-team recommendation, user preference |
| Local persistence | TBD (no strong preference) | drift or sqflite; decide at Foundation story |
| HTTP client | http or dio | Decide at Foundation story |

## Design direction

Game-like aesthetics but not too wild. Material 3 base. Review look and feel on the game board story before adding further screens.

**Why:** User wants to review design/aesthetics after the game board is done before committing to a visual style across all screens.

**How to apply:** Implement the game board with reasonable Material 3 + game-like styling. Pause for design review before building subsequent screens. Keep theming centralised (ThemeData) so colours are easy to update.

## Game board input validation

**Conflict-only** — a digit entry is blocked only when the same digit already exists in the same row, column, or box. Moves that are logically wrong but do not immediately collide are allowed. The player can make mistakes, exactly as with pen and paper. The app does not check against the solution.

**Why:** Mirrors real Sudoku UX. Solution-aware blocking would feel artificial and remove the challenge of careful reasoning.

## Code structure

Feature-based layout. The critical shared widget is `SudokuGrid`, used by Game Board, Tutorial, and Forced Chains Helper.

```
lib/
  app.dart / router.dart
  features/
    game/         screens/, widgets/, providers/
    tutorial/     screens/, providers/
    scores/
    settings/
    forced_chains/ screens/, providers/
  shared/
    widgets/
      sudoku_grid.dart        ← thin, renders board state + fires callbacks only
      sudoku_cell.dart
      digit_pad.dart
      technique_overlay.dart  ← stacked on top of grid for hints/give-up viz
    models/         puzzle.dart, cell_state.dart, solve_step.dart, source_cell.dart
    services/       api_client.dart, persistence_service.dart
    providers/      api_client_provider.dart, settings_provider.dart
    theme/          app_theme.dart, game_colors.dart
```

**SudokuGrid design principle:** Thin widget — only renders board state and fires callbacks. Extra behaviour (hint highlights, forced chain overlays, tutorial step-through) is added by stacking overlay widgets on top via `Stack`. The grid itself never knows about techniques or chains.

**How to apply:** When a feature needs to augment the board (hints, forced chains, tutorial), wrap `SudokuGrid` in a `Stack` and add the overlay as a sibling widget. Never add feature-specific parameters to `SudokuGrid` itself.

## Forced chains helper

Opened as a **modal overlay on top of the game board** — the game board stays mounted underneath, its state is fully preserved. Dismissing the overlay returns to the exact game state without any navigation or state restoration. Do NOT implement as a separate route.

## Game board features (complete list)

- Conflict-only digit validation (see above)
- Notes mode toggle
- Auto-fill notes: computes valid candidates (digits not in same row/col/box) for all empty cells, fills as notes in one undoable action — pure client-side, no API call
- Undo/redo history (persisted; history not required on resume)
- Highlight mode toggle: tap a placed digit to highlight all matching digits and notes
- Peer highlighting: cells sharing a row/col/box with the selected cell get a light background
- Hint: POST /puzzle/hint → highlights source cells (technique pattern) + action cells
- Give-up: POST /puzzle/solve → animates solution, marks game failed, not eligible for high scores
- Technique visualisation: shared overlay component showing source/action cells + technique label

## Backend URL

- Default: `http://localhost:8080`
- Configurable in the Settings screen at runtime
- Persisted to local storage so it survives app restarts
- Used by the API client as a base URL read from a provider

**Why:** Developer needs to run the backend locally while testing the app on an emulator or web.

## Test targets

Android emulator and web are both available for running/testing the app.

## Story creation

For frontend epics (#65–#71), AI creates the GitHub story issues autonomously — no user input needed to define them. Once stories exist, proceed through the full implementation loop (including mandatory task breakdown before writing any code) without asking permission at each phase. Only pause at: owner PR approval and story close.

## Workflow (frontend-specific)

- Owner approves and merges each PR — AI does not merge frontend PRs
- Acceptance testing: code-level until game board is playable; then manual by owner
- Time tracking: all phases in one growing table on the story's GitHub issue

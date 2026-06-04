---
name: feedback-technique-identifiers
description: Technique string constants use camelCase identifiers, not display names
metadata:
  node_type: memory
  type: feedback
  originSessionId: current
---

All technique string constant values use camelCase identifiers (`nakedSingles`, `hiddenPairRow`, etc.), not human-readable display names (`"Naked Singles"`, `"Hidden Pair (Row)"`).

**Why:** Display names are a presentation concern that belongs in the frontend. Stable camelCase identifiers make the HTTP API clean to use (`?technique=nakedSingles` vs `?technique=Naked+Singles`) and consistent with Go/HTTP conventions. Decided 2026-06-02.

**How to apply:**
- New technique top-level constant: `TechniqueHiddenTriples = "hiddenTriples"`
- New technique sub-level constants: `TechniqueHiddenTripleRow = "hiddenTripleRow"`, etc.
- Never use spaces or parentheses in the string values
- The Go constant names (`TechniqueHiddenTriples`) are unchanged — only the string values are camelCase
- Forced chains top-level: `TechniqueForcedChains = "forcedChains"` (no sub-level step constants — the chain reasoning lives in `SolveStep.Chains []ForcedChainBranch`)

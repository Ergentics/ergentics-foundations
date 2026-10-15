# Game evidence assessment

Decision: **`PracticeSurface.moment` is the public piece. The games stay in their own repositories.** Ur and backgammon keep their boards, dice, search, and thresholds. A stage commit is recorded as surface byte 4 after the game has already reduced its grade to a unit score.

## What the two games already share

Both titles are dice-race tutors on MasteryKit. The shared thesis is outside this repository: one evaluator plays the opponent and grades the player. At the tutor boundary the code does the same three things.

1. A legal stage commit is graded by regret: best value minus chosen value, floored at zero. Ur does this in `UrKit.PuzzleGrader`. Backgammon does it in `BackgammonKit.PuzzleGrader`. The rating is `optimal`, `good`, or `inaccurate`.
2. That rating is collapsed to a unit score before `TutorSession.submit`. A clean play is `0.85`. A mistake is `0.2`. Ur's puzzle path also gives `1.0` for optimal, because the `0.85` cap was found to stall positional skills. Match folding in both games stays binary: clean or mistake.
3. The submitted item is labeled `surface: "quiz"` with the stem "In-game decision", even when the player moved on the board. `UrLearningBridge.evidenceItem` and `BackgammonTutor.LearningBridge.evidenceItem` are the same shape. Ur's file says it mirrors the backgammon bridge.

`PracticeSurface.moment` is that board-commit case. A game that still labels the item `quiz` is using the old seam. The ledger accepts either byte. It does not infer which game produced the score.

## What must stay in the games

| Piece | Why it is not the next SDK type |
|---|---|
| Boards, dice, move generators, expectiminimax | Different rules. Ur's chance fan-out is not backgammon's 21 rolls. Both engines are proprietary and clean-room. |
| Regret epsilons | Ur treats regret `≤ 0.75` as optimal and `≤ 5` as good. Backgammon uses `1.5` and `6` in heuristic equity units. Backgammon's own notes say those units are not the rung-3 net's units. |
| The `0.85` / `0.2` table | Both bridges use it, and Ur already had to break it for puzzles. It is a shared calibration, not a law. Freezing it here would make the stall they already measured into a public contract. |
| Quiet-concept skips | Ur skips `board-path`. Backgammon skips its quiet positional concept and skills that are not ready. That is content policy. |
| Learn UI, moments, arc maps | `GAME-SPINE.md` is house pedagogy for the player-facing game. The public ledger does not own a stage. |

Raw regret is also the wrong thing to seal. Backgammon's cross-grader checks show two evaluators can agree that a move was a mistake and still disagree on the size of the regret. `OracleAdmission` compares canonical score bits. Those bits are only meaningful after the game has binned the grade. The bin stays in the game.

## What landed

`PracticeSurface.moment` (byte 4) records that the score came from a stage commit. The game maps its own rating to a `UnitScore` and submits that event. `OracleAdmission` can seal that unit score. It still cannot seal a regret in equity units. Existing `problems`, `quiz`, and `recall` bytes are unchanged.

## What not to build next

Do not import `UrKit` or `BackgammonKit`. Do not add dice, a doubling cube, or a shared search. Do not copy `GAME-SPINE.md` into this repository as a UI spec. Do not promote either game's epsilon or the `0.85` / `0.2` pair into `PracticeLedger`.

Algebra and the other non-game subjects already fit `problems`, `quiz`, and `recall`. They are not the gap this assessment found.

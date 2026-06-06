# Contract: Scene Flow & UI States

**Version**: 1.0.0 | **Feature**: `001-card-counter-tutorial`

## Scene graph

```text
BootScene → HomeScene ─┬→ TutorialScene → TableScene (preset config)
                       └→ SetupScene → TableScene (user config)

TableScene ↔ AnalyticsOverlay (toggle)
All scenes → HomeScene (exit)
```

## HomeScene

| Element | Behavior |
|---------|----------|
| Tutorial button | Navigate `TutorialScene`; no prerequisite |
| Free Play button | Navigate `SetupScene`; no prerequisite |
| Mute toggle | Updates `LearnerProfile.soundEnabled` |

## SetupScene (Free Play only)

| Control | Range |
|---------|-------|
| Deck count slider | 1–6 |
| Other players slider | 0–5 |
| Hands before reshuffle | 20–200 |
| Bet model picker | 3 models with pros/cons/EV panel |

Confirm → creates `SessionState` → `TableScene`.

## TableScene

| State | UI | Keyboard |
|-------|-----|----------|
| `betting` | Chip selector, recommended range | Enter confirm bet |
| `insurance` | Accept / Decline | `I` / `N` |
| `player-turn` | Hit, Stand, Double, Split | `H` `S` `D` `P` |
| `dealer-turn` | Animated reveal | — |
| `settled` | Coaching toast, next hand | Space continue |

Always visible: running count, true count, balance, stay-or-leave indicator.

## Mid-hand recovery dialog

Triggered when `hand-snapshot` exists on boot:

| Choice | Effect |
|--------|--------|
| Resume | Load snapshot into `GameController` |
| Forfeit | `clearHandSnapshot()`; restore pre-hand state |

## AnalyticsOverlay

| Chart | X-axis | Y-axis |
|-------|--------|--------|
| Balance | Hand index | Dollars |
| Advantage | Hand index | Estimated % |

Annotations for reshuffle, model change, player join/leave.

## Accessibility

- `prefers-reduced-motion`: tween duration 0; instant card placement
- All primary actions reachable via keyboard (see TableScene)
- Coaching text readable without color-only cues

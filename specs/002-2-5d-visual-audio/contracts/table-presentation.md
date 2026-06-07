# Contract: Table Presentation (3D + Actions)

**Version**: 1.0.0 | **Feature**: `002-2-5d-visual-audio`

## Scene graph

```text
table.tscn (Control)
├── MainSplit (HBox/VBox)
│   ├── SidebarContainer → sidebar.tscn (2D shell)
│   └── TableArea
│       ├── Viewport3D → table_3d.tscn (SubViewport)
│       └── ActionPanel → action_panel.tscn (2D shell, contextual)
└── AnalyticsDrawer (overlay, 2D shell)
```

## 3D table (`table_3d.gd`)

### Required nodes

| Node | Purpose |
|------|---------|
| `TableMesh` | Round felt table |
| `ShoeMesh` | 3D shoe stack + remaining count label (2D billboard or UI sub-viewport) |
| `CardRoot` | Parent for card meshes |
| `SeatRoot` | Dog seat anchors |
| `Camera3D` | Fixed tilt, legible card faces |

### Public API

```gdscript
func set_dog_count(count: int) -> void          # 0–5 other players
func sync_presentation(view: Dictionary) -> void # SeatView[] from card_layout
func set_shoe_remaining(count: int) -> void
func focus_seat(seat_id: String, focused: bool) -> void  # hover/focus zoom
```

### Card rules

- Face-up: rank+suit texture visible
- Face-down: card back texture
- Multi-card hands: fan in 3D with `card_layout.gd` angles
- Learner seat: largest scale multiplier
- Minimum scale: 0.65× baseline (configurable constant)

### Animations

| Event | Animation | Reduced motion |
|-------|-----------|----------------|
| Deal | Tween position from shoe | Instant placement |
| Hit | Tween to fan slot | Instant |
| Flip | Rotate Y 180° | Instant face swap |
| Collect | Tween off-table | Instant remove |
| Win/loss | Dog reaction + chip bounce | Static outcome icon |

Duration base: 260 ms; `MotionPreference.duration_ms(base, reduced)`.

## Action panel (`action_menu.gd` + `action_panel.tscn`)

### Visibility rules

| Phase | Visible actions |
|-------|-----------------|
| `betting` | `place-bet`, `deal` |
| `insurance` | `insurance-accept`, `insurance-decline` only |
| `player-turn` | Legal subset of `hit`, `stand`, `double`, `split` |
| `dealer-turn` | *(none)* |
| `settled` | `continue` |
| Always | `home` |

Illegal actions MUST NOT appear in the panel (hidden, not disabled).

### Keyboard map (when visible)

| Key | Action |
|-----|--------|
| `H` | hit |
| `S` | stand |
| `D` | double |
| `P` | split |
| `I` | insurance-accept |
| `N` | insurance-decline |
| `Enter` | place-bet / deal / continue |
| `Escape` | home |

Only bind keys present in `visibleActions`.

### Tutorial highlight

When `TutorialCoachingCue.highlightActionId` is set:

- Apply `lamp-glow` style to matching button
- No highlight in Free Play
- Non-pulsing when `motionReduced`

## Session sync flow

```text
GameController.events → table_scene._update_from_session()
  → card_layout.build(session) → TablePresentation dict
  → table_3d.sync_presentation(view)
  → action_menu.visible_actions(session) → action_panel.render()
  → coaching_cue.highlight(session, mode) → action_panel.set_highlight()
```

## Test hooks

| Method | Owner | Assertion |
|--------|-------|-----------|
| `get_visible_action_ids()` | `action_panel` | Matches legal set for fixture session |
| `get_card_count()` | `table_3d` | Cards on felt |
| `get_focused_seat()` | `table_3d` | Hover/focus zoom target |
| `get_layout_mode()` | `table_scene` | `wide` or `stacked` |

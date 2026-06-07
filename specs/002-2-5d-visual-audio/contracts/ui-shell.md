# Contract: Shared 2D UI Shell (Mix 2)

**Version**: 1.0.0 | **Feature**: `002-2-5d-visual-audio`

## Scope

Applies to: **Home**, **Setup**, **Tutorial**, **table sidebar**, **contextual action panel**,
**analytics overlay**, **options/audio controls**.

Does **not** apply to: 3D SubViewport table content (`table_3d.tscn`).

## Theme resource

| Property | Value |
|----------|-------|
| Path | `res://assets/themes/mix2_shell.tres` |
| Loader | `scripts/lib/ui_theme.gd` → `apply_to(control, screen_class)` |

## Screen classes

| Class | Scenes / nodes |
|-------|----------------|
| `MENU` | `home.tscn`, `setup.tscn`, `tutorial.tscn` |
| `SIDEBAR` | `scenes/table/sidebar.tscn` |
| `ACTION` | `scenes/table/action_panel.tscn` |
| `OVERLAY` | Analytics drawer, options modal |

## Required visual elements

### Panel

- Dark background (`StyleBoxFlat`, radius ≥ 8 px)
- Section separation via margin or nested panels

### Stat blocks

| Block | Content | Style |
|-------|---------|-------|
| Running count | Integer, signed | Saturated accent background |
| True count | Integer, signed | Saturated accent background |
| Bankroll | `$NNN` | Accent block |
| Recommended bet | `$NNN` | Accent block |
| Shoe progress | `%` or cards remaining | Grid tile |

### Buttons

- Rounded rectangle (`StyleBoxFlat` corner radius ≥ 12 px)
- Primary: filled accent; secondary: outline on dark panel
- Hover: subtle scale or color shift (respect reduced motion)

### Typography

- Headings: bold, high contrast on dark panel
- Stats: chunky numerals, minimum 18 px at 1280×720

## Responsive (sidebar / table)

| Viewport | Layout |
|----------|--------|
| width ≥ 900 px | Sidebar left, 3D table right |
| width < 900 px | Sidebar stacked above table |

**Stacked requirement**: Running count, true count, bankroll, shoe remaining MUST be visible without
scroll before play actions (FR-001g).

## Test hooks

| Method | Scene | Purpose |
|--------|-------|---------|
| `get_theme_path()` | `ui_theme.gd` | Returns `mix2_shell.tres` |
| `get_screen_class()` | Each scene root script | Returns `MENU` / `SIDEBAR` / etc. |
| `uses_shared_theme()` | Scene integration tests | Theme resource identity match |

## Accessibility

- Keyboard focus visible on all buttons
- Stat values not conveyed by color alone (numeric labels required)
- Touch targets ≥ 44 pt on iOS export

# Contract: Audio Profile & Action Sound Map

**Version**: 1.0.0 | **Feature**: `002-2-5d-visual-audio`

## AudioManager API

Path: `res://scripts/game/audio_manager.gd` (autoload or owned by `GameController`)

### Configuration

```gdscript
func set_master_enabled(enabled: bool) -> void
func set_music_enabled(enabled: bool) -> void
func set_sfx_enabled(enabled: bool) -> void
func set_music_volume(level: float) -> void   # 0.0–1.0
func set_sfx_volume(level: float) -> void     # 0.0–1.0
func unlock_autoplay() -> void                # Web first gesture
```

### Playback

```gdscript
func map_action_to_sound(action: String, settle_outcome: String = "") -> String
func play_action(action: String, settle_outcome: String = "") -> void
func play_ui(action: String = "ui-confirm") -> void
func start_table_bgm() -> void
func stop_table_bgm() -> void
```

### Test hooks (existing + extended)

```gdscript
func get_played_actions() -> Array[String]
func clear_played_actions() -> void
func get_bgm_state() -> String   # stopped | playing | paused
```

## Action → sound category map

| Action / event | Category id | Notes |
|----------------|-------------|-------|
| `place-bet` | `bet` | Distinct from deal |
| `deal` | `deal` | |
| `insurance-accept` | `insurance-accept` | |
| `insurance-decline` | `insurance-decline` | |
| `hit` | `hit` | |
| `stand` | `stand` | |
| `double` | `double` | |
| `split` | `split` | |
| `settle` + win | `win` | |
| `settle` + loss | `loss` | |
| `settle` + push | `push` | |
| `settle` + blackjack | `blackjack` | |
| `shoe:reshuffled` | `shuffle` | Event from controller |
| chip animation | `chip` | Bet placement |
| button confirm | `ui-confirm` | Menus + sidebar |

## Asset paths

Convention under `res://assets/audio/`:

```text
bgm/table_loop.ogg
sfx/bet_confirm.ogg
sfx/deal.ogg
sfx/hit.ogg
sfx/stand.ogg
sfx/double.ogg
sfx/split.ogg
sfx/insurance_yes.ogg
sfx/insurance_no.ogg
sfx/win.ogg
sfx/lose.ogg
sfx/push.ogg
sfx/blackjack.ogg
sfx/shuffle.ogg
sfx/chip.ogg
sfx/ui_confirm.ogg
```

Missing assets: log warning, continue silently (FR-017).

## Lifecycle

| Event | BGM | SFX |
|-------|-----|-----|
| Enter `table` scene | `start_table_bgm()` if music enabled | — |
| Leave `table` scene | `stop_table_bgm()` | — |
| Player action confirmed | — | `play_action(action)` |
| Hand settled | — | `play_action("settle", outcome)` |
| UI button pressed | — | `play_ui()` |
| Master mute | Stop BGM | Suppress all SFX |
| Music mute only | Stop BGM | SFX unchanged |
| SFX mute only | BGM unchanged | Suppress SFX |

## Mix balance

- Default `musicVolume`: 0.5
- Default `sfxVolume`: 0.8 (SFX more prominent per spec)
- No harsh transients; Ogg normalized to similar perceived loudness

## Persistence (profile extension)

```json
{
  "soundEnabled": true,
  "musicEnabled": true,
  "sfxEnabled": true,
  "musicVolume": 0.5,
  "sfxVolume": 0.8
}
```

Backward compatible: absent keys use defaults in `LearnerProfile.load_profile()`.

## Platform notes

- **Web**: defer `start_table_bgm()` until `unlock_autoplay()` after first input
- **Background tab**: pause BGM per Godot/Web export norms
- **iOS**: respect silent switch via Godot audio bus settings (document in export preset)

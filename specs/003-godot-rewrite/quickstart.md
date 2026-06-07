# Quickstart: Godot Card Counter

**Prerequisites:** Godot 4.4+ on PATH, Git

## First-time setup

```bash
# Clone GUT if not present (Task 3)
cd godot/addons
git clone --depth 1 --branch v9.4.0 https://github.com/bitwes/Gut.git gut
cd ../..
```

Open `godot/` in Godot Editor or run headless tests:

```bash
godot --headless --path godot -s tests/run_smoke.gd
```

## Development

```bash
godot --path godot          # open editor
godot --path godot -- --path godot  # play (F5 equivalent)
```

### Run tests

```bash
# All unit tests
godot --headless --path godot -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit

# Integration only
godot --headless --path godot -s addons/gut/gut_cmdln.gd -gdir=res://tests/integration -gexit

# Full suite
godot --headless --path godot -s tests/run_smoke.gd
```

## Build exports

Copy `godot/export_presets.example.cfg` to `godot/export_presets.cfg` before first export.
Godot does not commit local signing/template secrets, so keep `export_presets.cfg` local.

### Steam (Windows v1)

```bash
powershell -ExecutionPolicy Bypass -File scripts/build-steam.ps1
```

If the export fails with an export template error, install templates in the editor:
`Editor > Manage Export Templates...` and install the matching Godot version templates.

Manual equivalent:

```bash
godot --headless --path godot --export-release "Windows Desktop" dist/steam/CardCounter.exe
```

Steam packaging notes:
- Upload `dist/steam/CardCounter.exe` and the generated `.pck`/data files via SteamPipe.
- Positioning remains educational-only (no real-money gambling language).
- Windows export attempt status (Task 27): failed locally until matching Godot export templates are installed.
- Missing template paths observed:
  - `C:/Users/gener/AppData/Roaming/Godot/export_templates/4.6.3.stable/windows_debug_x86_64.exe`
  - `C:/Users/gener/AppData/Roaming/Godot/export_templates/4.6.3.stable/windows_release_x86_64.exe`

### Web

```bash
powershell -ExecutionPolicy Bypass -File scripts/build-web.ps1
npx serve dist/web
```

Web caveats:
- HTML5 downloads are larger than the Phaser/Vite build.
- Mid-hand recovery can be simplified on web due to browser tab lifecycle.
- Persistence uses browser-backed `user://` storage (IndexedDB).
- Web export attempt status (Task 28): failed locally until matching Godot export templates are installed.
- Missing template paths observed:
  - `C:/Users/gener/AppData/Roaming/Godot/export_templates/4.6.3.stable/web_nothreads_debug.zip`
  - `C:/Users/gener/AppData/Roaming/Godot/export_templates/4.6.3.stable/web_nothreads_release.zip`

### iOS (requires Mac + Xcode)

```bash
godot --headless --path godot --export-release "iOS" dist/ios/CardCounter.xcodeproj
```

iOS notes:
- A macOS machine with Xcode is required for signing, archiving, and App Store submission.

## Port reference

When implementing domain modules, port from:

- `src/domain/*.ts` → `godot/scripts/domain/*.gd`
- `tests/unit/*.test.ts` → `godot/tests/unit/test_*.gd`

Tests in the Phaser codebase are the acceptance specification.

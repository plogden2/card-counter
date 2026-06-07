# Card Counter

A blackjack card-counting tutorial game rewritten for **Godot 4** with a shared domain model
and scene-based UI. It targets Steam (Windows), Web (HTML5), and iOS as a free educational experience.

## Godot Quickstart

### Prerequisites

- Godot 4.6+ CLI available (or use the absolute executable path)
- Git

### First-time setup

```bash
# Clone GUT test addon if not present
cd godot/addons
git clone --depth 1 --branch v9.4.0 https://github.com/bitwes/Gut.git gut
cd ../..
```

Run the smoke suite:

```bash
godot --headless --path godot -s tests/run_smoke.gd
```

### Development

```bash
godot --path godot
```

### Build exports

Copy `godot/export_presets.example.cfg` to `godot/export_presets.cfg` before first export.

- Steam (Windows): `powershell -ExecutionPolicy Bypass -File scripts/build-steam.ps1`
- Web (HTML5): `powershell -ExecutionPolicy Bypass -File scripts/build-web.ps1`
- iOS: `godot --headless --path godot --export-release "iOS" dist/ios/CardCounter.xcodeproj` (requires macOS + Xcode)

If export fails due to missing templates, install matching templates in Godot via
`Editor > Manage Export Templates...`.

Full workflow details live in `specs/003-godot-rewrite/quickstart.md`.

## Governance

Feature work is governed by the [project constitution](.specify/memory/constitution.md).

## Spec Kit

Active feature specs live under `specs/`. See `.specify/feature.json` for the current
feature directory.

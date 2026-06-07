param(
    [string]$GodotExe = "C:\Users\gener\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.3-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$projectRoot = Join-Path $repoRoot "godot"
$exportConfig = Join-Path $projectRoot "export_presets.cfg"
$exampleConfig = Join-Path $projectRoot "export_presets.example.cfg"
$outputPath = Join-Path $repoRoot "dist/steam/CardCounter.exe"

if (-not (Test-Path $exampleConfig)) {
    throw "Missing example export config: $exampleConfig"
}

if (-not (Test-Path $exportConfig)) {
    Copy-Item $exampleConfig $exportConfig
    Write-Host "Created $exportConfig from example. Update signing/template settings if needed."
}

New-Item -ItemType Directory -Path (Split-Path $outputPath -Parent) -Force | Out-Null

Write-Host "Exporting Windows Desktop build to $outputPath"
& $GodotExe --headless --path $projectRoot --export-release "Windows Desktop" $outputPath
if ($LASTEXITCODE -ne 0) {
    throw "Godot export failed with exit code $LASTEXITCODE"
}

Write-Host "Steam Windows export complete."

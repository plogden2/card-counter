param(
    [string]$GodotExe = "C:\Users\gener\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.3-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$projectRoot = Join-Path $repoRoot "godot"
$exportConfig = Join-Path $projectRoot "export_presets.cfg"
$exampleConfig = Join-Path $projectRoot "export_presets.example.cfg"
$outputPath = Join-Path $repoRoot "dist/web/index.html"

if (-not (Test-Path $exampleConfig)) {
    throw "Missing example export config: $exampleConfig"
}

if (-not (Test-Path $exportConfig)) {
    Copy-Item $exampleConfig $exportConfig
    Write-Host "Created $exportConfig from example. Update templates if needed."
}

$configText = Get-Content -Path $exportConfig -Raw
if ($configText -notmatch '\[preset\.\d+\]\s*name="Web"') {
    Add-Content -Path $exportConfig -Value @'

[preset.1]
name="Web"
platform="Web"
runnable=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="dist/web/index.html"
script_export_mode=1
script_encryption_key=""

[preset.1.options]
custom_template/debug=""
custom_template/release=""
variant/extensions_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
threads/thread_support=false
'@
    Write-Host "Appended Web preset to local export_presets.cfg"
}

New-Item -ItemType Directory -Path (Split-Path $outputPath -Parent) -Force | Out-Null

Write-Host "Exporting Web build to $outputPath"
& $GodotExe --headless --path $projectRoot --export-release "Web" $outputPath
if ($LASTEXITCODE -ne 0) {
    throw "Godot export failed with exit code $LASTEXITCODE"
}

Write-Host "Web export complete."

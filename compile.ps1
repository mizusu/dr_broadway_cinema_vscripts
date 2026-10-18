# Compiles dr_skullgirls_cinema.vmf with TF2's own compilers (vbsp, vvis, vrad)
# and copies the .bsp into tf/maps, so `map dr_skullgirls_cinema` loads it.
#
#   .\compile.ps1          fast compile, for testing
#   .\compile.ps1 -Final   full-quality lighting, for release
#
# The compile runs on a copy in build/, so the repo .vmf is never touched.
# The map's VScripts are packed into the .bsp. Other custom content is not
# packed yet (use CompilePal for that).

param(
    [switch]$Final,
    [string]$TF2 = "D:\SteamLibrary\steamapps\common\Team Fortress 2"
)

$ErrorActionPreference = "Stop"
$map   = "dr_skullgirls_cinema"
# The 32-bit tools, as Hammer uses: bin\x64 has no MaterialSystem.dll, so vbsp fails there.
$bin   = Join-Path $TF2 "bin"
$game  = Join-Path $TF2 "tf"
$build = Join-Path $PSScriptRoot "build"

New-Item -ItemType Directory -Force $build | Out-Null
Copy-Item (Join-Path $PSScriptRoot "$map.vmf") $build -Force
$target = Join-Path $build $map

function Run($exe, [string[]]$exeArgs) {
    Write-Host "`n=== $exe $($exeArgs -join ' ') ===" -ForegroundColor Cyan
    & (Join-Path $bin $exe) @exeArgs
    if ($LASTEXITCODE -ne 0) { throw "$exe failed (exit code $LASTEXITCODE). See $target.log" }
}

$started = Get-Date
Run "vbsp.exe" @("-game", $game, $target)
if (-not (Test-Path "$target.prt")) {
    throw "No .prt file: the map has a leak, so vvis can't run. Load $target.lin in Hammer (Map > Load Pointfile) to find it."
}
# Flags match CompilePal's "Fast" and "Publish - Both" presets.
if ($Final) {
    Run "vvis.exe" @("-game", $game, $target)
    Run "vrad.exe" @("-final", "-StaticPropLighting", "-StaticPropPolys", "-both", "-game", $game, $target)
} else {
    Run "vvis.exe" @("-fast", "-nosort", "-game", $game, $target)
    Run "vrad.exe" @("-fast", "-bounce", "2", "-hdr", "-game", $game, $target)
}

# Pack the map's VScripts into the .bsp, so they work without installing them.
foreach ($script in @("elevators.nut")) {
    Run "bspzip.exe" @("-game", $game, "-addfile", "$target.bsp", "scripts/vscripts/$script", (Join-Path $PSScriptRoot $script), "$target.packed.bsp")
    Move-Item "$target.packed.bsp" "$target.bsp" -Force
}

Copy-Item "$target.bsp" (Join-Path $game "maps") -Force
$mins = [math]::Round(((Get-Date) - $started).TotalMinutes, 1)
Write-Host "`nDone in $mins min. Copied $map.bsp to tf\maps. In TF2: map $map" -ForegroundColor Green

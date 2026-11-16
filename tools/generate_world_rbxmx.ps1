# generate_world_rbxmx.ps1
# Master World Model Generator for Workspace.RelicRushWorld
# Invokes tools\generate_expanded_world.py to construct the full 15,000 x 15,000 stud dark-fantasy universe
# with 1,591 pre-baked elements across all 5 regions.

param(
    [string]$OutputPath = "assets\world\RelicRushWorld.rbxmx"
)

$pythonExe = ".\bin\blender\4.2\python\bin\python.exe"
$scriptPath = "tools\generate_expanded_world.py"

if (Test-Path $pythonExe) {
    & $pythonExe $scriptPath
} else {
    python $scriptPath
}

if (Test-Path $OutputPath) {
    $fileSize = (Get-Item $OutputPath).Length
    Write-Host "Verified $OutputPath successfully! Size: $fileSize bytes ($([math]::Round($fileSize / 1KB, 2)) KB)" -ForegroundColor Green
} else {
    Write-Error "Failed to generate $OutputPath"
}

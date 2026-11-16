# tools\install_blender_portable.ps1
# Downloads and sets up portable official Blender LTS 4.2 without requiring admin privileges

$ErrorActionPreference = "Stop"

$binDir = "C:\RelicRushAI\bin"
if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
}

$zipPath = "$binDir\blender.zip"
$targetExtract = "$binDir\blender"
$url = "https://download.blender.org/release/Blender4.2/blender-4.2.16-windows-x64.zip"

Write-Host "Downloading Blender LTS 4.2 portable (365 MB)..."
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $zipPath)
Write-Host "Download complete: $([math]::Round((Get-Item $zipPath).Length / 1MB, 2)) MB"

Write-Host "Extracting Blender..."
if (Test-Path $targetExtract) {
    Remove-Item $targetExtract -Recurse -Force
}
Expand-Archive -Path $zipPath -DestinationPath "$binDir\blender_tmp" -Force

$extractedFolder = Get-ChildItem -Path "$binDir\blender_tmp" -Directory | Select-Object -First 1
Move-Item -Path $extractedFolder.FullName -Destination $targetExtract -Force
Remove-Item "$binDir\blender_tmp" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

$blenderExe = "$targetExtract\blender.exe"
if (Test-Path $blenderExe) {
    Write-Host "Blender installed successfully at $blenderExe!"
    $ver = & $blenderExe --version
    Write-Host "$ver"
} else {
    throw "blender.exe not found after extraction"
}

# tools\capture_screen.ps1
# Captures full-screen screenshot to target file in assets\evidence\

param(
    [string]$Filename = "screen_baseline.png"
)

$outDir = "C:\RelicRushAI\assets\evidence"
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$outPath = Join-Path $outDir $Filename

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bitmap = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)

$bitmap.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bitmap.Dispose()

Write-Host "Screenshot captured successfully: $outPath ($((Get-Item $outPath).Length) bytes)"

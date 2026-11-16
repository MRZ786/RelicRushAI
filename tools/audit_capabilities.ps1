# tools\audit_capabilities.ps1
# Discovers all development capabilities, graphics engines, and runtime facilities

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  RELIC RUSH: CAPABILITY & TOOL AUDIT     " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$tools = @("rojo", "python", "blender", "winget", "git", "node", "pwsh")
foreach ($t in $tools) {
    $cmd = Get-Command $t -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "[FOUND] $t : $($cmd.Source) (v$($cmd.Version))" -ForegroundColor Green
    } else {
        Write-Host "[MISSING] $t is not in system PATH" -ForegroundColor Yellow
    }
}

# Check Rojo local binary
if (Test-Path ".\bin\rojo.exe") {
    $rojoVer = & ".\bin\rojo.exe" --version
    Write-Host "[LOCAL] .\bin\rojo.exe exists ($rojoVer)" -ForegroundColor Green
}

# Check Blender installation paths
$blenderSearch = @(
    "C:\Program Files\Blender Foundation",
    "C:\Program Files (x86)\Blender Foundation",
    "$env:LOCALAPPDATA\Programs\Blender Foundation"
)
$blenderExe = $null
foreach ($bp in $blenderSearch) {
    if (Test-Path $bp) {
        $exe = Get-ChildItem -Path $bp -Recurse -Filter "blender.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($exe) {
            $blenderExe = $exe.FullName
            Write-Host "[BLENDER FOUND] $($exe.FullName)" -ForegroundColor Green
            break
        }
    }
}
if (-not $blenderExe) {
    Write-Host "[BLENDER MISSING] No blender.exe found in standard Program Files or LocalAppData" -ForegroundColor Yellow
}

# Check Python installation paths
$pySearch = @(
    "C:\Python*",
    "C:\Program Files\Python*",
    "$env:LOCALAPPDATA\Programs\Python\*"
)
$pyExe = $null
foreach ($pp in $pySearch) {
    $found = Get-Item $pp -ErrorAction SilentlyContinue
    if ($found) {
        $exe = Get-ChildItem -Path $found.FullName -Filter "python.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($exe) {
            $pyExe = $exe.FullName
            Write-Host "[PYTHON FOUND] $($exe.FullName)" -ForegroundColor Green
            break
        }
    }
}
if (-not $pyExe) {
    Write-Host "[PYTHON SYSTEM] Checking if default 'python' command resolves..." -ForegroundColor Yellow
    $pyCheck = Get-Command "python" -ErrorAction SilentlyContinue
    if ($pyCheck) {
        Write-Host "[PYTHON] Resolves to $($pyCheck.Source)" -ForegroundColor Green
    } else {
        Write-Host "[PYTHON MISSING] Standard python not found" -ForegroundColor Yellow
    }
}

# Check Roblox Studio installation
$studioSearch = @(
    "$env:LOCALAPPDATA\Roblox\RobloxStudioBeta.exe",
    "$env:LOCALAPPDATA\Roblox\RobloxStudio.exe",
    "C:\Program Files\Roblox\*",
    "C:\Program Files (x86)\Roblox\*"
)
foreach ($sp in $studioSearch) {
    $found = Get-Item $sp -ErrorAction SilentlyContinue
    if ($found) {
        Write-Host "[ROBLOX STUDIO FOUND] $($found.FullName)" -ForegroundColor Green
    }
}

Write-Host "==========================================" -ForegroundColor Cyan

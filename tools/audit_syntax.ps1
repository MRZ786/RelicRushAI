$files = Get-ChildItem -Path "C:\RelicRushAI\src" -Recurse -Filter "*.luau"
Write-Host "Auditing $($files.Count) Luau files..."
$errors = 0
foreach ($f in $files) {
    $content = [System.IO.File]::ReadAllText($f.FullName)
    $c1 = [regex]::Matches($content, '\{').Count
    $c2 = [regex]::Matches($content, '\}').Count
    $p1 = [regex]::Matches($content, '\(').Count
    $p2 = [regex]::Matches($content, '\)').Count
    $b1 = [regex]::Matches($content, '\[').Count
    $b2 = [regex]::Matches($content, '\]').Count
    if ($c1 -ne $c2 -or $p1 -ne $p2 -or $b1 -ne $b2) {
        Write-Host "MISMATCH in $($f.Name): braces: $c1/$c2, parens: $p1/$p2, brackets: $b1/$b2" -ForegroundColor Red
        $errors++
    }
}
Write-Host "Audit Complete: $errors mismatches found across $($files.Count) files."

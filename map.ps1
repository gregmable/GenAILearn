foreach ($p in 1..4) {
    Write-Output "==== PHASE $p ===="
    $files = Get-ChildItem "phase$p-*.html" | Where-Object { $_.Name -notmatch 'quiz' } | Sort-Object Name
    foreach ($file in $files) {
        $name = ($file.BaseName -replace 'phase', '').Replace('-', '.')
        $content = Get-Content $file.FullName -Raw
        $h2Match = [regex]::Match($content, '<h2[^>]*>(.*?)</h2>', 'Singleline')
        $h2 = $h2Match.Groups[1].Value -replace '<[^>]+>', ''
        Write-Output ("$name " + $h2.Trim())
        $matches = [regex]::Matches($content, '<h3[^>]*>(.*?)</h3>', 'Singleline')
        foreach ($m in $matches) {
            $t = $m.Groups[1].Value -replace '<[^>]+>', ''
            if ($t.Trim()) { Write-Output ("  - " + $t.Trim()) }
        }
    }
    Write-Output ""
}

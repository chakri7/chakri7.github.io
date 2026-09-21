$ErrorActionPreference = "Stop"
$tabs = Invoke-RestMethod "http://127.0.0.1:9222/json/list"
$home = $false
Write-Host "Debug Chrome tab list:"
foreach ($t in $tabs) {
    Write-Host ("  type=$($t.type)  title=$($t.title)")
    Write-Host ("    $($t.url)")
    if ($t.type -eq "page" -and $t.url -match "247freepoker\.com" -and $t.url -notmatch "frame\.html") {
        $home = $true
    }
}
if (-not $home) {
    Write-Host "FAIL: debug Chrome has no homepage tab."
    Write-Host "A tab titled '247 Game Frame' is the isolated loader, not the live table."
    exit 1
}
Write-Host "OK: homepage tab is https://www.247freepoker.com/ (iframe src may still be game/frame.html)."
exit 0

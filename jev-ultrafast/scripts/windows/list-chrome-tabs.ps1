$ErrorActionPreference = "Stop"
$tabs = Invoke-RestMethod "http://127.0.0.1:9222/json/list"
Write-Host "Debug Chrome tab list:"
foreach ($t in $tabs) {
    Write-Host ("  type=$($t.type)  title=$($t.title)")
    Write-Host ("    $($t.url)")
}
exit 0

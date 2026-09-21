# Clone the poker branch if needed, then run Chrome debug + inspector.
# Safe from any directory. Does not assume C:\Users\2024\chakri7.github.io.
$ErrorActionPreference = "Stop"
Set-Location $HOME

$repo = Join-Path $HOME "chakri7.github.io"
$branch = "cursor/jev-ultrafast-poker-4ef6"
$url = "https://github.com/chakri7/chakri7.github.io.git"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git is not installed. Install https://git-scm.com/download/win then run this again."
}

if (-not (Test-Path (Join-Path $repo ".git"))) {
    Write-Host "Cloning $url ($branch) into $repo"
    git clone -b $branch $url $repo
    if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
} else {
    Write-Host "Updating existing clone $repo"
    Set-Location $repo
    git fetch origin $branch
    git checkout $branch
    git pull origin $branch
}

Set-Location $repo
$runner = Join-Path $repo "jev-ultrafast\scripts\windows\run-all.cmd"
if (-not (Test-Path $runner)) {
    throw "Still missing $runner. You are not on $branch. Run: git checkout $branch"
}

Get-ChildItem (Join-Path $repo "jev-ultrafast\scripts\windows") | Select-Object Name
cmd /c "`"$runner`""

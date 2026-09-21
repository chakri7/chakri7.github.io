# Clone the poker branch if needed, then run Chrome debug + inspector.
# Safe from any directory. Creates $HOME\chakri7.github.io if it is missing.
$ErrorActionPreference = "Stop"
Set-Location $HOME

$repo = Join-Path $HOME "chakri7.github.io"
$branch = "cursor/jev-ultrafast-poker-4ef6"
$url = "https://github.com/chakri7/chakri7.github.io.git"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is not installed. Install https://git-scm.com/download/win then run this again."
}

if (-not (Test-Path (Join-Path $repo ".git"))) {
    Write-Host "Cloning $url ($branch) into $repo"
    git clone -b $branch $url $repo
    if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
}

Set-Location $repo
git fetch origin $branch
if ($LASTEXITCODE -ne 0) { throw "git fetch failed" }
git checkout $branch
if ($LASTEXITCODE -ne 0) { throw "git checkout $branch failed" }
git reset --hard "origin/$branch"
if ($LASTEXITCODE -ne 0) { throw "git reset --hard origin/$branch failed" }
Write-Host "Running commit $(git rev-parse --short HEAD) on $branch"

$runner = Join-Path $repo "jev-ultrafast\scripts\windows\run-all.cmd"
if (-not (Test-Path $runner)) {
    throw "Still missing $runner after checkout. Expected files from $branch."
}

Get-ChildItem (Split-Path $runner) | Select-Object Name
cmd /c "`"$runner`""

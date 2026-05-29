param(
    [string]$ProjectId = "",
    [switch]$SkipLogin
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dist = Join-Path $root "dist"

Write-Host "Preparing dist folder at: $dist"
if (Test-Path $dist) {
    Remove-Item -Path $dist -Recurse -Force
}
New-Item -Path $dist -ItemType Directory | Out-Null

# Copy static pages and core assets only.
Get-ChildItem -Path $root -Filter "*.html" -File | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination (Join-Path $dist $_.Name) -Force
}

$rootFiles = @("styles.css", "site.js", "_redirects")
foreach ($fileName in $rootFiles) {
    $source = Join-Path $root $fileName
    if (Test-Path $source) {
        Copy-Item -Path $source -Destination (Join-Path $dist $fileName) -Force
    }
}

$assetsPath = Join-Path $root "assets"
if (Test-Path $assetsPath) {
    Copy-Item -Path $assetsPath -Destination (Join-Path $dist "assets") -Recurse -Force
}

$firebaseCmd = Get-Command firebase -ErrorAction SilentlyContinue
if (-not $firebaseCmd) {
    throw "Firebase CLI not found. Install with: npm install -g firebase-tools"
}

if (-not $SkipLogin) {
    Write-Host "Checking Firebase auth status..."
    try {
        firebase login:list | Out-Null
    }
    catch {
        Write-Host "No active Firebase login found. Launching login..."
        firebase login
    }
}

Push-Location $root
try {
    if ($ProjectId) {
        Write-Host "Deploying Hosting to project: $ProjectId"
        firebase deploy --only hosting --project $ProjectId
    }
    else {
        Write-Host "Deploying Hosting to the currently selected Firebase project"
        firebase deploy --only hosting
    }
}
finally {
    Pop-Location
}

<#
PowerShell script to download Inter font TTFs into `assets/fonts/`.
Usage: Run from project root in PowerShell:
  .\scripts\fetch_fonts.ps1

This script downloads files from the Google Fonts GitHub repository.
#>

$fonts = @(
    "Inter-Regular.ttf",
    "Inter-Medium.ttf",
    "Inter-SemiBold.ttf",
    "Inter-Bold.ttf"
)

$destDir = Join-Path -Path $PSScriptRoot -ChildPath "..\assets\fonts"
$destDir = Resolve-Path -Path $destDir | Select-Object -ExpandProperty Path

if (-not (Test-Path -Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

foreach ($font in $fonts) {
    $url = "https://github.com/google/fonts/raw/main/ofl/inter/$font"
    $outPath = Join-Path -Path $destDir -ChildPath $font
    Write-Host "Downloading $font..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $outPath -UseBasicParsing -ErrorAction Stop
        Write-Host "Saved to $outPath"
    }
    catch {
        Write-Warning "Failed to download $font from $url. Please download manually and place it in $destDir"
    }
}

Write-Host "Done. Verify the files in assets/fonts and update pubspec if filenames differ."
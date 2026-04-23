#requires -version 5.1
# Generate thumbnail and medium-sized variants of every JPEG in imgs/.
# Idempotent: skips outputs that are newer than their source.
# Usage:  powershell -ExecutionPolicy Bypass -File tools/resize-images.ps1

[CmdletBinding()]
param(
    [int]$ThumbLongEdge  = 800,
    [int]$ThumbQuality   = 82,
    [int]$MediumLongEdge = 1800,
    [int]$MediumQuality  = 85
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceDir   = Join-Path $projectRoot 'imgs'
$thumbDir    = Join-Path $sourceDir   'thumbs'
$mediumDir   = Join-Path $sourceDir   'medium'

foreach ($dir in @($thumbDir, $mediumDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object { $_.MimeType -eq 'image/jpeg' } |
    Select-Object -First 1

function Save-Resized {
    param(
        [string]$SourcePath,
        [string]$DestPath,
        [int]$LongEdge,
        [int]$Quality
    )

    $source = [System.Drawing.Image]::FromFile($SourcePath)
    try {
        $w = $source.Width
        $h = $source.Height
        $longest = [Math]::Max($w, $h)

        if ($longest -le $LongEdge) {
            $newW = $w
            $newH = $h
        } else {
            $scale = $LongEdge / $longest
            $newW = [int][Math]::Round($w * $scale)
            $newH = [int][Math]::Round($h * $scale)
        }

        $bitmap = New-Object System.Drawing.Bitmap $newW, $newH
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphics.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.DrawImage($source, 0, 0, $newW, $newH)
            } finally {
                $graphics.Dispose()
            }

            $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters 1
            $qualityParam = New-Object System.Drawing.Imaging.EncoderParameter(
                [System.Drawing.Imaging.Encoder]::Quality, [long]$Quality)
            $encoderParams.Param[0] = $qualityParam
            try {
                $bitmap.Save($DestPath, $jpegCodec, $encoderParams)
            } finally {
                $qualityParam.Dispose()
                $encoderParams.Dispose()
            }
        } finally {
            $bitmap.Dispose()
        }
    } finally {
        $source.Dispose()
    }
}

function Test-OutputFresh {
    param([string]$SourcePath, [string]$DestPath)
    if (-not (Test-Path $DestPath)) { return $false }
    $src = Get-Item $SourcePath
    $dst = Get-Item $DestPath
    return $dst.LastWriteTime -ge $src.LastWriteTime
}

$jpegs = Get-ChildItem -Path $sourceDir -Filter '*.jpg' -File
Write-Host "Found $($jpegs.Count) source images in $sourceDir"

$processed = 0
$skipped   = 0

foreach ($file in $jpegs) {
    $thumbPath  = Join-Path $thumbDir  $file.Name
    $mediumPath = Join-Path $mediumDir $file.Name

    $thumbFresh  = Test-OutputFresh $file.FullName $thumbPath
    $mediumFresh = Test-OutputFresh $file.FullName $mediumPath

    if ($thumbFresh -and $mediumFresh) {
        $skipped++
        continue
    }

    Write-Host "  $($file.Name)" -NoNewline

    if (-not $thumbFresh) {
        Save-Resized -SourcePath $file.FullName -DestPath $thumbPath `
                     -LongEdge $ThumbLongEdge -Quality $ThumbQuality
        Write-Host " [thumb]" -NoNewline
    }

    if (-not $mediumFresh) {
        Save-Resized -SourcePath $file.FullName -DestPath $mediumPath `
                     -LongEdge $MediumLongEdge -Quality $MediumQuality
        Write-Host " [medium]" -NoNewline
    }

    Write-Host ''
    $processed++
}

Write-Host ''
Write-Host "Done. Processed: $processed, skipped (already fresh): $skipped"
Write-Host "  Thumbs  -> $thumbDir"
Write-Host "  Medium  -> $mediumDir"

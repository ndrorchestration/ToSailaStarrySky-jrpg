param(
  [string]$OutputPath = "packaging\\one-file-launcher\\aetherwake.ico"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$directory = Split-Path -Parent $OutputPath
if ($directory) {
  New-Item -ItemType Directory -Path $directory -Force | Out-Null
}

$bitmap = New-Object System.Drawing.Bitmap 256, 256
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear([System.Drawing.ColorTranslator]::FromHtml("#07151f"))

$outerBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#6ee7c8"))
$innerBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#102f3a"))
$coreBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#f5c76b"))

$outer = [System.Drawing.PointF[]]@(
  (New-Object System.Drawing.PointF 45,164),
  (New-Object System.Drawing.PointF 128,35),
  (New-Object System.Drawing.PointF 211,164),
  (New-Object System.Drawing.PointF 128,221)
)
$inner = [System.Drawing.PointF[]]@(
  (New-Object System.Drawing.PointF 78,157),
  (New-Object System.Drawing.PointF 128,79),
  (New-Object System.Drawing.PointF 178,157),
  (New-Object System.Drawing.PointF 128,187)
)

$graphics.FillPolygon($outerBrush, $outer)
$graphics.FillPolygon($innerBrush, $inner)
$graphics.FillEllipse($coreBrush, 110, 125, 36, 36)

$handle = $bitmap.GetHicon()
$icon = [System.Drawing.Icon]::FromHandle($handle)
$stream = [System.IO.File]::Create($OutputPath)
try {
  $icon.Save($stream)
}
finally {
  $stream.Dispose()
  $icon.Dispose()
  $outerBrush.Dispose()
  $innerBrush.Dispose()
  $coreBrush.Dispose()
  $graphics.Dispose()
  $bitmap.Dispose()
}

if (-not (Test-Path -LiteralPath $OutputPath -PathType Leaf) -or
    (Get-Item -LiteralPath $OutputPath).Length -le 0) {
  throw "Failed to generate Aetherwake Windows icon"
}

Write-Host "Generated Aetherwake Windows icon: $OutputPath"

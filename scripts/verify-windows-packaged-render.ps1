param(
  [string]$RuntimeRoot = "$env:LOCALAPPDATA\Aetherwake\runtime",
  [string]$OutputPath = "artifact\aetherwake-packaged-window.png"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class AetherwakeWindowCapture {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);

    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
}
"@

$deadline = (Get-Date).AddSeconds(45)
$game = $null
while ((Get-Date) -lt $deadline -and -not $game) {
  Start-Sleep -Milliseconds 500
  $game = Get-Process -Name "Aetherwake" -ErrorAction SilentlyContinue |
    Where-Object {
      $_.MainWindowHandle -ne 0 -and
      $_.Path -and
      $_.Path.StartsWith($RuntimeRoot, [System.StringComparison]::OrdinalIgnoreCase)
    } |
    Select-Object -First 1
}

if (-not $game) {
  throw "No visible packaged Aetherwake window appeared"
}

$rect = New-Object AetherwakeWindowCapture+RECT
if (-not [AetherwakeWindowCapture]::GetWindowRect($game.MainWindowHandle, [ref]$rect)) {
  throw "Could not read the packaged Aetherwake window rectangle"
}

$width = $rect.Right - $rect.Left
$height = $rect.Bottom - $rect.Top
if ($width -lt 800 -or $height -lt 500) {
  throw "Packaged Aetherwake window is unexpectedly small: $width x $height"
}

$bitmap = New-Object System.Drawing.Bitmap $width, $height
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$hdc = $graphics.GetHdc()
try {
  $captured = [AetherwakeWindowCapture]::PrintWindow($game.MainWindowHandle, $hdc, 2)
}
finally {
  $graphics.ReleaseHdc($hdc)
  $graphics.Dispose()
}

if (-not $captured) {
  $bitmap.Dispose()
  throw "PrintWindow could not capture the packaged Aetherwake window"
}

$directory = Split-Path -Parent $OutputPath
if ($directory) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
$bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$colors = New-Object 'System.Collections.Generic.HashSet[string]'
$nonBlack = 0
$opaqueSamples = 0
for ($y = 24; $y -lt $height; $y += 32) {
  for ($x = 24; $x -lt $width; $x += 32) {
    $pixel = $bitmap.GetPixel($x, $y)
    [void]$colors.Add("$($pixel.R),$($pixel.G),$($pixel.B),$($pixel.A)")
    if ($pixel.A -gt 0) { $opaqueSamples++ }
    if (($pixel.R + $pixel.G + $pixel.B) -gt 12) { $nonBlack++ }
  }
}

$bitmap.Dispose()

Write-Host "Packaged window: $width x $height"
Write-Host "Unique sampled colors: $($colors.Count)"
Write-Host "Opaque samples: $opaqueSamples"
Write-Host "Non-black samples: $nonBlack"
Write-Host "Screenshot: $OutputPath"

if ($opaqueSamples -lt 100) {
  throw "Packaged Aetherwake window did not contain enough opaque pixels"
}
if ($colors.Count -lt 4) {
  throw "Packaged Aetherwake window is visually uniform/blank ($($colors.Count) sampled colors)"
}
if ($nonBlack -lt 20) {
  throw "Packaged Aetherwake window is effectively black/blank ($nonBlack non-black samples)"
}

Write-Host "AETHERWAKE_PACKAGED_WINDOW_RENDER=PASS"

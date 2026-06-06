# Buat dataset digit cetak multi-font untuk OCR Tenun.
# Render tiap digit 0-9 pada banyak font/ukuran/gaya, bounding-box crop,
# resize nearest ke 12x16, grayscale. Output: digit_dataset.txt
#   format tiap baris: "label v0 v1 ... v191" (gray 0-255).
# Pra-pemrosesan SAMA dgn examples/ocr_nik.tenun (bbox + nearest 12x16).
Add-Type -AssemblyName System.Drawing
$W = 12; $H = 16
$out = Join-Path $PSScriptRoot "..\digit_dataset.txt"

$fonts = @("Arial","Calibri","Times New Roman","Consolas","Verdana","Tahoma",
  "Segoe UI","Courier New","Georgia","Trebuchet MS","Cambria","Lucida Console",
  "Franklin Gothic Medium","Bahnschrift","Comic Sans MS","Microsoft Sans Serif",
  "Candara","Corbel","Constantia")
$inst = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
$fonts = $fonts | Where-Object { $inst -contains $_ }
$sizes = @(16)
$styles = @([System.Drawing.FontStyle]::Bold, [System.Drawing.FontStyle]::Regular)

$sb = New-Object System.Text.StringBuilder
$count = 0
foreach ($d in 0..9) {
  foreach ($fam in $fonts) {
    foreach ($sz in $sizes) {
      foreach ($st in $styles) {
        $cw = 48; $ch = 48
        $bmp = New-Object System.Drawing.Bitmap $cw, $ch
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::White)
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        try { $font = New-Object System.Drawing.Font($fam, $sz, $st, [System.Drawing.GraphicsUnit]::Pixel) }
        catch { $g.Dispose(); $bmp.Dispose(); continue }
        $g.DrawString("$d", $font, [System.Drawing.Brushes]::Black, 10, 6)
        $g.Dispose(); $font.Dispose()

        $minx = $cw; $miny = $ch; $maxx = -1; $maxy = -1
        for ($y = 0; $y -lt $ch; $y++) { for ($x = 0; $x -lt $cw; $x++) {
          $p = $bmp.GetPixel($x, $y)
          $gr = [int](($p.R * 299 + $p.G * 587 + $p.B * 114) / 1000)
          if ($gr -lt 128) {
            if ($x -lt $minx) { $minx = $x }; if ($x -gt $maxx) { $maxx = $x }
            if ($y -lt $miny) { $miny = $y }; if ($y -gt $maxy) { $maxy = $y }
          }
        } }
        if ($maxx -lt 0) { $bmp.Dispose(); continue }
        $bw = $maxx - $minx + 1; $bh = $maxy - $miny + 1
        $crop = New-Object System.Drawing.Bitmap $bw, $bh
        $gc = [System.Drawing.Graphics]::FromImage($crop)
        $gc.DrawImage($bmp, (New-Object System.Drawing.Rectangle 0, 0, $bw, $bh), (New-Object System.Drawing.Rectangle $minx, $miny, $bw, $bh), [System.Drawing.GraphicsUnit]::Pixel)
        $gc.Dispose(); $bmp.Dispose()
        $small = New-Object System.Drawing.Bitmap $W, $H
        $gs = [System.Drawing.Graphics]::FromImage($small)
        $gs.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $gs.DrawImage($crop, 0, 0, $W, $H)
        $gs.Dispose(); $crop.Dispose()

        $vals = New-Object System.Collections.Generic.List[string]
        for ($y = 0; $y -lt $H; $y++) { for ($x = 0; $x -lt $W; $x++) {
          $p = $small.GetPixel($x, $y)
          $gr = [int](($p.R * 299 + $p.G * 587 + $p.B * 114) / 1000)
          $vals.Add($gr)
        } }
        $small.Dispose()
        [void]$sb.AppendLine("$d " + ($vals -join " ")); $count++
      }
    }
  }
}
[IO.File]::WriteAllText($out, $sb.ToString())
Write-Output "samples: $count, fonts: $($fonts.Count)"

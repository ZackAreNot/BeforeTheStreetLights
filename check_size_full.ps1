Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile("c:\Users\Zaki\Gamedev\Gemastik\BeforeTheStreetLights\assets\NewMaps\Map1\FullMap1.png")
Write-Output "FullMap1: $($img.Width)x$($img.Height)"
$img.Dispose()

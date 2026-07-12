Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile("c:\Users\Zaki\Gamedev\Gemastik\BeforeTheStreetLights\assets\NewMaps\Map1\layer2tianglistrik.png")
Write-Output "$($img.Width)x$($img.Height)"
$img.Dispose()

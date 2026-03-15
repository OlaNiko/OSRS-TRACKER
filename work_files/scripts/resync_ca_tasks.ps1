$ErrorActionPreference = "Stop"

$htmlPath = "C:\Users\OlaNi\Documents\New project\work_files\ca_all_tasks.html"
$outJson = "C:\Users\OlaNi\Documents\New project\work_files\ca_tasks.json"
$outJs = "C:\Users\OlaNi\Documents\New project\work_files\ca_tasks.js"

$url = "https://oldschool.runescape.wiki/w/Combat_Achievements/All_tasks?action=render"

Write-Output "Fetching CA all tasks..."
Invoke-WebRequest -Uri $url -UseBasicParsing | Select-Object -ExpandProperty Content | Out-File -FilePath $htmlPath -Encoding UTF8

Write-Output "Parsing CA tasks..."
& "C:\Users\OlaNi\Documents\New project\work_files\scripts\parse_ca_html.ps1"

if ((Test-Path $outJson) -and (Test-Path $outJs)) {
  $jsonSize = (Get-Item $outJson).Length
  $jsSize = (Get-Item $outJs).Length
  Write-Output "Done. ca_tasks.json=$jsonSize bytes, ca_tasks.js=$jsSize bytes"
} else {
  Write-Output "Resync finished, but output files are missing."
}

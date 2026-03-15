$ErrorActionPreference = "Stop"

$htmlPath = "C:\Users\OlaNi\Documents\New project\osrs_tracker_26.7.html"
$dbPath = "C:\Users\OlaNi\Documents\New project\work_files\osrsbox_items_complete.json"
$outJs = "C:\Users\OlaNi\Documents\New project\work_files\gear_reqs.js"
$outMissing = "C:\Users\OlaNi\Documents\New project\work_files\gear_reqs_missing.txt"

if (!(Test-Path $htmlPath)) { throw "Missing $htmlPath" }
if (!(Test-Path $dbPath)) { throw "Missing $dbPath" }

$html = Get-Content $htmlPath -Raw

# Extract item names from GI(...) calls.
$names = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
$rx = [regex]::new('GI\((?:''([^'']+)''|"([^"]+)")')
foreach ($m in $rx.Matches($html)) {
  $name = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
  if ($name) { $null = $names.Add($name) }
}

# Load OSRSBox DB text and regex-extract name + requirements blocks.
$jsonText = Get-Content $dbPath -Raw
# Strip large base64 icon blobs to keep item blocks small.
$jsonText = [regex]::Replace($jsonText, '"icon":"[^"]*"', '"icon":""')
$reqs = @{}
$found = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)

$itemRx = [regex]::new('"name"\s*:\s*"([^"]+)".{0,8000}?"requirements"\s*:\s*{([^}]+)}',[System.Text.RegularExpressions.RegexOptions]::Singleline)
$reqRx = [regex]::new('"([^"]+)"\s*:\s*([0-9]+)')

foreach ($m in $itemRx.Matches($jsonText)) {
  $name = $m.Groups[1].Value
  if (-not $names.Contains($name)) { continue }
  $reqBlock = $m.Groups[2].Value
  $map = @{}
  foreach ($rm in $reqRx.Matches($reqBlock)) {
    $k = $rm.Groups[1].Value
    $v = [int]$rm.Groups[2].Value
    if ($v -le 0) { continue }
    switch ($k.ToLowerInvariant()) {
      "attack" { $map.Attack = $v }
      "strength" { $map.Strength = $v }
      "defence" { $map.Defence = $v }
      "ranged" { $map.Ranged = $v }
      "magic" { $map.Magic = $v }
      "prayer" { $map.Prayer = $v }
      "hitpoints" { $map.Hitpoints = $v }
      "agility" { $map.Agility = $v }
      "herblore" { $map.Herblore = $v }
      "slayer" { $map.Slayer = $v }
      "mining" { $map.Mining = $v }
      "smithing" { $map.Smithing = $v }
      "crafting" { $map.Crafting = $v }
      "fishing" { $map.Fishing = $v }
      "firemaking" { $map.Firemaking = $v }
      "woodcutting" { $map.Woodcutting = $v }
      "runecraft" { $map.Runecraft = $v }
      "fletching" { $map.Fletching = $v }
      "thieving" { $map.Thieving = $v }
      "farming" { $map.Farming = $v }
      "hunter" { $map.Hunter = $v }
      "construction" { $map.Construction = $v }
    }
  }
  if ($map.Count -gt 0) {
    $reqs[$name] = $map
    $null = $found.Add($name)
  }
}

$missing = $names | Where-Object { -not $found.Contains($_) } | Sort-Object
$missing | Out-File -FilePath $outMissing -Encoding UTF8

# Write JS overrides
$json = $reqs | ConvertTo-Json -Depth 4
"window.GEAR_REQ_OVERRIDES = $json;" | Out-File -FilePath $outJs -Encoding UTF8

Write-Output "Wrote $outJs and $outMissing"

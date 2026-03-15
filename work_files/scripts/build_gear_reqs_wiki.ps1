$ErrorActionPreference = "Stop"

$htmlPath = "C:\Users\OlaNi\Documents\New project\osrs_tracker_26.9.html"
$outJs = "C:\Users\OlaNi\Documents\New project\work_files\gear_reqs_wiki.js"
$outMissing = "C:\Users\OlaNi\Documents\New project\work_files\gear_reqs_wiki_missing.txt"

$html = Get-Content $htmlPath -Raw

# Extract item names from GI(...) calls.
$names = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
$rx = [regex]::new('GI\((?:''([^'']+)''|"([^"]+)")')
foreach ($m in $rx.Matches($html)) {
  $name = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
  if ($name) { $null = $names.Add($name) }
}

$reqs = @{}
$missing = New-Object System.Collections.Generic.List[string]

function Add-Req {
  param([hashtable]$map,[string]$skill,[int]$level)
  if ($level -le 0) { return }
  switch ($skill.Trim().ToLowerInvariant()) {
    "attack" { $map.Attack = $level }
    "strength" { $map.Strength = $level }
    "defence" { $map.Defence = $level }
    "defense" { $map.Defence = $level }
    "ranged" { $map.Ranged = $level }
    "magic" { $map.Magic = $level }
    "prayer" { $map.Prayer = $level }
    "hitpoints" { $map.Hitpoints = $level }
    "agility" { $map.Agility = $level }
    "herblore" { $map.Herblore = $level }
    "slayer" { $map.Slayer = $level }
    "mining" { $map.Mining = $level }
    "smithing" { $map.Smithing = $level }
    "crafting" { $map.Crafting = $level }
    "fishing" { $map.Fishing = $level }
    "firemaking" { $map.Firemaking = $level }
    "woodcutting" { $map.Woodcutting = $level }
    "runecraft" { $map.Runecraft = $level }
    "fletching" { $map.Fletching = $level }
    "thieving" { $map.Thieving = $level }
    "farming" { $map.Farming = $level }
    "hunter" { $map.Hunter = $level }
    "construction" { $map.Construction = $level }
  }
}

function Parse-Reqs {
  param([string]$text)
  $map = @{}
  if (-not $text) { return $map }

  # Pattern 1: sentence containing "requires level ..."
  $rxSentence = [regex]::new('requires level[^.\n]+', 'IgnoreCase')
  $sent = $rxSentence.Match($text)
  if ($sent.Success) {
    $rxLevels = [regex]::new('(\d+)\s*\[\[([A-Za-z ]+)\]\]', 'IgnoreCase')
    foreach ($m in $rxLevels.Matches($sent.Value)) {
      Add-Req $map $m.Groups[2].Value ([int]$m.Groups[1].Value)
    }
  }

  # Pattern 2: Requirements template like {{Requirements|Attack=75|Defence=70}}
  $rxTpl = [regex]::new('\{\{Requirements\|([^}]+)\}\}', 'IgnoreCase')
  $tpl = $rxTpl.Match($text)
  if ($tpl.Success) {
    $parts = $tpl.Groups[1].Value -split '\|'
    foreach ($p in $parts) {
      if ($p -match '^\s*([A-Za-z ]+)\s*=\s*([0-9]+)') {
        Add-Req $map $matches[1] ([int]$matches[2])
      }
    }
  }

  return $map
}

foreach ($name in ($names | Sort-Object)) {
  $title = $name.Replace(' ', '_')
  $url = "https://oldschool.runescape.wiki/w/$([uri]::EscapeDataString($title))?action=raw"
  try {
    $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0 (GearReqBot)' }
    $text = $resp.Content
    $map = Parse-Reqs $text
    if ($map.Count -gt 0) {
      $reqs[$name] = $map
    } else {
      $missing.Add($name) | Out-Null
    }
  } catch {
    $missing.Add($name) | Out-Null
  }
  Start-Sleep -Milliseconds 150
}

$missing | Sort-Object | Out-File -FilePath $outMissing -Encoding UTF8
$json = $reqs | ConvertTo-Json -Depth 4
"window.GEAR_REQ_OVERRIDES = $json;" | Out-File -FilePath $outJs -Encoding UTF8

Write-Output "Wrote $outJs and $outMissing"

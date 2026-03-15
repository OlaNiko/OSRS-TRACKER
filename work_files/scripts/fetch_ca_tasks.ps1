$ErrorActionPreference = "Stop"

$outJson = "C:\Users\OlaNi\Documents\New project\ca_tasks.json"
$outJs = "C:\Users\OlaNi\Documents\New project\ca_tasks.js"

$text = "{{#invoke:Combat_Achievements_Json|json}}"
$api = "https://oldschool.runescape.wiki/api.php?action=expandtemplates&text=$([uri]::EscapeDataString($text))&prop=wikitext&format=json&origin=*"
$resp = Invoke-WebRequest -Uri $api -UseBasicParsing
$data = $resp.Content | ConvertFrom-Json
$raw = $data.expandtemplates.wikitext
if (-not $raw) { throw "No CA data from wiki" }
$start = $raw.IndexOf('[')
$end = $raw.LastIndexOf(']')
if ($start -ge 0 -and $end -gt $start) {
  $raw = $raw.Substring($start, $end - $start + 1)
}

$items = $raw | ConvertFrom-Json

function Normalize-Tier {
  param([string]$t)
  if (-not $t) { return "" }
  $s = $t.ToLower()
  if ($s.StartsWith("easy")) { return "Easy" }
  if ($s.StartsWith("medium")) { return "Medium" }
  if ($s.StartsWith("hard")) { return "Hard" }
  if ($s.StartsWith("elite")) { return "Elite" }
  if ($s.StartsWith("master")) { return "Master" }
  if ($s.StartsWith("grand")) { return "Grandmaster" }
  return $t
}

$tierPts = @{
  Easy = 1
  Medium = 2
  Hard = 3
  Elite = 4
  Master = 5
  Grandmaster = 6
}

$out = @()
foreach ($t in $items) {
  $boss = $t.monster
  if (-not $boss) { $boss = $t.boss }
  if (-not $boss) { $boss = $t.monsters }
  $name = $t.name
  if (-not $name) { $name = $t.task }
  $tier = Normalize-Tier $t.tier
  $type = $t.type
  if (-not $type) { $type = $t.tasktype }
  $desc = $t.description
  if (-not $desc) { $desc = $t.desc }
  $pts = $tierPts[$tier]
  if ($boss -and $name -and $tier -and $pts) {
    $out += ,@($boss, $name, $tier, $pts, ($type -as [string]), ($desc -as [string]))
  }
}

$json = $out | ConvertTo-Json -Depth 6
$json | Out-File -FilePath $outJson -Encoding UTF8
$js = "window.CA_RAW_OVERRIDE = " + $json + ";"
$js | Out-File -FilePath $outJs -Encoding UTF8

Write-Output "Wrote $outJson and $outJs"

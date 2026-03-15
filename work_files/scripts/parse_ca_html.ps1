$ErrorActionPreference = "Stop"

$htmlPath = "C:\Users\OlaNi\Documents\New project\work_files\ca_all_tasks.html"
$outJson = "C:\Users\OlaNi\Documents\New project\work_files\ca_tasks.json"
$outJs = "C:\Users\OlaNi\Documents\New project\work_files\ca_tasks.js"

$html = Get-Content $htmlPath -Raw

function Clean-Text {
  param([string]$s)
  if (-not $s) { return "" }
  $t = $s -replace "<br\s*/?>", "`n"
  $t = $t -replace "<[^>]+>", " "
  $t = [System.Net.WebUtility]::HtmlDecode($t)
  $t = $t -replace "\s+", " "
  return $t.Trim()
}

$tierPts = @{
  Easy = 1
  Medium = 2
  Hard = 3
  Elite = 4
  Master = 5
  Grandmaster = 6
}

$rows = [regex]::Matches($html, "<tr[^>]*data-ca-task-id=""[^""]+""[^>]*>(.*?)</tr>", "Singleline")
$out = @()

foreach ($m in $rows) {
  $row = $m.Groups[1].Value
  $cells = [regex]::Matches($row, "<td[^>]*>(.*?)</td>", "Singleline") | ForEach-Object { $_.Groups[1].Value }
  if ($cells.Count -lt 5) { continue }
  $boss = Clean-Text $cells[0]
  $name = Clean-Text $cells[1]
  $desc = Clean-Text $cells[2]
  $type = Clean-Text $cells[3]
  $tierRaw = Clean-Text $cells[4]
  $tier = ($tierRaw -split "\s+")[0]
  $pts = $tierPts[$tier]
  if ($boss -and $name -and $tier -and $pts) {
    $out += ,@($boss, $name, $tier, $pts, $type, $desc)
  }
}

$jsonItems = $out | ForEach-Object { $_ | ConvertTo-Json -Compress }
$json = "[" + ($jsonItems -join ",") + "]"
$json | Out-File -FilePath $outJson -Encoding UTF8
$js = "window.CA_RAW_OVERRIDE = " + $json + ";"
$js | Out-File -FilePath $outJs -Encoding UTF8

Write-Output "Wrote $outJson and $outJs"

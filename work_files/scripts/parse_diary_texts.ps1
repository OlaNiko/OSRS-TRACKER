$ErrorActionPreference = "Stop"

$inDir = "C:\Users\OlaNi\Documents\New project\diary_texts"
$outJson = "C:\Users\OlaNi\Documents\New project\diary_tasks.json"
$outJs = "C:\Users\OlaNi\Documents\New project\diary_tasks.js"

$files = Get-ChildItem -Path $inDir -Filter *.txt | Sort-Object Name

$result = [ordered]@{}
$counts = [ordered]@{}

foreach ($file in $files) {
  $regionName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) -replace "_", " "
  if ($regionName -eq "Kourend Kebos") { $regionName = "Kourend & Kebos" }
  if ($regionName -eq "Lumbridge Draynor") { $regionName = "Lumbridge & Draynor" }

  $tiers = [ordered]@{
    easy   = @()
    medium = @()
    hard   = @()
    elite  = @()
  }

  $currentTier = $null
  Get-Content $file.FullName | ForEach-Object {
    $line = ($_ -replace "\s+", " ").Trim()
    if (-not $line) { return }
    if ($line -match "^(Easy|Medium|Hard|Elite)$") {
      $currentTier = $line.ToLower()
      return
    }
    if ($line -match "^\d+\.\s+(.+)$" -and $currentTier) {
      $task = $Matches[1].Trim()
      $task = $task -replace "\s+\.$", "."
      $tiers[$currentTier] += $task
    }
  }

  $result[$regionName] = $tiers
  $counts[$regionName] = [ordered]@{
    easy   = $tiers.easy.Count
    medium = $tiers.medium.Count
    hard   = $tiers.hard.Count
    elite  = $tiers.elite.Count
  }
}

$json = $result | ConvertTo-Json -Depth 6
$json | Out-File -FilePath $outJson -Encoding UTF8

$js = "window.DIARY_TASKS_OVERRIDE = " + $json + ";"
$js | Out-File -FilePath $outJs -Encoding UTF8

Write-Output "Wrote $outJson and $outJs"
Write-Output ($counts | ConvertTo-Json -Depth 3)

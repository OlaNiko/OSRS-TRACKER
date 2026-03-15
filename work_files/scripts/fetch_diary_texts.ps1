$ErrorActionPreference = "Stop"

$outDir = "C:\Users\OlaNi\Documents\New project\diary_texts"
if (-not (Test-Path $outDir)) {
  New-Item -ItemType Directory -Path $outDir | Out-Null
}

$pages = @(
  @{ name = "Ardougne"; slug = "Ardougne_Diary" },
  @{ name = "Desert"; slug = "Desert_Diary" },
  @{ name = "Falador"; slug = "Falador_Diary" },
  @{ name = "Fremennik"; slug = "Fremennik_Diary" },
  @{ name = "Kandarin"; slug = "Kandarin_Diary" },
  @{ name = "Karamja"; slug = "Karamja_Diary" },
  @{ name = "Kourend_Kebos"; slug = "Kourend_%26_Kebos_Diary" },
  @{ name = "Lumbridge_Draynor"; slug = "Lumbridge_%26_Draynor_Diary" },
  @{ name = "Morytania"; slug = "Morytania_Diary" },
  @{ name = "Varrock"; slug = "Varrock_Diary" },
  @{ name = "Western_Provinces"; slug = "Western_Provinces_Diary" },
  @{ name = "Wilderness"; slug = "Wilderness_Diary" }
)

function Convert-HtmlToText {
  param([string]$html)
  if (-not $html) { return "" }
  $text = $html
  $text = $text -replace "<script[\s\S]*?</script>", " "
  $text = $text -replace "<style[\s\S]*?</style>", " "
  $text = $text -replace "<br\s*/?>", "`n"
  $text = $text -replace "</p>", "`n`n"
  $text = $text -replace "</li>", "`n"
  $text = $text -replace "</h\d>", "`n"
  $text = $text -replace "<[^>]+>", " "
  $text = [System.Net.WebUtility]::HtmlDecode($text)
  $text = $text -replace "[`r`n]{3,}", "`n`n"
  $text = ($text -replace "[ \t]{2,}", " ").Trim()
  return $text
}

foreach ($p in $pages) {
  $url = "https://oldschool.runescape.wiki/w/$($p.slug)?action=render"
  $resp = Invoke-WebRequest -Uri $url -UseBasicParsing
  $text = Convert-HtmlToText $resp.Content
  $path = Join-Path $outDir ($p.name + ".txt")
  $text | Out-File -FilePath $path -Encoding UTF8
}

Write-Output "Wrote diary texts to $outDir"

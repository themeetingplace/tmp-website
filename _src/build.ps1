# 聚空間官網 mini 靜態站產生器
# 讀 pages.json + partials + 每頁內容片段，組出 deploy\ 下的真實多網址靜態頁面 + sitemap.xml
# 沒有 Node/npm 環境，改用 PowerShell token 置換模擬最小 SSG

$ErrorActionPreference = "Stop"
$srcDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$deployDir = Split-Path -Parent $srcDir
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Read-Utf8($path) {
  return [System.IO.File]::ReadAllText($path)
}
function Write-Utf8($path, $content) {
  $dir = Split-Path -Parent $path
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

$manifest = Get-Content (Join-Path $srcDir "pages.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$baseUrl = $manifest.baseUrl

$layout = Read-Utf8 (Join-Path $srcDir "partials\layout.html")
$header = Read-Utf8 (Join-Path $srcDir "partials\header.html")
$footer = Read-Utf8 (Join-Path $srcDir "partials\footer.html")
$scripts = Read-Utf8 (Join-Path $srcDir "partials\scripts.html")
$landlordForm = Read-Utf8 (Join-Path $srcDir "partials\landlord-form.html")
$styles = Read-Utf8 (Join-Path $srcDir "styles\main.css")

$sitemapEntries = @()

foreach ($p in $manifest.pages) {
  $content = Read-Utf8 (Join-Path $srcDir $p.contentFile)
  $content = $content.Replace("{{LANDLORD_FORM}}", $landlordForm)

  $canonical = $baseUrl + $p.url
  $ogImage = $baseUrl + $p.ogImage

  $jsonldBlock = ""
  if ($null -ne $p.jsonld) {
    if ($p.jsonld -is [System.Array]) {
      $ld = [ordered]@{ "@context" = "https://schema.org"; "@graph" = $p.jsonld }
    } else {
      $ld = [ordered]@{ "@context" = "https://schema.org" }
      foreach ($prop in $p.jsonld.PSObject.Properties) { $ld[$prop.Name] = $prop.Value }
    }
    $ldJson = $ld | ConvertTo-Json -Depth 10
    $jsonldBlock = "<script type=`"application/ld+json`">`n$ldJson`n</script>"
  }

  $page = $layout
  $page = $page.Replace("{{TITLE}}", $p.title)
  $page = $page.Replace("{{META_DESC}}", $p.metaDesc)
  $page = $page.Replace("{{CANONICAL}}", $canonical)
  $page = $page.Replace("{{OG_TITLE}}", $p.title)
  $page = $page.Replace("{{OG_DESC}}", $p.metaDesc)
  $page = $page.Replace("{{OG_IMAGE}}", $ogImage)
  $page = $page.Replace("{{JSONLD}}", $jsonldBlock)
  $page = $page.Replace("{{STYLES}}", $styles)
  $page = $page.Replace("{{DATA_PAGE}}", $p.dataPage)
  $page = $page.Replace("{{HEADER}}", $header)
  $page = $page.Replace("{{CONTENT}}", $content)
  $page = $page.Replace("{{FOOTER}}", $footer)
  $page = $page.Replace("{{SCRIPTS}}", $scripts)

  $outPath = Join-Path $deployDir $p.outPath
  Write-Utf8 $outPath $page
  Write-Output "Built: $($p.outPath)"

  $sitemapEntries += "  <url><loc>$canonical</loc></url>"
}

$sitemap = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<urlset xmlns=`"http://www.sitemaps.org/schemas/sitemap/0.9`">`n" + ($sitemapEntries -join "`n") + "`n</urlset>`n"
Write-Utf8 (Join-Path $deployDir "sitemap.xml") $sitemap
Write-Output "Built: sitemap.xml"

Write-Output "Done. $($manifest.pages.Count) pages generated."

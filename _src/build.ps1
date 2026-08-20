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
$headerEn = Read-Utf8 (Join-Path $srcDir "partials\header-en.html")
$footerEn = Read-Utf8 (Join-Path $srcDir "partials\footer-en.html")
$scripts = Read-Utf8 (Join-Path $srcDir "partials\scripts.html")
$landlordForm = Read-Utf8 (Join-Path $srcDir "partials\landlord-form.html")
$styles = Read-Utf8 (Join-Path $srcDir "styles\main.css")

# CSS/JS 改成外部可快取檔案（原本每頁都內嵌一份 main.css，同樣內容重複下載 12 次，
# 也無法被瀏覽器快取；現在寫成 /assets/css, /assets/js 底下的真實檔案，
# 版本號用內容雜湊算，內容一變網址就變，不會被舊快取卡住）
function Get-ShortHash($text) {
  $md5 = [System.Security.Cryptography.MD5]::Create()
  $bytes = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($text))
  return ([System.BitConverter]::ToString($bytes) -replace '-','').Substring(0,10).ToLower()
}
$cssVer = Get-ShortHash $styles
$jsVer = Get-ShortHash $scripts
Write-Utf8 (Join-Path $deployDir "assets\css\main.css") $styles
Write-Utf8 (Join-Path $deployDir "assets\js\main.js") $scripts
Write-Output "Built: assets/css/main.css ($cssVer), assets/js/main.js ($jsVer)"

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

  $preloadBlock = ""
  if ($null -ne $p.preloadImage -and $p.preloadImage -ne "") {
    $preloadBlock = "<link rel=`"preload`" as=`"image`" href=`"$($p.preloadImage)`">"
  }

  # 語言：預設 zh，peer 是同一頁在另一語言下的網址（沒填就退回該語言首頁，讓語言切換鈕永遠有地方可去）
  $lang = if ($p.lang) { $p.lang } else { "zh" }
  $hasPeer = ($null -ne $p.peer -and $p.peer -ne "")
  $peerUrl = if ($hasPeer) { $p.peer } else { if ($lang -eq "en") { "/" } else { "/en/" } }

  $zhChar = [char]0x4E2D
  $sepChar = [char]0xFF5C
  if ($lang -eq "en") {
    $langToggleHtml = "<a href=`"$peerUrl`">$zhChar</a><span class=`"v3-lang-sep`">$sepChar</span><span class=`"is-current`">EN</span>"
    $headerTemplate = $headerEn
    $footerTemplate = $footerEn
  } else {
    $langToggleHtml = "<span class=`"is-current`">$zhChar</span><span class=`"v3-lang-sep`">$sepChar</span><a href=`"$peerUrl`">EN</a>"
    $headerTemplate = $header
    $footerTemplate = $footer
  }
  $headerForPage = $headerTemplate.Replace("{{LANG_TOGGLE}}", $langToggleHtml)

  $hreflangBlock = ""
  if ($hasPeer) {
    $selfHreflang = if ($lang -eq "en") { "en" } else { "zh-Hant" }
    $peerHreflang = if ($lang -eq "en") { "zh-Hant" } else { "en" }
    $peerAbsUrl = $baseUrl + $peerUrl
    $hreflangBlock = "<link rel=`"alternate`" hreflang=`"$selfHreflang`" href=`"$canonical`">`n<link rel=`"alternate`" hreflang=`"$peerHreflang`" href=`"$peerAbsUrl`">"
  }

  $page = $layout
  $page = $page.Replace("{{TITLE}}", $p.title)
  $page = $page.Replace("{{META_DESC}}", $p.metaDesc)
  $page = $page.Replace("{{CANONICAL}}", $canonical)
  $page = $page.Replace("{{HREFLANG}}", $hreflangBlock)
  $page = $page.Replace("{{OG_TITLE}}", $p.title)
  $page = $page.Replace("{{OG_DESC}}", $p.metaDesc)
  $page = $page.Replace("{{OG_IMAGE}}", $ogImage)
  $page = $page.Replace("{{JSONLD}}", $jsonldBlock)
  $page = $page.Replace("{{PRELOAD}}", $preloadBlock)
  $page = $page.Replace("{{CSS_VER}}", $cssVer)
  $page = $page.Replace("{{JS_VER}}", $jsVer)
  $page = $page.Replace("{{DATA_PAGE}}", $p.dataPage)
  $page = $page.Replace("{{LANG}}", $lang)
  $page = $page.Replace("{{PEER_URL}}", $peerUrl)
  $page = $page.Replace("{{HEADER}}", $headerForPage)
  $page = $page.Replace("{{CONTENT}}", $content)
  $page = $page.Replace("{{FOOTER}}", $footerTemplate)

  $outPath = Join-Path $deployDir $p.outPath
  Write-Utf8 $outPath $page
  Write-Output "Built: $($p.outPath)"

  $sitemapEntries += "  <url><loc>$canonical</loc></url>"
}

$sitemap = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<urlset xmlns=`"http://www.sitemaps.org/schemas/sitemap/0.9`">`n" + ($sitemapEntries -join "`n") + "`n</urlset>`n"
Write-Utf8 (Join-Path $deployDir "sitemap.xml") $sitemap
Write-Output "Built: sitemap.xml"

Write-Output "Done. $($manifest.pages.Count) pages generated."

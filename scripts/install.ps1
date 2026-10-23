$ErrorActionPreference = 'Stop'

$version = $env:SKLAIR_VERSION -creplace '^v', ''
if ($version -cnotmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?$') {
    throw 'Specify a Sklair release version, for example 0.4.0 or v0.4.0.'
}
if ($env:RUNNER_OS -ne 'Windows') {
    throw "Unsupported runner OS: $env:RUNNER_OS"
}
switch ($env:RUNNER_ARCH) {
    'X64' { $architecture = 'amd64' }
    'ARM64' { $architecture = 'arm64' }
    default { throw "Unsupported runner architecture: $env:RUNNER_ARCH" }
}

$installation = Join-Path $env:RUNNER_TEMP "setup-sklair-$([guid]::NewGuid())"
$bin = Join-Path $installation 'bin'
$null = New-Item -ItemType Directory -Path $bin
$archive = "sklair-windows-$architecture.zip"
$archivePath = Join-Path $installation $archive
$baseUrl = "https://github.com/numelon-oss/sklair/releases/download/v$version"
Invoke-WebRequest "$baseUrl/$archive" -OutFile $archivePath
$manifestPath = Join-Path $installation 'SHA256SUMS'
Invoke-WebRequest "$baseUrl/SHA256SUMS" -OutFile $manifestPath
$checksums = Get-Content -LiteralPath $manifestPath -Raw

$pattern = '^([0-9a-fA-F]{64}) [ *]' + [regex]::Escape($archive) + '\r?$'
$entries = [regex]::Matches($checksums, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
if ($entries.Count -ne 1) {
    throw "Missing, duplicate, or invalid checksum for $archive."
}
if ((Get-FileHash $archivePath -Algorithm SHA256).Hash -ne $entries[0].Groups[1].Value) {
    throw "Checksum mismatch for $archive."
}

Expand-Archive -LiteralPath $archivePath -DestinationPath $bin
& (Join-Path $bin 'sklair.exe') version
if ($LASTEXITCODE -ne 0) { throw "Sklair could not run ($LASTEXITCODE)." }
Add-Content -LiteralPath $env:GITHUB_PATH -Value $bin -Encoding utf8

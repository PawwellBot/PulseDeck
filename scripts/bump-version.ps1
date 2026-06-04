param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$VersionArgs
)

$ErrorActionPreference = "Stop"

function Show-Usage {
  @"
Usage:
  scripts\bump-version.ps1 patch
  scripts\bump-version.ps1 minor
  scripts\bump-version.ps1 major
  scripts\bump-version.ps1 prerelease [tag]
  scripts\bump-version.ps1 set <version>
"@
}

if ($VersionArgs.Count -lt 1 -or $VersionArgs[0] -eq "-h" -or $VersionArgs[0] -eq "--help") {
  Show-Usage
  exit $(if ($VersionArgs.Count -lt 1) { 1 } else { 0 })
}

$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $RootDir

try {
  $NewVersion = & node "scripts/bump-version.mjs" @VersionArgs
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  & cargo check --manifest-path "src-tauri/Cargo.toml"
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  Write-Host "PulseDeck version updated to $NewVersion"
}
finally {
  Pop-Location
}

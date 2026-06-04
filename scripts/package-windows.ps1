param(
  [switch]$NoBump,
  [switch]$Help,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$VersionArgs
)

$ErrorActionPreference = "Stop"

function Show-Usage {
  @"
Usage:
  scripts\package-windows.ps1 [-NoBump]
  scripts\package-windows.ps1 patch
  scripts\package-windows.ps1 minor
  scripts\package-windows.ps1 major
  scripts\package-windows.ps1 prerelease [tag]
  scripts\package-windows.ps1 set <version>

Builds Windows installers for:
  - x64 NSIS setup .exe
  - x64 MSI
  - x86 NSIS setup .exe
  - x86 MSI

Notes:
  - MSI installers require Windows because WiX runs on Windows.
  - NSIS setup .exe installers are Tauri's Windows executable installer format.
  - Visual Studio C++ Build Tools and WiX Toolset v3 must be available for full MSI builds.
"@
}

function Require-Command($Name, $Hint) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Missing required command '$Name'. $Hint"
  }
}

if ($Help) {
  Show-Usage
  exit 0
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
  throw "Windows MSI/EXE packaging must run on Windows. Tauri MSI bundles use WiX, which only runs on Windows."
}

$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $RootDir

try {
  Require-Command "node" "Install Node.js first."
  Require-Command "npm" "Install npm first."
  Require-Command "cargo" "Install Rust first."

  if (-not $NoBump -and $VersionArgs.Count -gt 0) {
    & "$PSScriptRoot\bump-version.ps1" @VersionArgs
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }
  }

  $Version = node -p "require('./package.json').version"
  $Targets = @(
    @{ Label = "x64"; Triple = "x86_64-pc-windows-msvc" },
    @{ Label = "x86"; Triple = "i686-pc-windows-msvc" }
  )
  $Bundles = @("nsis", "msi")

  if (Get-Command "rustup" -ErrorAction SilentlyContinue) {
    foreach ($Target in $Targets) {
      $Triple = $Target.Triple
      & rustup target add $Triple
      if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
      }
    }
  }
  else {
    Write-Warning "rustup was not found. Make sure both Windows Rust targets are already installed."
  }

  Write-Host "Building PulseDeck $Version Windows installers"
  Write-Host "Windows bundle targets: $($Bundles -join ', ')"

  foreach ($Target in $Targets) {
    $Label = $Target.Label
    $Triple = $Target.Triple
    Write-Host ""
    Write-Host "Building $Label installers for $Triple"
    & npm run tauri -- build --ci --target $Triple --bundles @Bundles
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }
  }

  Write-Host ""
  Write-Host "Built Windows packages:"
  Get-ChildItem "src-tauri\target" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
      $_.Extension -eq ".msi" -or
      ($_.Extension -eq ".exe" -and $_.FullName -match "\\bundle\\nsis\\")
    } |
    Sort-Object FullName |
    ForEach-Object { $_.FullName }
}
finally {
  Pop-Location
}

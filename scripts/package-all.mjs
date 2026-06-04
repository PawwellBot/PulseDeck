#!/usr/bin/env node
import { spawnSync } from 'node:child_process'

const args = process.argv.slice(2)

function usage() {
  console.log(`Usage:
  node scripts/package-all.mjs [--no-bump]
  node scripts/package-all.mjs patch
  node scripts/package-all.mjs minor
  node scripts/package-all.mjs major
  node scripts/package-all.mjs prerelease [tag]
  node scripts/package-all.mjs set <version>

Builds every installer supported by the current host:
  - Linux host: AppImage, deb, rpm
  - Windows host: x64/x86 NSIS .exe and MSI

Full Windows MSI builds must run on Windows because Tauri uses WiX for MSI.`)
}

function run(command, commandArgs, options = {}) {
  const result = spawnSync(command, commandArgs, {
    stdio: 'inherit',
    shell: false,
    ...options,
  })

  if (result.error) {
    console.error(result.error.message)
    process.exit(1)
  }

  if (result.status !== 0) {
    process.exit(result.status ?? 1)
  }
}

if (args[0] === '-h' || args[0] === '--help') {
  usage()
  process.exit(0)
}

if (args.length > 0 && args[0] !== '--no-bump') {
  run('node', ['scripts/bump-version.mjs', ...args])
  run('cargo', ['check', '--manifest-path', 'src-tauri/Cargo.toml'])
}

if (process.platform === 'linux') {
  run('bash', ['scripts/package-linux.sh', '--no-bump'])
  console.log(`
Windows installers were not built on this Linux host.
Run scripts\\package-windows.ps1 -NoBump on Windows to build x64/x86 MSI and NSIS .exe installers.`)
} else if (process.platform === 'win32') {
  run('powershell', [
    '-NoProfile',
    '-ExecutionPolicy',
    'Bypass',
    '-File',
    'scripts/package-windows.ps1',
    '-NoBump',
  ])
} else {
  console.error(`Unsupported host for PulseDeck packaging: ${process.platform}`)
  process.exit(1)
}

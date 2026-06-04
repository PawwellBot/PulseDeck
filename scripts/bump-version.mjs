#!/usr/bin/env node
import fs from 'node:fs'

const [mode, extra = ''] = process.argv.slice(2)

if (!mode) {
  console.error('Missing version bump mode.')
  process.exit(1)
}

const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'))
const current = pkg.version
const match = current.match(/^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?$/)

if (!match) {
  console.error(`Current package.json version is not semver-compatible: ${current}`)
  process.exit(1)
}

let major = Number(match[1])
let minor = Number(match[2])
let patch = Number(match[3])
let prerelease = match[4] || ''

function exactVersion(value) {
  if (!/^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/.test(value)) {
    console.error(`Invalid version: ${value}`)
    process.exit(1)
  }

  return value
}

function bumpPrerelease(tag) {
  const cleanTag = tag || 'alpha'

  if (!/^[0-9A-Za-z-]+$/.test(cleanTag)) {
    console.error(`Invalid prerelease tag: ${cleanTag}`)
    process.exit(1)
  }

  const currentPrerelease = prerelease.match(/^([0-9A-Za-z-]+)\.(\d+)$/)
  if (currentPrerelease && currentPrerelease[1] === cleanTag) {
    return `${major}.${minor}.${patch}-${cleanTag}.${Number(currentPrerelease[2]) + 1}`
  }

  return `${major}.${minor}.${patch}-${cleanTag}.0`
}

let next

switch (mode) {
  case 'major':
    next = `${major + 1}.0.0`
    break
  case 'minor':
    next = `${major}.${minor + 1}.0`
    break
  case 'patch':
    next = `${major}.${minor}.${patch + 1}`
    break
  case 'prerelease':
    next = bumpPrerelease(extra)
    break
  case 'set':
    if (!extra) {
      console.error('Missing version for set mode.')
      process.exit(1)
    }
    next = exactVersion(extra)
    break
  default:
    console.error(`Unknown version bump mode: ${mode}`)
    process.exit(1)
}

pkg.version = next
fs.writeFileSync('package.json', `${JSON.stringify(pkg, null, 2)}\n`)

if (fs.existsSync('package-lock.json')) {
  const lock = JSON.parse(fs.readFileSync('package-lock.json', 'utf8'))
  lock.version = next
  if (lock.packages && lock.packages['']) {
    lock.packages[''].version = next
  }
  fs.writeFileSync('package-lock.json', `${JSON.stringify(lock, null, 2)}\n`)
}

const tauriPath = 'src-tauri/tauri.conf.json'
const tauri = JSON.parse(fs.readFileSync(tauriPath, 'utf8'))
tauri.version = next
fs.writeFileSync(tauriPath, `${JSON.stringify(tauri, null, 2)}\n`)

const cargoPath = 'src-tauri/Cargo.toml'
let cargo = fs.readFileSync(cargoPath, 'utf8')
cargo = cargo.replace(/^version = ".*"$/m, `version = "${next}"`)
fs.writeFileSync(cargoPath, cargo)

console.log(next)

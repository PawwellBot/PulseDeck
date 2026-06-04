export type AssistTone = 'good' | 'ready' | 'warn' | 'blocked' | 'unknown'

export interface DisplayMode {
  label: string
  width: number
  height: number
  refreshRate: number
  preferred: boolean
}

export interface AssistResult {
  tone: AssistTone
  title: string
  detail: string
}

export interface Monitor {
  id: number
  name: string
  description: string
  connectorType: string
  width: number
  height: number
  refreshRate: number
  x: number
  y: number
  scale: number
  enabled: boolean
  primary: boolean
  modes: DisplayMode[]
  assist: AssistResult
}

export interface BackupEntry {
  path: string
  createdAt: string
  bytes: number
}

export interface DisplaySnapshot {
  source: string
  hyprlandAvailable: boolean
  generatedAt: string
  configPath: string
  configPreview: string[]
  monitors: Monitor[]
  backups: BackupEntry[]
  configErrors: string
}

export interface ApplyResult {
  configPath: string
  backupPath: string | null
  reloadOutput: string
  configErrors: string
  appliedAt: string
}

export interface DisplayProfile {
  id: string
  name: string
  description: string
  icon: string
  favoriteRefresh: number
  monitorCount: number
  autoApply: boolean
}

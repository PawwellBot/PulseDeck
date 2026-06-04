export interface SetupCheck {
  label: string
  detail: string
  passed: boolean
  required: boolean
}

export interface SetupStatus {
  firstRun: boolean
  setupCompleted: boolean
  setupPath: string
  configPath: string
  hyprctlAvailable: boolean
  pkexecAvailable: boolean
  hyprlandSession: boolean
  adminPermissionRequested: boolean
  adminPermissionGranted: boolean
  adminPermissionCheckedAt: string | null
  adminPermissionMessage: string | null
  checkedAt: string
  checks: SetupCheck[]
}

export interface AdminPermissionResult {
  granted: boolean
  message: string
  checkedAt: string
  setupStatus: SetupStatus
}

import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { useLocalStorage } from '@vueuse/core'

import { command, isTauriRuntime } from '../lib/tauri'
import type { AdminPermissionResult, SetupStatus } from '../types/setup'

const demoSetupStatus = (
  setupCompleted: boolean,
  adminRequested = false,
  adminGranted = false,
): SetupStatus => ({
  firstRun: !setupCompleted,
  setupCompleted,
  setupPath: '~/.config/pulsedeck/setup.json',
  configPath: '~/.config/hypr/monitors.conf',
  hyprctlAvailable: false,
  pkexecAvailable: false,
  hyprlandSession: false,
  adminPermissionRequested: adminRequested,
  adminPermissionGranted: adminGranted,
  adminPermissionCheckedAt: adminRequested ? new Date().toISOString() : null,
  adminPermissionMessage: adminGranted
    ? 'Administrator permission was already granted once. PulseDeck will not ask again.'
    : adminRequested
      ? 'Browser preview cannot open a system administrator prompt. Run the Tauri app to use pkexec.'
      : null,
  checkedAt: new Date().toISOString(),
  checks: [
    {
      label: 'Hyprland session',
      detail: 'Browser preview is not connected to a Hyprland session.',
      passed: false,
      required: true,
    },
    {
      label: 'hyprctl',
      detail: 'hyprctl checks run inside the Tauri desktop app.',
      passed: false,
      required: true,
    },
    {
      label: 'Administrator prompt',
      detail: 'pkexec prompts are available only from the desktop app.',
      passed: false,
      required: false,
    },
    {
      label: 'Monitor config path',
      detail: '~/.config/hypr/monitors.conf',
      passed: true,
      required: true,
    },
  ],
})

export const useSetupStore = defineStore('setup', () => {
  const browserSetupComplete = useLocalStorage('pulsedeck:browser-setup-complete', false)
  const status = ref<SetupStatus | null>(null)
  const loading = ref(false)
  const requestingAdmin = ref(false)
  const completing = ref(false)
  const error = ref<string | null>(null)

  const shouldShowSetup = computed(() => !status.value?.setupCompleted)
  const adminStepSatisfied = computed(
    () => Boolean(status.value?.adminPermissionGranted) || !status.value?.pkexecAvailable,
  )

  async function load() {
    loading.value = true
    error.value = null

    try {
      status.value = await command<SetupStatus>('get_setup_status')
    } catch (caught) {
      status.value = demoSetupStatus(browserSetupComplete.value)
      error.value = caught instanceof Error ? caught.message : 'Using browser setup preview.'
    } finally {
      loading.value = false
    }
  }

  async function requestAdminPermission() {
    if (status.value?.adminPermissionGranted) return

    requestingAdmin.value = true
    error.value = null

    try {
      const result = await command<AdminPermissionResult>('request_admin_permissions')
      status.value = result.setupStatus
    } catch (caught) {
      if (!isTauriRuntime()) {
        status.value = demoSetupStatus(browserSetupComplete.value, true)
      }
      error.value = caught instanceof Error ? caught.message : 'Unable to request administrator permission.'
    } finally {
      requestingAdmin.value = false
    }
  }

  async function completeSetup() {
    completing.value = true
    error.value = null

    try {
      status.value = await command<SetupStatus>('complete_setup')
    } catch (caught) {
      if (!isTauriRuntime()) {
        browserSetupComplete.value = true
        status.value = demoSetupStatus(true, true)
      } else {
        error.value = caught instanceof Error ? caught.message : 'Unable to finish setup.'
      }
    } finally {
      completing.value = false
    }
  }

  return {
    adminStepSatisfied,
    completeSetup,
    completing,
    error,
    load,
    loading,
    requestAdminPermission,
    requestingAdmin,
    shouldShowSetup,
    status,
  }
})

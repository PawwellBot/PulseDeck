import dayjs from 'dayjs'
import Fuse from 'fuse.js'
import { defineStore } from 'pinia'
import { computed, ref, watch } from 'vue'
import { useDocumentVisibility, useIntervalFn, useLocalStorage, useNow } from '@vueuse/core'

import { command, isTauriRuntime } from '../lib/tauri'
import type { ApplyResult, DisplayProfile, DisplaySnapshot, Monitor } from '../types/display'

const demoGeneratedAt = () => new Date().toISOString()

const demoSnapshot = (): DisplaySnapshot => ({
  source: 'Browser preview',
  hyprlandAvailable: false,
  generatedAt: demoGeneratedAt(),
  configPath: '~/.config/hypr/monitors.conf',
  configPreview: [
    'monitor = DP-1, 2560x1440@165, 0x0, 1',
    'monitor = HDMI-A-1, 1920x1080@120, 2560x180, 1',
  ],
  configErrors: 'Hyprland commands are available only inside the Tauri desktop app.',
  backups: [],
  monitors: [
    {
      id: 1,
      name: 'DP-1',
      description: 'Desk display - 27 inch QHD',
      connectorType: 'DisplayPort',
      width: 2560,
      height: 1440,
      refreshRate: 165,
      x: 0,
      y: 0,
      scale: 1,
      enabled: true,
      primary: true,
      modes: [
        { label: '2560x1440 @ 165Hz', width: 2560, height: 1440, refreshRate: 165, preferred: true },
        { label: '2560x1440 @ 144Hz', width: 2560, height: 1440, refreshRate: 144, preferred: false },
        { label: '1920x1080 @ 120Hz', width: 1920, height: 1080, refreshRate: 120, preferred: false },
      ],
      assist: {
        tone: 'good',
        title: 'High refresh applied',
        detail: 'This display is already above the 120Hz target.',
      },
    },
    {
      id: 2,
      name: 'HDMI-A-1',
      description: 'Side display - 24 inch FHD',
      connectorType: 'HDMI',
      width: 1920,
      height: 1080,
      refreshRate: 60,
      x: 2560,
      y: 180,
      scale: 1,
      enabled: true,
      primary: false,
      modes: [
        { label: '1920x1080 @ 120Hz', width: 1920, height: 1080, refreshRate: 120, preferred: true },
        { label: '1920x1080 @ 60Hz', width: 1920, height: 1080, refreshRate: 60, preferred: false },
      ],
      assist: {
        tone: 'ready',
        title: '120Hz available',
        detail: 'PulseDeck can write a Hyprland mode using the advertised 120Hz option.',
      },
    },
  ],
})

const starterProfiles: DisplayProfile[] = [
  {
    id: 'desk',
    name: 'Desk',
    description: 'Main multi-monitor layout for focused work.',
    icon: 'PanelTop',
    favoriteRefresh: 120,
    monitorCount: 2,
    autoApply: true,
  },
  {
    id: 'gaming',
    name: 'Gaming',
    description: 'Prefer the fastest valid mode on the primary display.',
    icon: 'Gauge',
    favoriteRefresh: 165,
    monitorCount: 1,
    autoApply: false,
  },
  {
    id: 'travel',
    name: 'Travel',
    description: 'Laptop-only setup for docks, projectors, and hotel desks.',
    icon: 'Briefcase',
    favoriteRefresh: 60,
    monitorCount: 1,
    autoApply: false,
  },
]

export const useDisplayStore = defineStore('display', () => {
  const snapshot = ref<DisplaySnapshot | null>(null)
  const applyResult = ref<ApplyResult | null>(null)
  const loading = ref(false)
  const backgroundScanning = ref(false)
  const applying = ref(false)
  const error = ref<string | null>(null)
  const monitorChangeMessage = ref<string | null>(null)
  const selectedMonitorName = useLocalStorage('pulsedeck:selected-monitor', '')
  const autoScanEnabled = useLocalStorage('pulsedeck:auto-scan-enabled', true)
  const profileFilter = ref('')
  const profiles = ref<DisplayProfile[]>(starterProfiles)
  const now = useNow({ interval: 1_000 })
  const documentVisibility = useDocumentVisibility()
  const monitorSignature = ref('')

  const monitors = computed(() => snapshot.value?.monitors ?? [])
  const backups = computed(() => snapshot.value?.backups ?? [])
  const previewLines = computed(() => snapshot.value?.configPreview ?? [])
  const selectedMonitor = computed<Monitor | null>(() => {
    const chosen = monitors.value.find((monitor) => monitor.name === selectedMonitorName.value)
    return chosen ?? monitors.value[0] ?? null
  })

  const lastScanLabel = computed(() => {
    if (!snapshot.value) return 'Not scanned'
    const timestamp = dayjs(snapshot.value.generatedAt)
    return timestamp.isSame(dayjs(now.value), 'day') ? timestamp.format('HH:mm:ss') : timestamp.format('MMM D HH:mm')
  })

  const fastestMonitor = computed(() =>
    monitors.value.reduce<Monitor | null>((winner, monitor) => {
      if (!winner) return monitor
      return monitor.refreshRate > winner.refreshRate ? monitor : winner
    }, null),
  )

  const assistCounts = computed(() => ({
    ready: monitors.value.filter((monitor) => monitor.assist.tone === 'ready').length,
    good: monitors.value.filter((monitor) => monitor.assist.tone === 'good').length,
    warn: monitors.value.filter((monitor) => monitor.assist.tone === 'warn').length,
    blocked: monitors.value.filter((monitor) => monitor.assist.tone === 'blocked').length,
  }))

  const filteredProfiles = computed(() => {
    const filter = profileFilter.value.trim()
    if (!filter) return profiles.value

    const fuse = new Fuse(profiles.value, {
      threshold: 0.32,
      keys: ['name', 'description'],
    })

    return fuse.search(filter).map((result) => result.item)
  })

  const monitorWatcher = useIntervalFn(
    () => {
      if (!autoScanEnabled.value || applying.value || loading.value || backgroundScanning.value) return
      if (documentVisibility.value !== 'visible') return

      void refresh({ background: true })
    },
    3_000,
    { immediate: false },
  )

  watch(documentVisibility, (visibility) => {
    if (visibility === 'visible' && autoScanEnabled.value && isTauriRuntime()) {
      void refresh({ background: true })
    }
  })

  async function refresh(options: { background?: boolean } = {}) {
    if (options.background) {
      backgroundScanning.value = true
    } else {
      loading.value = true
      error.value = null
    }

    try {
      const nextSnapshot = await command<DisplaySnapshot>('get_display_snapshot')
      acceptSnapshot(nextSnapshot)
    } catch (caught) {
      if (!options.background) {
        acceptSnapshot(demoSnapshot())
        error.value = caught instanceof Error ? caught.message : 'Using browser preview data.'
      }
    } finally {
      if (!selectedMonitorName.value && monitors.value.length > 0) {
        selectedMonitorName.value = monitors.value[0].name
      }
      if (options.background) {
        backgroundScanning.value = false
      } else {
        loading.value = false
      }
    }
  }

  function acceptSnapshot(nextSnapshot: DisplaySnapshot) {
    const previousNames = new Set(snapshot.value?.monitors.map((monitor) => monitor.name) ?? [])
    const nextNames = new Set(nextSnapshot.monitors.map((monitor) => monitor.name))
    const previousSignature = monitorSignature.value
    const nextSignature = signatureFor(nextSnapshot.monitors)

    snapshot.value = nextSnapshot
    monitorSignature.value = nextSignature

    if (previousSignature && previousSignature !== nextSignature) {
      const added = [...nextNames].filter((name) => !previousNames.has(name))
      const removed = [...previousNames].filter((name) => !nextNames.has(name))
      const changes = [
        added.length ? `Added ${added.join(', ')}` : '',
        removed.length ? `Removed ${removed.join(', ')}` : '',
      ].filter(Boolean)

      monitorChangeMessage.value = changes.length ? changes.join(' / ') : 'Monitor details updated.'
    }

    if (selectedMonitorName.value && !nextNames.has(selectedMonitorName.value)) {
      selectedMonitorName.value = nextSnapshot.monitors[0]?.name ?? ''
    }
  }

  function signatureFor(items: Monitor[]) {
    return [...items]
      .sort((left, right) => left.name.localeCompare(right.name))
      .map((monitor) =>
        [
          monitor.name,
          monitor.enabled ? 'on' : 'off',
          monitor.width,
          monitor.height,
          monitor.refreshRate.toFixed(2),
          monitor.x,
          monitor.y,
          monitor.scale,
        ].join(':'),
      )
      .join('|')
  }

  async function startMonitorWatcher() {
    if (!isTauriRuntime()) return

    if (!snapshot.value) {
      await refresh()
    }

    if (autoScanEnabled.value && !monitorWatcher.isActive.value) {
      monitorWatcher.resume()
    }
  }

  function stopMonitorWatcher() {
    monitorWatcher.pause()
  }

  function setAutoScanEnabled(enabled: boolean) {
    autoScanEnabled.value = enabled

    if (enabled) {
      void startMonitorWatcher()
    } else {
      stopMonitorWatcher()
    }
  }

  function selectMonitor(name: string) {
    selectedMonitorName.value = name
  }

  function toggleProfileAutoApply(profileId: string) {
    const profile = profiles.value.find((item) => item.id === profileId)
    if (profile) {
      profile.autoApply = !profile.autoApply
    }
  }

  async function applyPreview() {
    applying.value = true
    error.value = null

    try {
      applyResult.value = await command<ApplyResult>('write_monitor_config', {
        lines: previewLines.value,
      })
      await refresh()
    } catch (caught) {
      error.value = caught instanceof Error ? caught.message : 'Unable to apply monitor config.'
    } finally {
      applying.value = false
    }
  }

  return {
    applyPreview,
    applyResult,
    applying,
    assistCounts,
    autoScanEnabled,
    backgroundScanning,
    backups,
    error,
    fastestMonitor,
    filteredProfiles,
    lastScanLabel,
    loading,
    monitors,
    monitorChangeMessage,
    previewLines,
    profileFilter,
    profiles,
    refresh,
    selectMonitor,
    selectedMonitor,
    selectedMonitorName,
    setAutoScanEnabled,
    snapshot,
    startMonitorWatcher,
    stopMonitorWatcher,
    toggleProfileAutoApply,
  }
})

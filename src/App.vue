<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import {
  Activity,
  Archive,
  Bug,
  Check,
  Gauge,
  LayoutDashboard,
  ListRestart,
  MonitorUp,
  Play,
  Radar,
  RefreshCw,
  Settings2,
} from '@lucide/vue'

import AssistPanel from './components/AssistPanel.vue'
import BackupPanel from './components/BackupPanel.vue'
import DiagnosticsPanel from './components/DiagnosticsPanel.vue'
import MonitorCanvas from './components/MonitorCanvas.vue'
import MonitorInspector from './components/MonitorInspector.vue'
import ProfilesPanel from './components/ProfilesPanel.vue'
import SetupScreen from './components/SetupScreen.vue'
import { useDisplayStore } from './stores/display'
import { useSetupStore } from './stores/setup'

type ViewName = 'dashboard' | 'profiles' | 'diagnostics' | 'backups'

const store = useDisplayStore()
const setup = useSetupStore()
const activeView = ref<ViewName>('dashboard')

const navItems = [
  { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { id: 'profiles', label: 'Profiles', icon: ListRestart },
  { id: 'diagnostics', label: 'Diagnostics', icon: Bug },
  { id: 'backups', label: 'Backups', icon: Archive },
] satisfies Array<{ id: ViewName; label: string; icon: typeof LayoutDashboard }>

const highRefreshCount = computed(
  () => store.monitors.filter((monitor) => monitor.refreshRate >= 119.5).length,
)
const activeNavItem = computed(() => navItems.find((item) => item.id === activeView.value) ?? navItems[0])

onMounted(() => {
  void initialize()
})

async function initialize() {
  await setup.load()

  if (!setup.shouldShowSetup) {
    await store.refresh()
    await store.startMonitorWatcher()
  }
}

async function completeSetup() {
  await setup.completeSetup()

  if (!setup.shouldShowSetup) {
    await store.refresh()
    await store.startMonitorWatcher()
  }
}
</script>

<template>
  <SetupScreen
    v-if="setup.shouldShowSetup"
    :status="setup.status"
    :loading="setup.loading"
    :requesting-admin="setup.requestingAdmin"
    :completing="setup.completing"
    :error="setup.error"
    @refresh="setup.load"
    @request-admin="setup.requestAdminPermission"
    @complete="completeSetup"
  />

  <div v-else class="min-h-screen bg-graphite-950 text-zinc-100">
    <div class="flex min-h-screen">
      <aside class="hidden w-64 shrink-0 border-r border-white/10 bg-graphite-900 lg:flex lg:flex-col">
        <div class="flex h-20 items-center gap-3 border-b border-white/10 px-5">
          <div class="grid size-10 place-items-center rounded-lg border border-white/20 bg-white/10">
            <Activity class="size-5 text-white" />
          </div>
          <div>
            <p class="text-lg font-bold text-white">PulseDeck</p>
            <p class="text-xs text-zinc-500">Dial in every display.</p>
          </div>
        </div>

        <nav class="space-y-1 p-3" aria-label="Main">
          <button
            v-for="item in navItems"
            :key="item.id"
            type="button"
            :class="[
              'flex h-11 w-full items-center gap-3 rounded-lg px-3 text-sm font-semibold transition',
              activeView === item.id
                ? 'bg-white text-black'
                : 'text-zinc-400 hover:bg-white/[0.05] hover:text-white',
            ]"
            @click="activeView = item.id"
          >
            <component :is="item.icon" class="size-4" />
            {{ item.label }}
          </button>
        </nav>

        <div class="mt-auto border-t border-white/10 px-5 py-4">
          <p class="text-xs font-semibold uppercase tracking-wide text-zinc-500">Fastest display</p>
          <div class="mt-2 flex items-end justify-between gap-3">
            <p class="text-2xl font-bold text-white">
              {{ store.fastestMonitor ? `${Math.round(store.fastestMonitor.refreshRate)}Hz` : '--' }}
            </p>
            <p class="max-w-28 truncate text-sm text-zinc-400">{{ store.fastestMonitor?.name ?? 'No scan' }}</p>
          </div>
        </div>
      </aside>

      <main class="min-w-0 flex-1">
        <header class="sticky top-0 z-30 border-b border-white/10 bg-graphite-950/92 backdrop-blur">
          <div class="flex min-h-20 flex-col gap-4 px-4 py-4 md:flex-row md:items-center md:justify-between lg:px-7">
            <div>
              <p class="text-xs font-semibold uppercase tracking-wide text-zinc-500">PulseDeck</p>
              <h1 class="mt-1 text-2xl font-bold text-white">{{ activeNavItem.label }}</h1>
            </div>

            <div class="flex flex-wrap items-center gap-2">
              <button
                type="button"
                :class="[
                  'inline-flex h-10 items-center gap-2 rounded-lg border px-3 text-sm font-semibold transition',
                  store.autoScanEnabled
                    ? 'border-white/30 bg-white/10 text-white hover:bg-white/15'
                    : 'border-white/10 bg-white/[0.03] text-zinc-400 hover:border-white/20 hover:bg-white/[0.06]',
                ]"
                @click="store.setAutoScanEnabled(!store.autoScanEnabled)"
              >
                <Radar :class="['size-4', store.backgroundScanning ? 'animate-pulse' : '']" />
                Auto Scan
              </button>
              <button
                type="button"
                class="inline-flex h-10 items-center gap-2 rounded-lg border border-white/10 bg-white/[0.03] px-3 text-sm font-semibold text-zinc-200 transition hover:border-white/20 hover:bg-white/[0.06]"
                :disabled="store.loading"
                @click="store.refresh()"
              >
                <RefreshCw :class="['size-4', store.loading ? 'animate-spin' : '']" />
                Refresh
              </button>
              <button
                type="button"
                class="inline-flex h-10 items-center gap-2 rounded-lg bg-white px-3 text-sm font-bold text-black transition hover:bg-zinc-200 disabled:cursor-not-allowed disabled:opacity-60"
                :disabled="store.applying || store.previewLines.length === 0"
                @click="store.applyPreview"
              >
                <Play class="size-4 fill-current" />
                Apply
              </button>
            </div>
          </div>
        </header>

        <div class="space-y-5 p-4 lg:p-6">
          <nav class="grid grid-cols-4 gap-2 lg:hidden" aria-label="Main">
            <button
              v-for="item in navItems"
              :key="item.id"
              type="button"
              :class="[
                'flex h-11 items-center justify-center rounded-lg border text-sm font-semibold transition',
                activeView === item.id
                  ? 'border-white/30 bg-white/10 text-white'
                  : 'border-white/10 bg-graphite-900 text-zinc-400 hover:text-white',
              ]"
              @click="activeView = item.id"
            >
              <component :is="item.icon" class="size-4" />
              <span class="sr-only">{{ item.label }}</span>
            </button>
          </nav>

          <div
            v-if="store.error"
            class="flex items-start gap-3 rounded-lg border border-white/20 bg-white/[0.06] px-4 py-3 text-sm text-zinc-100"
          >
            <Settings2 class="mt-0.5 size-4 shrink-0" />
            <span>{{ store.error }}</span>
          </div>

          <div
            v-if="store.monitorChangeMessage"
            class="flex items-start gap-3 rounded-lg border border-white/20 bg-white/[0.06] px-4 py-3 text-sm text-zinc-100"
          >
            <Radar class="mt-0.5 size-4 shrink-0" />
            <span>{{ store.monitorChangeMessage }}</span>
          </div>

          <section class="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            <div class="rounded-lg border border-white/10 bg-graphite-900 px-4 py-3">
              <div class="flex items-center justify-between text-xs font-semibold uppercase tracking-wide text-zinc-500">
                <span>Displays</span>
                <MonitorUp class="size-4 text-zinc-300" />
              </div>
              <p class="mt-3 text-2xl font-bold text-white">{{ store.monitors.length }}</p>
            </div>
            <div class="rounded-lg border border-white/10 bg-graphite-900 px-4 py-3">
              <div class="flex items-center justify-between text-xs font-semibold uppercase tracking-wide text-zinc-500">
                <span>120Hz+</span>
                <Check class="size-4 text-white" />
              </div>
              <p class="mt-3 text-2xl font-bold text-white">{{ highRefreshCount }}</p>
            </div>
            <div class="rounded-lg border border-white/10 bg-graphite-900 px-4 py-3">
              <div class="flex items-center justify-between text-xs font-semibold uppercase tracking-wide text-zinc-500">
                <span>Ready</span>
                <Gauge class="size-4 text-zinc-300" />
              </div>
              <p class="mt-3 text-2xl font-bold text-white">{{ store.assistCounts.ready }}</p>
            </div>
            <div class="rounded-lg border border-white/10 bg-graphite-900 px-4 py-3">
              <div class="flex items-center justify-between text-xs font-semibold uppercase tracking-wide text-zinc-500">
                <span>Scan</span>
                <RefreshCw class="size-4 text-zinc-500" />
              </div>
              <p class="mt-3 text-2xl font-bold text-white">{{ store.lastScanLabel }}</p>
            </div>
          </section>

          <template v-if="activeView === 'dashboard'">
            <section class="grid gap-5 xl:grid-cols-[minmax(0,1fr)_380px]">
              <MonitorCanvas
                :monitors="store.monitors"
                :selected-name="store.selectedMonitorName"
                @select="store.selectMonitor"
              />
              <MonitorInspector :monitor="store.selectedMonitor" />
            </section>
            <AssistPanel :monitors="store.monitors" />
          </template>

          <ProfilesPanel
            v-else-if="activeView === 'profiles'"
            v-model:filter="store.profileFilter"
            :profiles="store.filteredProfiles"
            @toggle-auto-apply="store.toggleProfileAutoApply"
          />

          <DiagnosticsPanel
            v-else-if="activeView === 'diagnostics'"
            :snapshot="store.snapshot"
            :preview-lines="store.previewLines"
          />

          <BackupPanel v-else :backups="store.backups" />
        </div>
      </main>
    </div>
  </div>
</template>

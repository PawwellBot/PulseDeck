<script setup lang="ts">
import { ChevronDown, MonitorCheck, ScanLine } from '@lucide/vue'

import type { Monitor } from '../types/display'
import StatusPill from './StatusPill.vue'

defineProps<{
  monitor: Monitor | null
}>()
</script>

<template>
  <aside class="rounded-lg border border-white/10 bg-graphite-900 shadow-panel">
    <div class="border-b border-white/10 px-5 py-3">
      <h2 class="text-base font-semibold text-white">Details</h2>
    </div>

    <div v-if="monitor" class="space-y-4 p-5">
      <div class="flex items-start justify-between gap-3">
        <div class="min-w-0">
          <p class="truncate text-lg font-semibold text-white">{{ monitor.name }}</p>
          <p class="truncate text-sm text-zinc-400">{{ monitor.description }}</p>
        </div>
        <StatusPill :tone="monitor.assist.tone" :label="monitor.assist.title" />
      </div>

      <dl class="divide-y divide-white/10 rounded-lg border border-white/10 bg-white/[0.03] text-sm">
        <div class="flex items-center justify-between gap-4 px-3 py-2.5">
          <dt class="text-zinc-500">Resolution</dt>
          <dd class="font-semibold text-zinc-100">{{ monitor.width }}x{{ monitor.height }}</dd>
        </div>
        <div class="flex items-center justify-between gap-4 px-3 py-2.5">
          <dt class="text-zinc-500">Refresh</dt>
          <dd class="font-semibold text-zinc-100">{{ monitor.refreshRate.toFixed(2) }}Hz</dd>
        </div>
        <div class="flex items-center justify-between gap-4 px-3 py-2.5">
          <dt class="text-zinc-500">Position</dt>
          <dd class="font-semibold text-zinc-100">{{ monitor.x }}x{{ monitor.y }}</dd>
        </div>
        <div class="flex items-center justify-between gap-4 px-3 py-2.5">
          <dt class="text-zinc-500">Scale</dt>
          <dd class="font-semibold text-zinc-100">{{ monitor.scale }}x</dd>
        </div>
      </dl>

      <div>
        <div class="mb-2 flex items-center gap-2 text-sm font-semibold text-white">
          <ScanLine class="size-4 text-white" />
          Modes
        </div>
        <div class="max-h-56 space-y-2 overflow-auto pr-1">
          <button
            v-for="mode in monitor.modes"
            :key="`${mode.width}-${mode.height}-${mode.refreshRate}`"
            type="button"
            class="flex w-full items-center justify-between rounded-lg border border-white/10 bg-white/[0.03] px-3 py-2 text-left text-sm text-zinc-200 transition hover:border-white/20 hover:bg-white/[0.06]"
          >
            <span>{{ mode.label }}</span>
            <span
              v-if="mode.preferred"
              class="rounded-md border border-white/30 bg-white/10 px-2 py-1 text-xs font-semibold text-white"
            >
              target
            </span>
            <ChevronDown v-else class="size-4 text-zinc-600" />
          </button>
        </div>
      </div>

      <div class="rounded-lg border border-white/10 bg-white/[0.03] p-4">
        <div class="flex items-center gap-2 text-sm font-semibold text-white">
          <MonitorCheck class="size-4 text-white" />
          120Hz Assist
        </div>
        <p class="mt-2 text-sm leading-6 text-zinc-300">{{ monitor.assist.detail }}</p>
      </div>
    </div>

    <div v-else class="p-5 text-sm text-zinc-400">No monitor selected.</div>
  </aside>
</template>

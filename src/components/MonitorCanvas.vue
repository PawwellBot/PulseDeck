<script setup lang="ts">
import { computed } from 'vue'
import { Monitor } from '@lucide/vue'

import type { Monitor as PulseMonitor } from '../types/display'
import StatusPill from './StatusPill.vue'

const props = defineProps<{
  monitors: PulseMonitor[]
  selectedName: string
}>()

const emit = defineEmits<{
  select: [name: string]
}>()

const bounds = computed(() => {
  if (props.monitors.length === 0) {
    return { minX: 0, minY: 0, width: 1, height: 1 }
  }

  const minX = Math.min(...props.monitors.map((monitor) => monitor.x))
  const minY = Math.min(...props.monitors.map((monitor) => monitor.y))
  const maxX = Math.max(...props.monitors.map((monitor) => monitor.x + monitor.width))
  const maxY = Math.max(...props.monitors.map((monitor) => monitor.y + monitor.height))

  return {
    minX,
    minY,
    width: Math.max(maxX - minX, 1),
    height: Math.max(maxY - minY, 1),
  }
})

function styleFor(monitor: PulseMonitor) {
  const box = bounds.value
  const left = ((monitor.x - box.minX) / box.width) * 100
  const top = ((monitor.y - box.minY) / box.height) * 100
  const width = (monitor.width / box.width) * 100
  const height = (monitor.height / box.height) * 100

  return {
    left: `${left}%`,
    top: `${top}%`,
    width: `${Math.max(width, 24)}%`,
    height: `${Math.max(height, 34)}%`,
  }
}
</script>

<template>
  <section class="flex min-h-[360px] flex-col rounded-lg border border-white/10 bg-graphite-900 shadow-panel">
    <div class="flex items-center justify-between border-b border-white/10 px-5 py-3">
      <h2 class="text-base font-semibold text-white">Layout</h2>
      <span class="text-sm text-zinc-500">{{ monitors.length }} display{{ monitors.length === 1 ? '' : 's' }}</span>
    </div>

    <div class="relative flex-1 overflow-hidden p-6">
      <div class="absolute inset-6 rounded-lg bg-[linear-gradient(rgba(255,255,255,0.04)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.04)_1px,transparent_1px)] bg-[size:32px_32px]" />
      <div v-if="monitors.length === 0" class="relative z-10 grid h-full min-h-64 place-items-center text-sm text-zinc-400">
        No displays found.
      </div>
      <button
        v-for="monitor in monitors"
        :key="monitor.name"
        type="button"
        :style="styleFor(monitor)"
        :class="[
          'absolute z-10 flex min-h-28 min-w-44 flex-col justify-between rounded-lg border p-4 text-left transition',
          monitor.name === selectedName
            ? 'border-white/80 bg-graphite-800 shadow-glow'
            : 'border-white/10 bg-graphite-850 hover:border-white/25 hover:bg-graphite-800',
        ]"
        @click="emit('select', monitor.name)"
      >
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <div class="flex items-center gap-2 text-sm font-semibold text-white">
              <Monitor class="size-4 shrink-0 text-white" />
              <span class="truncate">{{ monitor.name }}</span>
            </div>
            <p class="mt-1 truncate text-xs text-zinc-400">{{ monitor.connectorType }}</p>
          </div>
          <StatusPill :tone="monitor.assist.tone" :label="`${Math.round(monitor.refreshRate)}Hz`" />
        </div>
        <div class="flex items-end justify-between gap-3 text-xs text-zinc-300">
          <span>{{ monitor.width }}x{{ monitor.height }}</span>
          <span>{{ monitor.scale }}x scale</span>
        </div>
      </button>
    </div>
  </section>
</template>

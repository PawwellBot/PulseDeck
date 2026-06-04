<script setup lang="ts">
import { CircleCheck, CircleHelp, CircleX, TriangleAlert } from '@lucide/vue'

import type { Monitor } from '../types/display'
import StatusPill from './StatusPill.vue'

defineProps<{
  monitors: Monitor[]
}>()

const iconFor = {
  good: CircleCheck,
  ready: CircleCheck,
  warn: TriangleAlert,
  blocked: CircleX,
  unknown: CircleHelp,
}
</script>

<template>
  <section class="rounded-lg border border-white/10 bg-graphite-900 shadow-panel">
    <div class="border-b border-white/10 px-5 py-3">
      <h2 class="text-base font-semibold text-white">120Hz Assist</h2>
    </div>

    <div class="divide-y divide-white/10">
      <div v-for="monitor in monitors" :key="monitor.name" class="flex gap-4 px-5 py-3.5">
        <component :is="iconFor[monitor.assist.tone]" class="mt-0.5 size-5 shrink-0 text-white" />
        <div class="min-w-0 flex-1">
          <div class="flex flex-wrap items-center gap-2">
            <h3 class="font-semibold text-white">{{ monitor.name }}</h3>
            <StatusPill :tone="monitor.assist.tone" :label="monitor.assist.title" />
          </div>
          <p class="mt-1 text-sm leading-6 text-zinc-400">{{ monitor.assist.detail }}</p>
        </div>
      </div>
    </div>
  </section>
</template>

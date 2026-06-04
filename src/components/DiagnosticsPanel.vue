<script setup lang="ts">
import { FileCode2, ServerCog, TerminalSquare } from '@lucide/vue'

import type { DisplaySnapshot } from '../types/display'

defineProps<{
  snapshot: DisplaySnapshot | null
  previewLines: string[]
}>()
</script>

<template>
  <section class="grid gap-5 lg:grid-cols-[1fr_0.9fr]">
    <div class="rounded-lg border border-white/10 bg-graphite-900 shadow-panel">
      <div class="flex items-center gap-2 border-b border-white/10 px-5 py-4">
        <FileCode2 class="size-5 text-white" />
        <h2 class="text-base font-semibold text-white">Generated Config</h2>
      </div>
      <p class="border-b border-white/10 px-5 py-2 text-sm text-zinc-500">
        {{ snapshot?.configPath ?? '~/.config/hypr/monitors.conf' }}
      </p>
      <pre class="overflow-auto p-5 text-sm leading-7 text-zinc-200"><code>{{ previewLines.join('\n') }}</code></pre>
    </div>

    <div class="space-y-5">
      <div class="rounded-lg border border-white/10 bg-graphite-900 shadow-panel">
        <div class="flex items-center gap-2 border-b border-white/10 px-5 py-3">
          <ServerCog class="size-5 text-zinc-300" />
          <h2 class="text-base font-semibold text-white">Runtime</h2>
        </div>
        <dl class="grid grid-cols-2 gap-4 p-5 text-sm">
          <div>
            <dt class="text-zinc-500">Source</dt>
            <dd class="mt-1 font-semibold text-white">{{ snapshot?.source ?? 'Not scanned' }}</dd>
          </div>
          <div>
            <dt class="text-zinc-500">Hyprland</dt>
            <dd class="mt-1 font-semibold text-white">{{ snapshot?.hyprlandAvailable ? 'Available' : 'Unavailable' }}</dd>
          </div>
        </dl>
      </div>

      <div class="rounded-lg border border-white/10 bg-graphite-900 shadow-panel">
        <div class="flex items-center gap-2 border-b border-white/10 px-5 py-3">
          <TerminalSquare class="size-5 text-zinc-300" />
          <h2 class="text-base font-semibold text-white">Config Errors</h2>
        </div>
        <pre class="min-h-32 overflow-auto p-5 text-sm leading-6 text-zinc-300"><code>{{ snapshot?.configErrors || 'No config errors reported.' }}</code></pre>
      </div>
    </div>
  </section>
</template>

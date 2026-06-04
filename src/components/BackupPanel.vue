<script setup lang="ts">
import { ArchiveRestore, FolderClock } from '@lucide/vue'

import type { BackupEntry } from '../types/display'

defineProps<{
  backups: BackupEntry[]
}>()
</script>

<template>
  <section class="rounded-lg border border-white/10 bg-graphite-900 shadow-panel">
    <div class="flex items-center gap-2 border-b border-white/10 px-5 py-3">
      <FolderClock class="size-5 text-white" />
      <h2 class="text-base font-semibold text-white">Backups</h2>
    </div>

    <div v-if="backups.length" class="divide-y divide-white/10">
      <article v-for="backup in backups" :key="backup.path" class="flex items-center justify-between gap-4 px-5 py-4">
        <div class="min-w-0">
          <p class="truncate text-sm font-semibold text-white">{{ backup.path }}</p>
          <p class="mt-1 text-xs text-zinc-500">{{ backup.createdAt }} / {{ backup.bytes }} bytes</p>
        </div>
        <button
          type="button"
          class="rounded-md border border-white/10 bg-white/[0.03] p-2 text-zinc-400 transition hover:border-white/40 hover:text-white"
          v-tooltip="'Restore support is planned after config diff review lands'"
        >
          <ArchiveRestore class="size-4" />
        </button>
      </article>
    </div>

    <div v-else class="px-5 py-10 text-center text-sm text-zinc-400">No backups yet.</div>
  </section>
</template>

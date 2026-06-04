<script setup lang="ts">
import { Briefcase, Gauge, PanelTop, Search, Star } from '@lucide/vue'

import type { DisplayProfile } from '../types/display'

defineProps<{
  profiles: DisplayProfile[]
  filter: string
}>()

const emit = defineEmits<{
  'update:filter': [value: string]
  toggleAutoApply: [profileId: string]
}>()

const icons = {
  Briefcase,
  Gauge,
  PanelTop,
}
</script>

<template>
  <section class="rounded-lg border border-white/10 bg-graphite-900 shadow-panel">
    <div class="flex flex-col gap-4 border-b border-white/10 px-5 py-3 md:flex-row md:items-center md:justify-between">
      <div>
        <h2 class="text-base font-semibold text-white">Profiles</h2>
      </div>
      <label class="relative block w-full md:w-72">
        <Search class="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-zinc-500" />
        <input
          :value="filter"
          type="search"
          class="h-10 w-full rounded-lg border border-white/10 bg-graphite-850 pl-9 pr-3 text-sm text-white outline-none transition placeholder:text-zinc-500 focus:border-white/60"
          placeholder="Search profiles"
          @input="emit('update:filter', ($event.target as HTMLInputElement).value)"
        />
      </label>
    </div>

    <div class="grid gap-3 p-5 md:grid-cols-3">
      <article
        v-for="profile in profiles"
        :key="profile.id"
        class="rounded-lg border border-white/10 bg-white/[0.03] p-4"
      >
        <div class="flex items-start justify-between gap-3">
          <component :is="icons[profile.icon as keyof typeof icons]" class="size-5 text-white" />
          <button
            type="button"
            :class="[
              'rounded-md border p-1.5 transition',
              profile.autoApply
                ? 'border-white/30 bg-white/10 text-white'
                : 'border-white/10 bg-white/[0.03] text-zinc-500 hover:text-zinc-300',
            ]"
            v-tooltip="'Toggle auto-apply'"
            @click="emit('toggleAutoApply', profile.id)"
          >
            <Star class="size-4" />
          </button>
        </div>
        <h3 class="mt-4 font-semibold text-white">{{ profile.name }}</h3>
        <p class="mt-2 min-h-12 text-sm leading-6 text-zinc-400">{{ profile.description }}</p>
        <div class="mt-4 flex items-center justify-between text-xs text-zinc-500">
          <span>{{ profile.monitorCount }} display{{ profile.monitorCount === 1 ? '' : 's' }}</span>
          <span>{{ profile.favoriteRefresh }}Hz target</span>
        </div>
      </article>
    </div>
  </section>
</template>

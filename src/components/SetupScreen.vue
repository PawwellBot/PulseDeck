<script setup lang="ts">
import { computed } from 'vue'
import {
  Activity,
  CheckCircle2,
  CircleAlert,
  KeyRound,
  Loader2,
  ShieldCheck,
  XCircle,
} from '@lucide/vue'

import type { SetupStatus } from '../types/setup'

const props = defineProps<{
  status: SetupStatus | null
  loading: boolean
  requestingAdmin: boolean
  completing: boolean
  error: string | null
}>()

const emit = defineEmits<{
  refresh: []
  requestAdmin: []
  complete: []
}>()

const canContinue = computed(() => {
  if (!props.status) return false
  return props.status.adminPermissionGranted || !props.status.pkexecAvailable
})

const adminGrantRecorded = computed(() => Boolean(props.status?.adminPermissionGranted))
const adminPromptUnavailable = computed(() => !props.status?.pkexecAvailable)
const adminButtonLabel = computed(() => {
  if (adminGrantRecorded.value) return 'Granted'
  if (adminPromptUnavailable.value) return 'Unavailable'
  return 'Ask Permission'
})
</script>

<template>
  <main class="grid min-h-screen place-items-center bg-graphite-950 px-4 py-8 text-zinc-100">
    <section class="w-full max-w-5xl overflow-hidden rounded-lg border border-white/10 bg-graphite-900 shadow-panel">
      <div class="grid lg:grid-cols-[320px_1fr]">
        <div class="border-b border-white/10 bg-graphite-850 p-6 lg:border-b-0 lg:border-r lg:p-8">
          <div class="flex items-center gap-3">
            <div class="grid size-11 place-items-center rounded-lg border border-white/20 bg-white/10">
              <Activity class="size-5 text-white" />
            </div>
            <div>
              <p class="text-xl font-bold text-white">PulseDeck Setup</p>
              <p class="text-sm text-zinc-500">First launch checks</p>
            </div>
          </div>

          <div class="mt-10 space-y-4 text-sm leading-6 text-zinc-400">
            <p>Hyprland checks</p>
            <p>Admin authorization</p>
            <p>Safe monitor config path</p>
          </div>
        </div>

        <div class="p-6 lg:p-8">
          <div class="flex flex-col gap-3 border-b border-white/10 pb-5 md:flex-row md:items-start md:justify-between">
            <div>
              <p class="text-sm font-semibold uppercase tracking-wide text-zinc-400">Setup</p>
              <h2 class="mt-2 text-2xl font-bold text-white">Prepare PulseDeck</h2>
            </div>

            <button
              type="button"
              class="inline-flex h-10 shrink-0 items-center gap-2 rounded-lg border border-white/10 bg-white/[0.03] px-3 text-sm font-semibold text-zinc-200 transition hover:border-white/20 hover:bg-white/[0.06]"
              :disabled="loading"
              @click="emit('refresh')"
            >
              <Loader2 v-if="loading" class="size-4 animate-spin" />
              <Activity v-else class="size-4" />
              Recheck
            </button>
          </div>

          <div v-if="error" class="mt-5 flex gap-3 rounded-lg border border-white/20 bg-white/[0.06] p-4 text-sm text-zinc-100">
            <CircleAlert class="mt-0.5 size-4 shrink-0" />
            <span>{{ error }}</span>
          </div>

          <div class="mt-5 space-y-3">
            <article
              v-for="check in status?.checks ?? []"
              :key="check.label"
              class="flex gap-3 rounded-lg border border-white/10 bg-white/[0.03] p-4"
            >
              <CheckCircle2 v-if="check.passed" class="mt-0.5 size-5 shrink-0 text-white" />
              <XCircle v-else-if="check.required" class="mt-0.5 size-5 shrink-0 text-zinc-300" />
              <CircleAlert v-else class="mt-0.5 size-5 shrink-0 text-zinc-500" />
              <div class="min-w-0 flex-1">
                <div class="flex flex-wrap items-center gap-2">
                  <h3 class="font-semibold text-white">{{ check.label }}</h3>
                  <span
                    :class="[
                      'rounded-md border px-2 py-0.5 text-xs font-semibold',
                      check.required
                        ? 'border-white/10 bg-white/[0.03] text-zinc-400'
                        : 'border-white/10 bg-white/[0.06] text-zinc-300',
                    ]"
                  >
                    {{ check.required ? 'required' : 'optional' }}
                  </span>
                </div>
                <p class="mt-1 break-words text-sm leading-6 text-zinc-400">{{ check.detail }}</p>
              </div>
            </article>
          </div>

          <div class="mt-5 rounded-lg border border-white/10 bg-white/[0.03] p-4">
            <div class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
              <div class="flex gap-3">
                <KeyRound class="mt-0.5 size-5 shrink-0 text-white" />
                <div>
                  <h3 class="font-semibold text-white">Admin permission prompt</h3>
                  <p class="mt-1 text-sm leading-6 text-zinc-400">
                    Runs <code class="rounded bg-black px-1.5 py-0.5">pkexec true</code> once.
                  </p>
                  <p v-if="status?.adminPermissionMessage" class="mt-2 text-sm leading-6 text-zinc-300">
                    {{ status.adminPermissionMessage }}
                  </p>
                </div>
              </div>

              <button
                type="button"
                class="inline-flex h-10 items-center justify-center gap-2 rounded-lg border border-white/20 bg-white px-3 text-sm font-bold text-black transition hover:bg-zinc-200 disabled:cursor-not-allowed disabled:opacity-60"
                :disabled="requestingAdmin || adminGrantRecorded || adminPromptUnavailable"
                @click="emit('requestAdmin')"
              >
                <CheckCircle2 v-if="adminGrantRecorded" class="size-4" />
                <Loader2 v-else-if="requestingAdmin" class="size-4 animate-spin" />
                <ShieldCheck v-else class="size-4" />
                {{ adminButtonLabel }}
              </button>
            </div>
          </div>

          <div class="mt-6 flex flex-col-reverse gap-3 md:flex-row md:items-center md:justify-between">
            <p class="text-sm text-zinc-500">
              Setup state: {{ status?.setupPath ?? '~/.config/pulsedeck/setup.json' }}
            </p>
            <button
              type="button"
              class="inline-flex h-11 items-center justify-center gap-2 rounded-lg bg-white px-4 text-sm font-bold text-black transition hover:bg-zinc-200 disabled:cursor-not-allowed disabled:opacity-60"
              :disabled="!canContinue || completing"
              @click="emit('complete')"
            >
              <Loader2 v-if="completing" class="size-4 animate-spin" />
              <CheckCircle2 v-else class="size-4" />
              Enter PulseDeck
            </button>
          </div>
        </div>
      </div>
    </section>
  </main>
</template>

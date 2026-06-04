<script setup lang="ts">
import { computed } from 'vue'
import type { AssistTone } from '../types/display'

const props = defineProps<{
  tone: AssistTone
  label: string
}>()

const classes = computed(() => {
  if (props.tone === 'good') return 'border-white/30 bg-white/15 text-white'
  if (props.tone === 'ready') return 'border-white/20 bg-white/10 text-zinc-100'
  if (props.tone === 'warn') return 'border-white/15 bg-white/[0.07] text-zinc-300'
  if (props.tone === 'blocked') return 'border-white/10 bg-black text-zinc-400'
  return 'border-white/10 bg-white/5 text-zinc-300'
})
</script>

<template>
  <span :class="['inline-flex h-7 items-center rounded-md border px-2.5 text-xs font-semibold', classes]">
    {{ label }}
  </span>
</template>

import { invoke } from '@tauri-apps/api/core'

declare global {
  interface Window {
    __TAURI_INTERNALS__?: unknown
  }
}

export const isTauriRuntime = () =>
  typeof window !== 'undefined' && window.__TAURI_INTERNALS__ !== undefined

export async function command<T>(name: string, args?: Record<string, unknown>): Promise<T> {
  if (!isTauriRuntime()) {
    throw new Error('PulseDeck is running in browser preview mode.')
  }

  return invoke<T>(name, args)
}

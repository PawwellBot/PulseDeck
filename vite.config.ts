import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import svgLoader from 'vite-svg-loader'

const tauriDebug = process.env.TAURI_DEBUG === 'true'

export default defineConfig({
  clearScreen: false,
  envPrefix: ['VITE_', 'TAURI_'],
  plugins: [vue(), svgLoader()],
  server: {
    host: '127.0.0.1',
    port: 1420,
    strictPort: true,
  },
  build: {
    target: ['es2022', 'chrome120', 'safari16'],
    minify: tauriDebug ? false : 'esbuild',
    sourcemap: tauriDebug,
  },
})

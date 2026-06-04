import { createApp } from 'vue'
import { VueQueryPlugin } from '@tanstack/vue-query'
import FloatingVue from 'floating-vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import './assets/styles.css'
import 'floating-vue/dist/style.css'

createApp(App)
  .use(createPinia())
  .use(VueQueryPlugin, {
    queryClientConfig: {
      defaultOptions: {
        queries: {
          staleTime: 8_000,
          refetchOnWindowFocus: false,
        },
      },
    },
  })
  .use(FloatingVue)
  .mount('#app')

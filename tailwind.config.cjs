/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./index.html', './src/**/*.{vue,ts}'],
  theme: {
    extend: {
      colors: {
        graphite: {
          950: '#000000',
          900: '#080808',
          850: '#111111',
          800: '#1a1a1a',
          700: '#2a2a2a',
        },
      },
      boxShadow: {
        panel: '0 20px 60px rgba(0, 0, 0, 0.26)',
        glow: '0 0 0 1px rgba(255, 255, 255, 0.45), 0 18px 45px rgba(255, 255, 255, 0.08)',
      },
      fontFamily: {
        sans: ['Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}

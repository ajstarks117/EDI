/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        background: {
          DEFAULT: '#0F172A', // Deep dark slate
          card: '#1E293B',    // Card slate
          border: '#334155',  // Border slate
          body: '#0B0F19',    // Deep space dark background
        },
        emergency: {
          DEFAULT: '#EF4444', // Crimson Red
          medium: '#F59E0B',  // Amber
          low: '#10B981',     // Emerald Green
        },
        primary: {
          50: '#EEF2FF',
          100: '#E0E7FF',
          200: '#C7D2FE',
          300: '#A5B4FC',
          400: '#818CF8',
          500: '#6366F1', // Indigo
          600: '#4F46E5',
          700: '#4338CA',
        }
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        outfit: ['Outfit', 'sans-serif'],
      },
      boxShadow: {
        'glow-red': '0 0 15px rgba(239, 68, 68, 0.4)',
        'glow-indigo': '0 0 15px rgba(99, 102, 241, 0.2)',
      }
    },
  },
  plugins: [],
}

/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      /* ── Colour Tokens ─────────────────────────────────── */
      colors: {
        /* Playbook brand palette (CSS-var backed for runtime theming) */
        'primary-navy':   'var(--color-primary-navy)',
        'safety-teal':    'var(--color-safety-teal)',
        'alert-red':      'var(--color-alert-red)',
        'warning-amber':  'var(--color-warning-amber)',
        'success-green':  'var(--color-success-green)',
        'off-white':      'var(--color-off-white)',
        'dark-text':      'var(--color-dark-text)',
        'muted-text':     'var(--color-muted-text)',

        /* Surfaces (swap automatically on .dark) */
        surface: {
          DEFAULT: 'var(--surface-bg)',
          card:    'var(--surface-card)',
          border:  'var(--surface-border)',
        },

        /* Legacy aliases kept for existing components */
        background: {
          DEFAULT: '#0F172A',
          card: '#1E293B',
          border: '#334155',
          body: '#0B0F19',
        },
        emergency: {
          DEFAULT: '#EF4444',
          medium: '#F59E0B',
          low: '#10B981',
        },
        primary: {
          50:  '#EEF2FF',
          100: '#E0E7FF',
          200: '#C7D2FE',
          300: '#A5B4FC',
          400: '#818CF8',
          500: '#6366F1',
          600: '#4F46E5',
          700: '#4338CA',
        },
      },

      /* ── 8-pt Spacing Scale ────────────────────────────── */
      spacing: {
        'px': '1px',
        '0': '0px',
        '0.5': '4px',   // xs
        '1':   '8px',   // sm  — base unit
        '1.5': '12px',
        '2':   '16px',  // md
        '2.5': '20px',
        '3':   '24px',  // lg
        '3.5': '28px',
        '4':   '32px',  // xl
        '5':   '40px',  // 2xl
        '6':   '48px',  // 3xl
        '7':   '56px',
        '8':   '64px',  // 4xl
        '9':   '72px',
        '10':  '80px',
        '11':  '88px',
        '12':  '96px',
        '14':  '112px',
        '16':  '128px',
      },

      /* ── Border Radii ──────────────────────────────────── */
      borderRadius: {
        'none': '0px',
        'sm':   '4px',
        'md':   '8px',
        'lg':   '16px',
        'xl':   '24px',
        'pill': '100px',
        'full': '9999px',
      },

      /* ── Typography ────────────────────────────────────── */
      fontFamily: {
        sans:   ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
        outfit: ['Outfit', 'Inter', 'sans-serif'],
      },
      fontSize: {
        'xs':   ['0.75rem',  { lineHeight: '1rem' }],
        'sm':   ['0.875rem', { lineHeight: '1.25rem' }],
        'base': ['1rem',     { lineHeight: '1.5rem' }],
        'lg':   ['1.125rem', { lineHeight: '1.75rem' }],
        'xl':   ['1.25rem',  { lineHeight: '1.75rem' }],
        '2xl':  ['1.5rem',   { lineHeight: '2rem' }],
        '3xl':  ['1.875rem', { lineHeight: '2.25rem' }],
        '4xl':  ['2.25rem',  { lineHeight: '2.5rem' }],
      },

      /* ── Shadows ───────────────────────────────────────── */
      boxShadow: {
        'glow-red':    '0 0 15px rgba(211, 47, 47, 0.4)',
        'glow-teal':   '0 0 15px rgba(13, 122, 140, 0.3)',
        'glow-indigo': '0 0 15px rgba(99, 102, 241, 0.2)',
      },
    },
  },
  plugins: [],
}

/**
 * TravelSure Design System — Color & Typography Tokens
 *
 * These tokens mirror the CSS custom-properties declared in index.css
 * so that both Tailwind utilities AND runtime JS can reference a single
 * source of truth.
 */

export const colors = {
  /** Core brand navy – sidebar backgrounds, primary buttons */
  primaryNavy: '#1A3C5E',
  /** Safety / operational teal – status badges, map overlays */
  safetyTeal: '#0D7A8C',
  /** Critical / SOS red – emergency alerts, destructive actions */
  alertRed: '#D32F2F',
  /** Warning amber – geofence exits, moderate-severity notices */
  warningAmber: '#F0A500',
  /** Success / resolved green – confirmations, healthy status */
  successGreen: '#2E7D32',
  /** Light-mode page background */
  offWhite: '#F5F7FA',
  /** Primary text on light backgrounds */
  darkText: '#1C2B3A',
  /** Secondary / muted text */
  mutedText: '#607080',
} as const;

export const spacing = {
  /** 8-pt grid base unit */
  unit: 8,
  xs: '4px',   // 0.5 unit
  sm: '8px',   // 1 unit
  md: '16px',  // 2 units
  lg: '24px',  // 3 units
  xl: '32px',  // 4 units
  '2xl': '40px', // 5 units
  '3xl': '48px', // 6 units
  '4xl': '64px', // 8 units
} as const;

export const radii = {
  sm: '4px',
  md: '8px',
  lg: '16px',
  xl: '24px',
  pill: '100px',
} as const;

export const typography = {
  fontFamily: {
    sans: "'Inter', system-ui, -apple-system, sans-serif",
    heading: "'Outfit', 'Inter', sans-serif",
  },
  fontSize: {
    xs: '0.75rem',    // 12px
    sm: '0.875rem',   // 14px
    base: '1rem',     // 16px
    lg: '1.125rem',   // 18px
    xl: '1.25rem',    // 20px
    '2xl': '1.5rem',  // 24px
    '3xl': '1.875rem', // 30px
    '4xl': '2.25rem',  // 36px
  },
  fontWeight: {
    normal: '400',
    medium: '500',
    semibold: '600',
    bold: '700',
    extrabold: '800',
  },
} as const;

export const theme = {
  colors,
  spacing,
  radii,
  typography,
} as const;

export default theme;

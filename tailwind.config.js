/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./app/views/**/*.{erb,haml,html,slim}",
    "./app/frontend/**/*.{vue,js,ts}"
  ],
  theme: {
    extend: {
      fontFamily: {
        serif: ['Garamond Text', 'Times New Roman', 'serif'],
        sans: ['Optima', 'Candara', 'sans-serif'],
        mono: ['Fira Code', 'monospace']
      },
      colors: {
        // Semantic brand colors - much easier to remember!
        brand: {
          green: {
            light: '#f0fdf4',
            base: '#059669',
            dark: '#047857',
            darker: '#065f46',
          },
          blue: {
            light: '#eff6ff',
            base: '#2563eb',
            dark: '#1d4ed8',
          }
        },
        // Feature colors
        feature: {
          green: '#22c55e',
          blue: '#3b82f6',
          purple: '#7c3aed',
        },
        // Quick access - your most used colors
        primary: '#059669',
        secondary: '#2563eb',
        danger: '#dc2626',
        warning: '#d97706',
        success: '#16a34a',
        info: '#0ea5e9'
      },
      backgroundImage: {
        // Gradients from your design
        'gradient-hero': 'linear-gradient(135deg, #f0fdf4 0%, #eff6ff 100%)',
        'gradient-primary': 'linear-gradient(135deg, #059669 0%, #2563eb 100%)',
        'gradient-green': 'linear-gradient(135deg, #22c55e 0%, #059669 100%)',
        'gradient-blue': 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)',
        'gradient-overlay': 'linear-gradient(90deg, rgba(5, 150, 105, 0.1) 0%, rgba(37, 99, 235, 0.1) 100%)',
      }
    }
  },
  plugins: [],
}

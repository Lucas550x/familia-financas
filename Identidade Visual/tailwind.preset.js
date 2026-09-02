/** Família Finanças — preset do Tailwind
 *  tailwind.config.js:  export default { presets: [ffPreset], content: [...] }
 */
export default {
  theme: {
    extend: {
      colors: {
        ff: {
          verde: { DEFAULT: '#0F7A5A', vivo: '#1FA97C', fundo: '#0B5C43' },
          menta: { DEFAULT: '#DCF2E8', forte: '#B9E5D3' },
          coral: { DEFAULT: '#E2603C', texto: '#C24A28', fundo: '#FBE6DF' },
          ouro:  { DEFAULT: '#F2B441', texto: '#8A5F09', fundo: '#FDF1DA' },
          grafite: '#10221C',
          nevoa: { DEFAULT: '#6B7A74', clara: '#9AA7A2' },
          areia: '#F7F5EF',
          linha: '#E7E4DB',
        },
      },
      fontFamily: {
        display: ['"Plus Jakarta Sans"', 'system-ui', 'sans-serif'],
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      fontSize: {
        xs: ['12px', '1.4'],
        sm: ['13px', '1.45'],
        base: ['15px', '1.55'],
        lg: ['18px', '1.4'],
        xl: ['22px', '1.25'],
        '2xl': ['30px', '1.2'],
        '3xl': ['38px', '1.15'],
      },
      borderRadius: { sm: '10px', md: '16px', lg: '24px' },
    },
  },
}

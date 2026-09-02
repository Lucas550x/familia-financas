// Família Finanças — tokens tipados para React Native / TS
export const cores = {
  verdeCofre: '#0F7A5A',
  verdeVivo: '#1FA97C',
  verdeFundo: '#0B5C43',
  menta: '#DCF2E8',
  mentaForte: '#B9E5D3',
  coral: '#E2603C',
  coralTexto: '#C24A28',
  coralFundo: '#FBE6DF',
  ouro: '#F2B441',
  ouroTexto: '#8A5F09',
  ouroFundo: '#FDF1DA',
  grafite: '#10221C',
  nevoa: '#6B7A74',
  nevoaClara: '#9AA7A2',
  areia: '#F7F5EF',
  linha: '#E7E4DB',
  branco: '#FFFFFF',
} as const

export const temaClaro = {
  bg: cores.areia,
  surface: cores.branco,
  text: cores.grafite,
  textMuted: cores.nevoa,
  border: cores.linha,
  primary: cores.verdeCofre,
  onPrimary: cores.branco,
  income: cores.verdeCofre,
  expense: cores.coralTexto,
  goal: cores.ouro,
} as const

export const temaEscuro = {
  bg: '#0B1714',
  surface: '#14261F',
  text: '#EDF3F0',
  textMuted: '#93A49D',
  border: '#24382F',
  primary: cores.verdeVivo,
  onPrimary: '#06231A',
  income: cores.verdeVivo,
  expense: '#F58063',
  goal: cores.ouro,
} as const

export const fontes = {
  display: 'Plus Jakarta Sans',
  body: 'Inter',
} as const

export const tamanhos = { xs: 12, sm: 13, base: 15, lg: 18, xl: 22, xxl: 30, xxxl: 38 } as const
export const espaco = { 1: 4, 2: 8, 3: 12, 4: 16, 5: 20, 6: 24, 8: 32, 10: 40 } as const
export const raio = { sm: 10, md: 16, lg: 24, full: 999 } as const

export type Tema = typeof temaClaro

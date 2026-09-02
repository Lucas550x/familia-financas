# Família Finanças — identidade visual

```
familia-financas-brand/
├── CLAUDE.md              contexto para a IA do editor (leia primeiro)
├── BRAND.md               manual da marca completo
├── tokens/
│   ├── tokens.css         variáveis CSS — fonte única de verdade
│   ├── tokens.json        mesmos valores em JSON, para scripts e design tools
│   ├── tailwind.preset.js preset do Tailwind
│   └── theme.ts           constantes tipadas para React Native / TS
├── logo/                  SVGs em todas as variações
└── exemplos/
    └── preview.html       abra no navegador para ver tudo aplicado
```

## Como usar no VS Code

1. Copie a pasta inteira para a raiz do projeto, ou apenas `tokens/` e `logo/` para
   `src/styles/` e `src/assets/`.
2. **Copie `CLAUDE.md` para a raiz do repositório.** É o arquivo que o Claude Code e a
   maioria dos assistentes de IA lêem automaticamente como contexto do projeto. Se já
   existir um `CLAUDE.md`, cole o conteúdo dentro dele numa seção "Design".
3. Importe os tokens no entrypoint:

```css
@import "./styles/tokens.css";
```

4. Carregue as fontes no `index.html`:

```html
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet"
  href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&family=Inter:wght@400;500;600&display=swap">
```

Em produção, prefira baixar os arquivos `.woff2` e servir localmente.

5. Com Tailwind, em `tailwind.config.js`:

```js
import ffPreset from './tokens/tailwind.preset.js'
export default { presets: [ffPreset], content: ['./src/**/*.{ts,tsx}'] }
```

## Prompt sugerido para a IA

> Leia `CLAUDE.md` e `tokens/tokens.css`. Crie a tela de [nome] seguindo esses tokens.
> Não use nenhuma cor literal — apenas as variáveis `--ff-*`.

## Modo escuro

Coloque `data-theme="dark"` no `<html>`. Todas as variáveis semânticas trocam sozinhas.

## Fontes

Plus Jakarta Sans e Inter, ambas Open Font License, liberadas para uso comercial.

# Contexto de design — Família Finanças

App de controle financeiro para famílias brasileiras. Várias pessoas da mesma casa lançam
e acompanham receitas, despesas e metas juntas. Público: adultos 25–55, não especialistas
em finanças. O app precisa parecer confiável e calmo, nunca corporativo ou intimidador.

**Antes de escrever qualquer UI, leia `BRAND.md` e importe `tokens/tokens.css`.**
Nunca escreva um valor de cor literal em componentes — sempre use as variáveis.

## Regras que não se negociam

1. **Verde é dinheiro que entra.** `--ff-income` só aparece em receitas e saldos positivos.
   Nunca use verde num botão genérico sem relação com valor.
2. **Coral é dinheiro que sai.** `--ff-expense` só em despesas, saldo negativo e erros.
3. **Ouro é meta.** Só em progresso de objetivos, reservas e conquistas.
4. **Estrutura é neutra.** Fundo `--ff-bg` (areia), cards `--ff-surface`, texto `--ff-text`
   e `--ff-text-muted`. Se uma tela parece colorida demais, o problema é aqui.
5. **Todo valor monetário** usa a classe `.ff-valor` (ou `font-variant-numeric: tabular-nums`),
   formatado com `Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' })`.
6. **Nunca use verde e coral como única distinção** entre entrada e saída — daltonismo é
   comum. Sempre acompanhe de sinal (`+` / `−`) ou ícone.
7. **Um botão primário por tela.** O resto é secundário (contorno) ou fantasma.
8. **Sem sombras decorativas.** Hierarquia vem da cor de superfície, não de elevação.
   `--ff-shadow-card` só em elementos flutuantes reais.
9. **Sem gradientes, sem glassmorphism, sem emoji na interface.** Ícones: Lucide ou
   Tabler, contorno, 20px na navegação e 18px em listas.
10. **Contraste mínimo AA.** Sobre fundos claros use `--ff-coral-texto` e `--ff-ouro-texto`,
    nunca `--ff-coral` e `--ff-ouro` puros em texto.

## Tipografia

- Títulos e números de destaque: `--ff-font-display` (Plus Jakarta Sans), peso 600/700.
- Corpo, rótulos e valores em lista: `--ff-font-body` (Inter), peso 400/500/600.
- Escala: 12 / 13 / 15 / 18 / 22 / 30 / 38. Não invente tamanhos intermediários.
- Sentence case em tudo. Sem caixa alta, sem rótulos "eyebrow" acima de títulos.

## Voz do produto

Direta, calorosa, sem jargão. Fale "sua família", nunca "o usuário".

| Escreva                          | Não escreva                              |
| -------------------------------- | ---------------------------------------- |
| "Nova despesa"                    | "Cadastrar novo lançamento de saída"     |
| "Você gastou R$ 312 com mercado" | "Análise de gastos da categoria mercado" |
| "Não deu para conectar ao banco. Tente de novo." | "Erro: falha na sincronização!" |
| "Comece pela primeira despesa"   | "Nenhum item encontrado"                 |

Botões dizem o que acontece: "Salvar despesa", nunca "Enviar" ou "OK". Sem exclamação em
mensagens do sistema. Sem "por favor". Estados vazios são convite para agir, não desculpa.

## Layout

- Grade de 4px. Respiro lateral de 20px nas telas de celular.
- Cards: raio 16px, fundo `--ff-surface`, borda `1px solid --ff-border`, padding 16px.
- Ícone quadrado de categoria: 34–36px, raio 10px, fundo `--ff-menta`, ícone `--ff-primary`.
- Altura mínima de alvo tocável: 44px.
- Navegação inferior com 5 itens: início, relatórios, novo lançamento, família, perfil.

## Assets

`logo/simbolo.svg` (mínimo 24px), `logo/logo-horizontal.svg` (mínimo 120px de largura),
versões `-negativo` para fundos escuros, `favicon.svg` para web.
Área de proteção ao redor do logo: altura do telhado do símbolo em todos os lados.
Não distorça, não recolora, não adicione sombra ou contorno.

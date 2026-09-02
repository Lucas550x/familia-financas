# Família Finanças — manual da marca

## O conceito

O símbolo é uma casa formada por três barras crescentes sob um telhado. O telhado protege,
as barras crescem. As três barras têm opacidades diferentes: leem como membros de uma
família de tamanhos diferentes e, ao mesmo tempo, como um gráfico de evolução.

Casa + progresso + proteção. É o que um app de controle financeiro doméstico promete.

## Logo

| Arquivo | Uso | Tamanho mínimo |
| --- | --- | --- |
| `logo/logo-horizontal.svg` | Cabeçalho, materiais, assinatura | 120px de largura |
| `logo/logo-vertical.svg` | Splash, materiais quadrados | 100px de largura |
| `logo/simbolo.svg` | Avatar, ícone do app, espaços apertados | 24px |
| `logo/simbolo-negativo.svg` | Sobre fundos escuros ou fotos | 24px |
| `logo/simbolo-monocromatico.svg` | Herda `currentColor`; carimbo, impressão 1 cor | 24px |
| `logo/favicon.svg` | Aba do navegador, PWA | 16px |

**Área de proteção:** margem livre em todos os lados igual à altura do telhado do símbolo
(cerca de 22% da altura do logo).

**Não faça:** distorcer proporções, trocar o verde por outra cor, aplicar a versão positiva
sobre fundo escuro, adicionar sombra ou contorno, girar, colocar dentro de outra forma,
usar o símbolo e o nome com espaçamento diferente do arquivo original.

## Cores

### Marca

| Nome | Hex | Uso |
| --- | --- | --- |
| Verde Cofre | `#0F7A5A` | Primária. Marca, saldo, receitas |
| Verde Vivo | `#1FA97C` | Ações, estado ativo, verde no modo escuro |
| Menta | `#DCF2E8` | Fundo de ícones, chips, superfícies suaves |

### Sinal financeiro

| Nome | Hex | Uso |
| --- | --- | --- |
| Coral | `#E2603C` | Despesas, alertas (preenchimentos) |
| Coral Texto | `#C24A28` | Mesma cor em texto sobre fundo claro (AA) |
| Ouro | `#F2B441` | Metas, poupança, conquistas |
| Ouro Texto | `#8A5F09` | Mesma cor em texto sobre fundo claro (AA) |

### Neutros

| Nome | Hex | Uso |
| --- | --- | --- |
| Grafite | `#10221C` | Texto principal, fundo do modo escuro |
| Névoa | `#6B7A74` | Texto de apoio |
| Areia | `#F7F5EF` | Fundo das telas |
| Linha | `#E7E4DB` | Divisórias e bordas |
| Branco | `#FFFFFF` | Superfície de cards |

### A regra de cor

Cor nunca é decoração neste produto — ela informa se dinheiro entrou ou saiu. Verde é
entrada, coral é saída, ouro é meta. Todo o resto da interface é neutro. Se você precisa
de um botão que não trata de valor, ele é neutro ou contorno, não verde.

Verde e coral nunca são a única distinção entre entrada e saída. Sempre acompanhe de sinal
(`+` / `−`) ou de ícone, porque daltonismo vermelho-verde é comum.

## Tipografia

**Plus Jakarta Sans** para títulos e números de destaque. Formas geométricas e abertas,
com um leve caráter humanista que evita o tom corporativo.
**Inter** para corpo, rótulos e valores em lista. Foi desenhada para telas e tem números
tabulares excelentes, que é exatamente o que uma lista de transações precisa.

Ambas são Open Font License, liberadas para uso comercial.

Escala: 12 / 13 / 15 / 18 / 22 / 30 / 38.
Entrelinha: 1.2 em títulos, 1.55 em texto corrido.
Sentence case em toda a interface. Sem caixa alta.

Valores monetários sempre com `font-variant-numeric: tabular-nums` e formatados com
`Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' })`.

## Layout e componentes

- Grade de 4px. Respiro lateral de 20px em telas de celular.
- Card: raio 16px, fundo branco, borda de 1px em Linha, padding 16px.
- Card de saldo: fundo Verde Cofre, texto branco, raio 16px. É o único bloco totalmente
  colorido da tela inicial — a cor concentrada nele é o que dá hierarquia.
- Ícone de categoria: quadrado de 34–36px, raio 10px, fundo Menta, ícone em Verde Cofre.
- Barra de progresso de meta: 6px de altura, raio 3px, trilho em Linha, preenchimento Ouro.
- Alvo tocável mínimo: 44px.
- Navegação inferior de 5 itens. Ícones de contorno a 22px, ativo em Verde Cofre.
- Sem sombras decorativas. Hierarquia vem da cor de superfície.

## Voz

Direta, calorosa, sem jargão financeiro. Fale "sua família", nunca "o usuário".
Botões dizem o que acontece: "Salvar despesa", não "Enviar".
Erros explicam o que houve e o que fazer, sem pedir desculpa e sem exclamação.
Estados vazios são convite para agir: "Comece pela primeira despesa".

## Modo escuro

Fundo `#0B1714`, superfícies `#14261F`. A primária troca para Verde Vivo `#1FA97C`, porque
Verde Cofre não tem contraste suficiente sobre fundo escuro. Despesa vira `#F58063`.
Todos os valores já estão em `tokens/tokens.css` sob `[data-theme="dark"]`.

## Registro

"Família Finanças" é descritivo, o que enfraquece a proteção no INPI. Vale considerar um
nome comercial mais distintivo mantendo "Família Finanças" como assinatura descritiva.
Consulte a base do INPI antes de investir em identidade impressa.

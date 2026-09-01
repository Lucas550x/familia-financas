# Família Finanças — Contexto do Projeto

## 1. Objetivo

**Família Finanças** é um aplicativo Flutter de controle financeiro familiar, inicialmente focado em Android e preparado para evolução para iOS.

O objetivo é permitir que duas ou mais pessoas da mesma família controlem, de forma simples e visual:

- entradas de dinheiro;
- contas e despesas;
- contas fixas, únicas e parceladas;
- quem pagou cada conta;
- quanto cada pessoa contribuiu;
- valores pagos e pendentes;
- saldo previsto do mês;
- metas financeiras;
- orçamento mensal;
- relatórios;
- vencimentos e alertas;
- backup e restauração;
- atualizações do aplicativo.

A experiência deve ser simples o suficiente para uso diário por pessoas que não têm conhecimento financeiro ou técnico.

---

## 2. Estado atual

Versão base do projeto: **2.0.0**.

O aplicativo atualmente possui:

- dashboard mensal;
- entradas por perfil;
- despesas por categoria;
- contas únicas;
- contas fixas mensais;
- despesas recorrentes por quantidade de meses;
- controle de pagamento;
- identificação de quem pagou;
- perfis familiares;
- metas;
- orçamento mensal;
- relatórios;
- navegação entre meses;
- tema automático, claro e escuro;
- persistência local com `SharedPreferences`;
- backup/restauração em JSON;
- alertas visuais e sonoros dentro do aplicativo;
- verificação de atualização pelo GitHub Releases;
- workflow do GitHub Actions para validar, testar, compilar e publicar APK.

---

## 3. Stack

- **Flutter**
- **Dart**
- **Material 3**
- `shared_preferences` — persistência local
- `http` — consulta de atualizações no GitHub
- `url_launcher` — abertura da nova versão para instalação
- GitHub Actions — CI/CD e geração do APK

Arquivo de dependências: `pubspec.yaml`.

---

## 4. Estrutura principal

```text
familia_financas/
├── lib/
│   ├── main.dart
│   ├── models.dart
│   ├── app_state.dart
│   └── update_service.dart
├── test/
│   ├── models_test.dart
│   └── widget_test.dart
├── .github/
│   └── workflows/
│       └── build-apk.yml
├── analysis_options.yaml
├── pubspec.yaml
├── README.md
└── PROJECT.md
```

### `lib/main.dart`

Interface principal do aplicativo, navegação, telas, formulários, componentes visuais e interação com o usuário.

### `lib/models.dart`

Modelos de domínio usados pelo aplicativo, como perfis, entradas, contas, metas e demais estruturas financeiras.

### `lib/app_state.dart`

Estado principal do aplicativo, persistência, carregamento e operações financeiras.

### `lib/update_service.dart`

Consulta a versão publicada no GitHub e identifica se existe uma atualização mais nova.

---

## 5. Repositório e atualizações

Repositório principal:

`Lucas550x/familia-financas`

Branch de produção:

`main`

Cada push para `main` dispara o workflow:

`.github/workflows/build-apk.yml`

O workflow deve:

1. baixar o projeto;
2. instalar Flutter;
3. gerar os arquivos Android necessários;
4. preparar a assinatura de release;
5. instalar dependências;
6. executar análise estática;
7. executar testes;
8. compilar o APK de release;
9. disponibilizar o APK como artifact;
10. criar uma GitHub Release;
11. marcar a release mais nova como `latest`.

O aplicativo consulta:

`https://api.github.com/repos/Lucas550x/familia-financas/releases/latest`

Quando o build publicado for maior que o instalado, o aplicativo deve mostrar um aviso de **Atualização disponível**.

O Android não permite atualização totalmente silenciosa de um APK comum. O usuário ainda precisa confirmar a instalação da nova versão.

---

## 6. Build e versão

O GitHub Actions passa estas definições ao Flutter:

```text
APP_BUILD=<github.run_number>
APP_SHA=<github.sha>
```

No Dart, esses valores devem continuar compatíveis com:

```dart
const int.fromEnvironment('APP_BUILD');
const String.fromEnvironment('APP_SHA');
```

Não remover essas definições sem também modificar o sistema de atualização.

---

## 7. Assinatura Android

A assinatura de release usa GitHub Actions Secrets.

Secrets esperados:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

### Regra crítica

**Nunca colocar a chave `.jks`, senhas ou conteúdo dos secrets dentro do repositório.**

Nunca imprimir os secrets nos logs do GitHub Actions.

Todos os APKs futuros precisam continuar usando a mesma chave de assinatura para que possam atualizar o aplicativo instalado sem desinstalação.

---

## 8. Como abrir no VS Code

Abra no VS Code **a pasta `familia_financas` que contém o `pubspec.yaml`**.

Não abra somente `lib` e, se possível, não abra uma pasta acima contendo vários projetos.

Extensões recomendadas:

- Flutter;
- Dart;
- GitHub Pull Requests and Issues (opcional);
- GitLens (opcional).

Depois de abrir o projeto, execute no terminal:

```bash
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter run
```

Para Android, o computador precisa possuir Flutter SDK e Android SDK configurados.

---

## 9. Comandos importantes

### Instalar dependências

```bash
flutter pub get
```

### Formatar o código

```bash
dart format lib test
```

### Analisar erros

```bash
flutter analyze
```

### Executar testes

```bash
flutter test
```

### Rodar no celular/emulador

```bash
flutter run
```

### Gerar APK localmente

```bash
flutter build apk --release
```

O build oficial de produção deve continuar sendo realizado pelo GitHub Actions para garantir assinatura e versionamento consistentes.

---

## 10. Regras para alterações de código

Antes de considerar qualquer alteração concluída:

1. executar `dart format lib test`;
2. executar `flutter analyze`;
3. executar `flutter test`;
4. corrigir erros antes de fazer commit;
5. conferir se o app continua abrindo em telas pequenas;
6. não remover funcionalidades existentes sem solicitação explícita;
7. não quebrar compatibilidade com os dados já salvos;
8. manter o mecanismo de atualização funcionando;
9. não colocar segredos no código;
10. evitar dependências desnecessárias.

Se uma alteração afetar modelos persistidos, criar migração ou leitura compatível com os dados anteriores.

---

## 11. Direção visual

O aplicativo deve parecer um produto financeiro moderno e amigável, não um painel administrativo genérico.

Princípios:

- Material 3;
- visual limpo;
- espaçamento consistente;
- cartões arredondados;
- informações mais importantes primeiro;
- valores financeiros fáceis de escanear;
- cores de status utilizadas com moderação;
- bom contraste no modo claro e escuro;
- componentes adequados a telas pequenas;
- textos em português do Brasil;
- evitar telas excessivamente cheias;
- evitar elementos enormes que consumam espaço desnecessário.

O dashboard deve priorizar:

- saldo previsto;
- entradas;
- total de despesas;
- já pago;
- falta pagar;
- próximas contas;
- alertas importantes.

---

## 12. Regras financeiras

### Entradas

Uma entrada pode ser:

- única;
- mensal/recorrente.

Toda entrada pode estar associada a um perfil.

### Contas

Uma conta pode ser:

- única;
- fixa mensal;
- recorrente durante N meses.

Deve possuir, quando aplicável:

- descrição;
- valor;
- vencimento;
- categoria;
- recorrência;
- status de pagamento;
- perfil que realizou o pagamento.

### Meses

Os cálculos da tela mensal devem utilizar somente dados pertencentes ao mês selecionado, respeitando recorrências.

### Pagamento

Ao marcar uma despesa como paga, registrar quem realizou o pagamento sempre que essa informação estiver disponível.

---

## 13. Persistência

Atualmente os dados ficam armazenados localmente no aparelho com `SharedPreferences`.

O aplicativo deve continuar funcionando sem internet para as funcionalidades financeiras locais.

A falta de conexão só deve afetar recursos que realmente precisam de internet, como a verificação de atualização.

Não apagar dados do usuário em uma atualização normal do aplicativo.

---

## 14. Backup

O backup atual utiliza JSON.

Ao alterar modelos de dados:

- manter o JSON anterior legível quando possível;
- validar dados antes de restaurar;
- não travar o aplicativo por causa de um backup inválido;
- mostrar erro compreensível ao usuário.

---

## 15. Sincronização futura

O armazenamento atual é local. Para sincronização verdadeira entre celulares será necessário backend.

Arquitetura futura recomendada:

- autenticação;
- famílias/grupos;
- membros da família;
- banco remoto;
- regras de acesso por família;
- sincronização offline-first;
- resolução de conflitos;
- backup remoto.

Possíveis serviços: Supabase ou Firebase.

Não introduzir sincronização improvisada ou insegura apenas para compartilhar dados entre aparelhos.

---

## 16. Funcionalidades futuras prioritárias

A evolução pode incluir:

- sincronização entre os celulares da família;
- login;
- convite de membros;
- notificações locais do sistema Android/iOS;
- lembretes em background;
- biometria;
- anexar comprovantes;
- busca e filtros avançados;
- exportação CSV/PDF;
- comparação entre meses;
- gráficos de evolução;
- cartões de crédito e fechamento de fatura;
- parcelamento de compras;
- contas bancárias/carteiras;
- reserva de emergência;
- objetivos compartilhados;
- iOS/TestFlight/App Store.

---

## 17. Política de qualidade

Uma funcionalidade não deve ser considerada pronta apenas porque a interface apareceu.

Para considerar uma feature concluída, verificar:

- funcionamento do fluxo principal;
- casos vazios;
- valores zero;
- valores grandes;
- datas no fim/início do mês;
- fevereiro e anos bissextos quando relevante;
- recorrências;
- edição;
- exclusão;
- reinício do aplicativo;
- persistência;
- modo claro;
- modo escuro;
- tela pequena;
- ausência de internet quando possível;
- erros do serviço externo;
- regressões em funções existentes.

---

## 18. Checklist antes do commit

```text
[ ] Código formatado
[ ] flutter pub get sem erro
[ ] flutter analyze sem erros relevantes
[ ] flutter test passando
[ ] Fluxo alterado testado manualmente
[ ] Persistência verificada
[ ] Nenhum secret no commit
[ ] Atualização continua compatível
[ ] Interface revisada em tela pequena
[ ] Commit descreve claramente a alteração
```

---

## 19. Orientação para IA/agentes dentro do VS Code

Ao receber uma tarefa neste projeto:

1. leia este `PROJECT.md` antes de alterar arquivos;
2. examine o código existente antes de propor uma reescrita;
3. preserve funcionalidades que já funcionam;
4. prefira mudanças pequenas e verificáveis;
5. corrija a causa do erro, não apenas o sintoma;
6. execute análise e testes depois das alterações;
7. não invente que algo foi testado se o comando não foi realmente executado;
8. informe limitações do ambiente quando houver;
9. não modifique secrets ou assinatura sem necessidade;
10. não faça push destrutivo, force-push ou exclusão de histórico sem autorização explícita.

### Objetivo permanente

Transformar o Família Finanças em um aplicativo familiar confiável, simples, bonito e seguro, mantendo estabilidade a cada atualização.

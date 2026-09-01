# Família Finanças 2.0

Aplicativo Flutter para controle financeiro familiar.

## Recursos
- Dashboard mensal com entradas, despesas, saldo previsto, pagos e pendentes.
- Contas únicas, fixas ou por quantidade de meses.
- Pagamento associado a um perfil da família.
- Entradas únicas ou mensais por perfil.
- Perfis, metas, orçamento mensal e relatórios.
- Tema automático, claro e escuro.
- Alertas visuais e sonoros dentro do app.
- Backup e restauração em JSON via área de transferência.
- Persistência local com SharedPreferences.
- Verificação de atualizações pelo GitHub Releases.
- Cada push na branch `main` valida, testa, compila e publica um novo APK.

## Atualização
O workflow gera uma release `build-N` em cada push para `main`. O APK recebe `APP_BUILD=N`. O aplicativo consulta a release mais recente e mostra um aviso se existir build maior.

> Android não permite instalação silenciosa de APK por um aplicativo comum. O botão Atualizar abre o APK da release para o usuário confirmar a instalação.

## Assinatura Android
Antes do primeiro build 2.0, configure os quatro GitHub Actions Secrets descritos no arquivo separado `FAMILIA_FINANCAS_SIGNING_SETUP.txt`. A chave não deve ser commitada no repositório.

A versão 1.x criada anteriormente usou a chave temporária do runner do GitHub. Por isso, para instalar a primeira versão 2.0 assinada corretamente será necessário desinstalar a versão antiga uma única vez. A partir da 2.0, as atualizações usam a mesma assinatura e podem ser instaladas por cima.

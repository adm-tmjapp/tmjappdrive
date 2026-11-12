# Observabilidade do TMJ Drive

## O que é enviado

O app usa Firebase Crashlytics para:

- exceções fatais do Flutter, da plataforma e da zona principal;
- erros não fatais de rede, push, localização e notificações;
- contexto de versão, ambiente, papel do usuário e tela/fluxo;
- breadcrumbs das requisições HTTP sem corpo, senha ou token.

O Firebase Analytics recebe eventos de produto, como `login_success`,
`dashboard_load_failed`, `driver_online_failed`, `ride_accept_failed` e
`push_token_registration_failed`.

## Privacidade

Não registrar senha, JWT, token FCM, CPF completo, e-mail ou dados bancários.
O identificador do usuário enviado ao Crashlytics é pseudonimizado.

## Triagem no Firebase

1. Filtrar por versão do app e plataforma.
2. Priorizar `fatal` e erros com maior número de usuários afetados.
3. Usar `http_path`, `http_status`, `api_error_code` e `request_id` para
   correlacionar a falha com os logs da API.
4. Validar `crash-free users` e `crash-free sessions` antes de liberar uma
   nova versão.

## Política de ação

- P0: app não abre, login indisponível ou motorista não consegue operar.
- P1: fluxo crítico degradado para muitos usuários.
- P2: falha contornável ou restrita a uma funcionalidade secundária.
- P3: erro visual, log esperado ou melhoria de diagnóstico.

Alertas de regressão devem ser configurados no console do Firebase para novos
crashes, aumento de usuários afetados e queda de crash-free users.

# Plano de implementação do cadastro e login com nome de usuário

**Objetivo** Deixar cadastro e login com nome de usuário único e senha em Flutter, Spring Boot e PostgreSQL.

**Especificação** [Cadastro e login com nome de usuário](../design-cadastro-login-username.md)

**Complexidade e criticidade** C3 (10/15) pelo contrato compartilhado, mudança no banco e validação de vários cenários. R3 porque o fluxo envolve autenticação e integridade de contas.

## Backend e migração

- [x] Adaptar os testes de controlador e persistência ao contrato `username` e cobrir autenticação bem-sucedida, credenciais inválidas, duplicata e ausência de e-mail nas respostas.
- [x] Adicionar a V4 em `backend/src/main/resources/db/migration/`. Adicionar validações de formato, preenchimento de contas legadas e unicidade no banco.
- [x] Atualizar `User`, repositório, DTOs e `UserController`. Preservar BCrypt, regra de autorização, limite de tentativas e identidade usada pelo JWT.
- [x] Verificar a V4 em schema descartável no PostgreSQL isolado, incluindo usuário antigo, nome duplicado e persistência do hash e dos vínculos.

## Aplicativo Flutter

- [x] Atualizar a validação, as telas de cadastro e login, `UserService` e `UserSession` para o contrato novo. Exibir erro específico para usuário ocupado.
- [x] Atualizar os testes de serviço, formulário e sessão. Usar o transporte simulado para verificar o JSON enviado, a resposta e a navegação.

## Integração e aceite

- [x] Conferir o diff, atualizar o planejamento de qualidade e verificar a matriz de critérios da especificação.
- [x] Validar pelos executores do projeto, com PostgreSQL isolado em `game_match_test` e Flutter com `--no-pub`. Registrar resultados e limites da validação.
- [x] Obter inspeção independente de QA, revisão de código e revisão de segurança. Corrigir e verificar novamente os achados pertinentes.
- [x] Entregar as mudanças no workspace. A publicação e a aplicação da migração no Supabase dependem de um ciclo de release separado.

## Evidências

`.\test.ps1` passou com 82 testes Maven e 90 testes Flutter. A V4 foi exercitada em schemas com dados legados em `game_match_test`. O teste de integração usa PostgreSQL real para criar uma conta, reler o hash, autenticar com a senha original e validar o JWT. Os testes Flutter usam respostas simuladas para exercitar os formulários, a navegação e a sessão. A compilação Flutter Web passou. A inspeção de QA não contou com um aparelho Android.

## Ambiente local

O banco de desenvolvimento `game_match` tem tabelas e catálogo existentes, mas a inspeção de 22/11/2026 não encontrou `flyway_schema_history`. O plano de validação usa `game_match_test` e esquemas descartáveis. Para adotar a V4 no banco legado, prepare e confira uma cópia com histórico compatível antes de gravar qualquer versão no banco de desenvolvimento.

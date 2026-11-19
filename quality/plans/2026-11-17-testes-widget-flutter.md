# Cobertura de widgets Flutter — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` or `superpowers:subagent-driven-development` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cobrir os estados e ações mais importantes das telas existentes de amizades, compatibilidade e convites com testes Flutter determinísticos.

**Architecture:** Testar `FriendsScreen` e `GamesScreen` em `flutter_test`, simulando as respostas HTTP com o mecanismo já usado nos testes de serviços (`http.runWithClient` e `MockClient`). Alterar produção somente se um limite de teste necessário não puder ser exercitado pelas interfaces atuais, mantendo a menor mudança possível.

**Tech Stack:** Flutter/Dart, `flutter_test`, `http/testing.dart` já declarado no projeto.

**Spec:** `quality/test-plan.md`, `quality/test-inventory.md`, `quality/backlog.md`.

## Global Constraints

- Manter testes em `frontend/test/` e usar dependências já resolvidas.
- Executar Flutter com `flutter test --no-pub`; neste ambiente, seguir `AGENTS.md` para acesso ao cache do SDK.
- Não usar rede real nem alterar comportamento do produto apenas para facilitar testes.
- A inspeção atual não encontrou tela ou controles de administração do catálogo em `frontend/lib/`; confirmar o escopo antes de adicionar testes administrativos.

## Review Focus

- Falha HTTP durante carregamento não pode deixar spinner sem fim ou exibir dados de sucesso — cobrir em ambos os fluxos/telas aplicáveis.
- Estado vazio precisa continuar distinguível de erro — cobrir em amigos, compatibilidade e convites.
- Ações aceitas pelo usuário devem atualizar/listar o estado sem duplicar item — cobrir resposta de amizade e convite.
- Falha de envio não deve apresentar confirmação de sucesso nem remover a ação disponível — cobrir envio de solicitação e convite.
- Imagens remotas ausentes ou inválidas não devem quebrar a árvore de widgets — cobrir fallback visível onde a tela renderiza imagens.

---

### Task 1: Preparar cenários das telas sociais

**Files:**
- Create: `frontend/test/helpers/screen_test_data.dart`
- Create: `frontend/test/friends_screen_test.dart`
- Reference: `frontend/lib/features/friends/screens/friends_screen.dart`
- Reference: `frontend/lib/data/services/friendship_service.dart`, `match_service.dart`, `play_invite_service.dart`, `user_service.dart`

**Interfaces:**
- Consumes: contratos HTTP cobertos em `frontend/test/service_contract_test.dart` e sessão de usuário em `frontend/lib/core/session/user_session.dart`.
- Produces: cenários de widget isolados por `MockClient`, com respostas determinísticas por rota.

- [x] **Step 0: Acionar o Test Automation Engineer para revisar a divisão dos cenários, os estados críticos e a estratégia de mocks antes de ampliar a suíte.** Não substituir os testes escritos pelo agente implementador.
- [x] **Step 1: Criar helpers de fixture e de HTTP simulado para usuário, amizade, compatibilidade e convite.** Não compartilhar estado global entre testes; limpar a sessão ao final de cada caso.
- [x] **Step 2: Cobrir carregamento, erro inicial e conteúdo vazio.** Asserir spinner durante a espera e mensagens/controles observáveis após a resposta.
- [x] **Step 3: Cobrir busca de usuários e envio de solicitação.** Verificar filtro por texto, feedback de sucesso e feedback de falha sem sucesso falso.
- [x] **Step 4: Cobrir aceitar e recusar solicitação pendente.** Verificar chamada esperada e atualização após recarga.
- [x] **Step 5: Cobrir seleção de amigo, compatibilidade vazia/com resultados e envio de convite.** Verificar carregamento, confirmação de sucesso e erro de envio sem sucesso falso.
- [x] **Step 6: Executar `flutter test --no-pub test/friends_screen_test.dart` em `frontend/` e corrigir os cenários até passarem.**

### Task 2: Cobrir compatibilidade e convites na tela de jogos

**Files:**
- Modify: `frontend/test/games_screen_test.dart` (existing header test is retained)
- Reference: `frontend/test/helpers/screen_test_data.dart`
- Reference: `frontend/lib/features/games/screens/games_screen.dart`
- Reference: `frontend/lib/data/services/match_service.dart`, `play_invite_service.dart`

**Interfaces:**
- Consumes: `MockClient`/fixtures definidos na Task 1, sem dependência em serviços reais.
- Produces: cobertura dos estados das abas Compatíveis e Convites.

- [x] **Step 1: Cobrir carregamento, falha e lista vazia de jogos compatíveis.**
- [x] **Step 2: Cobrir seleção de jogo e apresentação de amigos interessados, incluindo ausência de interessados.**
- [x] **Step 3: Cobrir abas de convites recebidos/enviados vazias e preenchidas.**
- [x] **Step 4: Cobrir aceitar/recusar convite e estados de erro das ações, incluindo falha no envio de convite.**
- [x] **Step 5: Cobrir fallback de imagem para URL inválida nos elementos exercitados.**
- [x] **Step 6: Executar `flutter test --no-pub test/games_screen_test.dart` em `frontend/` e corrigir os cenários até passarem.**

### Task 3: Resolver a lacuna de tela administrativa

**Files:**
- Inspect: `frontend/lib/features/games/screens/games_screen.dart`
- Inspect: `frontend/lib/data/services/game_service.dart`
- Update if a screen/flow exists: `frontend/test/` e este plano

**Interfaces:**
- Consumes: decisão do responsável pelo produto sobre o fluxo administrativo Flutter esperado.
- Produces: registro do fluxo existente e casos de widget correspondentes, ou pendência explícita de produto sem cobertura fictícia.

- [x] **Step 1: Confirmar se existe interface administrativa de catálogo no app e identificar suas ações observáveis.** A inspeção encontrou apenas fluxos de jogos compatíveis e convites em `GamesScreen`; nenhuma tela/admin Flutter está presente.
- [x] **Step 2: Se a interface existir, adicionar testes de lista/carregamento/erro/vazio e ações administrativas suportadas, sem duplicar os testes backend já existentes.** Não há interface administrativa; não criar tela neste plano e manter a lacuna no backlog para decisão de produto.
- [x] **Step 3: Executar os testes administrativos aplicáveis ou registrar claramente que não há fluxo de interface a testar.** Sem interface para validar; a pendência de produto permanece explícita.

### Task 4: Integrar a nova cobertura

**Files:**
- Modify: `quality/test-inventory.md`
- Modify: `quality/backlog.md`
- Verify: `frontend/test/`

- [x] **Step 1: Executar `.\test.ps1` e registrar os resultados observados: 60 testes Maven e 83 Flutter passaram em 2026-11-18.**
- [x] **Step 2: Atualizar inventário e marcar no backlog apenas os fluxos concluídos e verificados.**
- [x] **Step 3: Revisar diff, requisitos e resultado dos testes com o Code Reviewer.** Revisão final aprovada, sem achados pendentes; inventário conferido (11 casos FriendsScreen, 14 GamesScreen, 83 Flutter no total). A decisão de produto sobre eventual interface administrativa continua registrada no backlog.

# QA manual de catálogo e isolamento — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` or `superpowers:subagent-driven-development` to execute this checklist task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Completar a validação manual dos fluxos de catálogo/admin e isolamento entre contas, documentando evidência reproduzível sem expor credenciais.

**Architecture:** QA percorre o cliente e as rotas já existentes com contas descartáveis e banco isolado. O QA não altera o produto; dúvidas sobre ausência de tela administrativa são registradas como lacuna de escopo, não como aprovação.

**Tech Stack:** Flutter app, backend Spring Boot e PostgreSQL `game_match_test`; a ferramenta de inspeção HTTP será escolhida entre as disponíveis no ambiente quando o QA começar, sem presumir instalação ou dependência nova.

**Spec:** `quality/test-plan.md`, `quality/test-inventory.md`, `quality/reports/2026-10-25-suite-completa.md`.

## Global Constraints

- Usar somente `game_match_test` e contas/jogos descartáveis.
- Não registrar senhas, tokens, segredos ou dados pessoais nos relatórios.
- QA registra passos, resultado esperado/observado e evidência somente para falhas, riscos relevantes ou decisões.
- A cobertura backend de autorização já tem testes MockMvc; QA manual complementa, não substitui, essa evidência.
- Não afirmar que há fluxo administrativo de interface até confirmá-lo no app.

## Review Focus

- O ambiente e as contas usados precisam ser identificados sem registrar segredos.
- A interface/rota deve corresponder a uma ação administrativa real, não somente a uma API protegida.
- Usuário comum não pode obter ações ou dados exclusivos de administrador.
- Troca de conta deve limpar a sessão anterior; validar leitura e escrita entre contas.
- Evidências precisam permitir repetir cada falha sem depender de dados efêmeros não descritos.

---

### Task 1: Preparar dados e ambiente de QA

**Files:**
- Reference: `quality/test-plan.md`
- Reference: `quality/reports/2026-10-25-suite-completa.md`
- Modify only if a material finding exists: `quality/reports/`

- [x] **Step 1: Confirmar backend, frontend e PostgreSQL ativos, com URL do backend apontada a `game_match_test`.** Ambos responderam localmente; o log Spring indicou PostgreSQL 18 e `game_match_test`.
- [x] **Step 2: Preparar contas descartáveis de usuário comum e administrador e dados mínimos de catálogo.** Duas contas temporárias e um jogo foram criados no banco de teste e removidos ao final.
- [x] **Step 3: Escolher uma ferramenta HTTP já disponível, se for necessária para verificar tentativas de acesso cruzado; não instalar dependências para esta rodada.** Usado `Invoke-WebRequest` do PowerShell e `psql` local.
- [x] **Step 4: Confirmar que o app apresenta uma interface administrativa.** O usuário confirmou que não há interface administrativa; a inspeção de `MainNavigation` mostra apenas Avaliar, Amigos e Jogos. O QA visual administrativo foi declarado indisponível.

### Task 2: Percorrer catálogo e ações administrativas disponíveis

**Files:**
- Inspect: `frontend/lib/features/games/screens/games_screen.dart`
- Inspect: rotas de catálogo/importação em `backend/src/main/java/com/gamematch/backend/controller/GameController.java`
- Record material findings only: `quality/reports/`

- [x] **Step 1: Com usuário comum, percorrer a consulta de jogos disponível e registrar carregamento, lista vazia, erro de backend e resultado com dados.** Flutter web mostrou o carregamento durante atraso temporário de `GET /games` e depois carregou os jogos fixture. Após avaliar os três jogos, mostrou “Você avaliou todos os jogos”. Offline, a aba Jogos exibiu erro, mas a aba Avaliar mostrou incorretamente “Você já avaliou todos os jogos disponíveis”. Defeito P2 registrado em `quality/reports/2026-11-18-catalogo-offline-mostrado-como-vazio.md`.
- [x] **Step 2: Com administrador, percorrer cada ação administrativa de interface existente e comparar resultado com o esperado.** Não aplicável: não existe interface administrativa. A criação administrativa disponível por API `POST /games` retornou 200; não foram chamadas rotas IGDB externas.
- [x] **Step 3: Com usuário comum, tentar acessar a mesma ação; confirmar bloqueio observável sem escrita indevida.** `POST /games` retornou 403; consulta posterior confirmou que o jogo negado não persistiu.
- [x] **Step 4: Se não existir interface administrativa, não simular uma aprovação de UI; registrar a lacuna e os endpoints que permanecem cobertos por testes automatizados.** Testes MockMvc existentes cobrem as permissões de criação/importação/admin; QA HTTP desta rodada cobriu criação manual.

### Task 3: Verificar isolamento entre contas

**Files:**
- Inspect: telas autenticadas e `UserSession`
- Reference: `backend/src/test/java/com/gamematch/backend/config/AuthorizationBoundaryTest.java`
- Record material findings only: `quality/reports/`

- [x] **Step 1: Criar dados privados distintos para duas contas descartáveis e confirmar que cada conta vê apenas os próprios dados e os compartilhamentos previstos.** Leituras cruzadas de dados privados foram negadas na rodada anterior. Nesta rodada, duas contas descartáveis criadas em `game_match_test` autenticaram, criaram interesses LIKE/FAVORITE, aceitaram amizade e receberam o jogo compartilhado pelos endpoints de comparação, jogos compatíveis e amigos interessados. Respostas: amizade `ACCEPTED`, 1 jogo compatível e 1 amigo interessado; dados removidos e limpeza confirmada.
- [x] **Step 2: Sair da conta A, autenticar a conta B e confirmar que a sessão e as telas não preservam dados privados de A.** Logout da conta A retornou ao login sem o nome de A; login B exibiu o nome de B e voltou a listar um jogo que A já havia avaliado, demonstrando que as avaliações não foram herdadas entre sessões. Com amizade aceita e avaliação compartilhada, B também viu o jogo compatível e A como amiga interessada.
- [x] **Step 3: Tentar ações cruzadas de leitura e escrita nos fluxos disponíveis; verificar resposta de autorização e ausência de alteração.** Leituras de avaliação, amizade, compatibilidade e convite retornaram 403; atualização da avaliação alheia retornou 403 e a conta dona confirmou que o valor permaneceu intacto.
- [x] **Step 4: Limpar os dados descartáveis ao final e confirmar que o banco de desenvolvimento permaneceu intocado.** Uma transação de limpeza protegida por `current_database() = 'game_match_test'` removeu somente os IDs/itens de QA. Consulta posterior confirmou 0 itens `QA_TEMP_`/`QA_DENIED_` e 0 contas QA da rodada; backend nunca apontou para `game_match`.

### Task 4: Consolidar evidências e encaminhar achados

**Files:**
- Update only if needed: `quality/test-inventory.md`
- Create report only for findings, risks or decisions: `quality/reports/`

- [x] **Step 1: Para cada achado, registrar pré-condição, passos, esperado, observado e evidência sem segredo.** A falha de catálogo offline foi registrada com passos reproduzíveis, esperado e observado; a ausência da interface administrativa continua confirmada.
- [x] **Step 2: Registrar relatórios somente para falhas, riscos ou decisões relevantes; atualizar inventário com o escopo executado.** O achado P2 foi documentado e o inventário atualizado com os fluxos visuais realizados.
- [x] **Step 3: Revisar conclusões e evidências com o Code Reviewer; QA permanece responsável por não alterar o produto.** Revisão independente aprovada; o achado P2 foi encaminhado ao backlog como correção pendente.

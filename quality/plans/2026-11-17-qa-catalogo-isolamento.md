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

- [ ] **Step 1: Confirmar backend, frontend e PostgreSQL ativos, com URL do backend apontada a `game_match_test`.**
- [ ] **Step 2: Preparar contas descartáveis de usuário comum e administrador e dados mínimos de catálogo.**
- [ ] **Step 3: Escolher uma ferramenta HTTP já disponível, se for necessária para verificar tentativas de acesso cruzado; não instalar dependências para esta rodada.**
- [ ] **Step 4: Confirmar que o app apresenta uma interface administrativa.** Se não houver, limitar QA de interface às telas existentes e registrar o fluxo administrativo como indisponível para validação visual.

### Task 2: Percorrer catálogo e ações administrativas disponíveis

**Files:**
- Inspect: `frontend/lib/features/games/screens/games_screen.dart`
- Inspect: rotas de catálogo/importação em `backend/src/main/java/com/gamematch/backend/controller/GameController.java`
- Record material findings only: `quality/reports/`

- [ ] **Step 1: Com usuário comum, percorrer a consulta de jogos disponível e registrar carregamento, lista vazia, erro de backend e resultado com dados.**
- [ ] **Step 2: Com administrador, percorrer cada ação administrativa de interface existente e comparar resultado com o esperado.**
- [ ] **Step 3: Com usuário comum, tentar acessar a mesma ação; confirmar bloqueio observável sem escrita indevida.**
- [ ] **Step 4: Se não existir interface administrativa, não simular uma aprovação de UI; registrar a lacuna e os endpoints que permanecem cobertos por testes automatizados.**

### Task 3: Verificar isolamento entre contas

**Files:**
- Inspect: telas autenticadas e `UserSession`
- Reference: `backend/src/test/java/com/gamematch/backend/config/AuthorizationBoundaryTest.java`
- Record material findings only: `quality/reports/`

- [ ] **Step 1: Criar dados privados distintos para duas contas descartáveis e confirmar que cada conta vê apenas os próprios dados e os compartilhamentos previstos.**
- [ ] **Step 2: Sair da conta A, autenticar a conta B e confirmar que a sessão e as telas não preservam dados privados de A.**
- [ ] **Step 3: Tentar ações cruzadas de leitura e escrita nos fluxos disponíveis; verificar resposta de autorização e ausência de alteração.**
- [ ] **Step 4: Limpar os dados descartáveis ao final e confirmar que o banco de desenvolvimento permaneceu intocado.**

### Task 4: Consolidar evidências e encaminhar achados

**Files:**
- Update only if needed: `quality/test-inventory.md`
- Create report only for findings, risks or decisions: `quality/reports/`

- [ ] **Step 1: Para cada achado, registrar pré-condição, passos, esperado, observado e evidência sem segredo.**
- [ ] **Step 2: Não criar relatório de rodada sem achado relevante; atualizar inventário somente com o escopo realmente validado.**
- [ ] **Step 3: Revisar conclusões e evidências com o Code Reviewer; QA permanece responsável por não alterar o produto.**

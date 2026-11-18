# Testes de integração PostgreSQL — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` or `superpowers:subagent-driven-development` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Verificar que migrações e fluxos principais persistem e recuperam dados corretamente em PostgreSQL real, sem tocar no banco de desenvolvimento.

**Architecture:** Acrescentar testes de integração no backend, aproveitando Spring Boot, JPA e Flyway existentes. Primeiro estabelecer provisionamento, dados de teste e limpeza isolados; não presumir Testcontainers, pois ele não foi encontrado nas dependências atuais.

**Tech Stack:** Java 21, Spring Boot, JUnit Jupiter, Spring Data JPA, Flyway, PostgreSQL e Maven Wrapper.

**Spec:** `quality/test-plan.md`, `quality/test-inventory.md`, `quality/backlog.md`.

## Global Constraints

- O único destino permitido é `jdbc:postgresql://localhost:5432/game_match_test`.
- Nunca apagar, truncar ou migrar `game_match`.
- Manter Flyway como fonte do esquema; Hibernate permanece em `ddl-auto=validate`.
- Não adicionar dependência de infraestrutura até confirmar que o PostgreSQL isolado disponível não atende ao teste repetível.
- Mockar integrações externas como IGDB; o objetivo é persistência real, não chamadas externas.

## Review Focus

- Configuração ausente ou incorreta não pode direcionar o teste para `game_match` — falhar antes de qualquer escrita.
- Reexecução não pode depender de dados deixados por uma rodada anterior — testar limpeza/isolation.
- Restrições e chaves estrangeiras do esquema real devem rejeitar dados inválidos — cobrir constraints relevantes.
- Persistência tem que ser validada após nova leitura/transação — evitar asserções somente sobre objetos em memória.
- Falha de um caso não pode deixar dados que contaminem casos seguintes — usar limpeza previsível ou rollback onde aplicável.

---

### Task 1: Estabelecer uma execução isolada e repetível

**Files:**
- Create: `backend/src/test/java/com/gamematch/backend/integration/` (classes de teste após validar a estratégia)
- Inspect: `backend/src/main/resources/application.properties`
- Inspect: `test.ps1`
- Modify if needed: `test.ps1`, configuração de teste do backend e `quality/test-plan.md`

**Interfaces:**
- Consumes: PostgreSQL local e variável `SPRING_DATASOURCE_URL` já usada pelo comando agregado.
- Produces: preflight que comprova o destino `game_match_test` e uma estratégia previsível de dados/limpeza.

- [ ] **Step 0: Acionar o Test Automation Engineer para revisar a estratégia de integração, isolamento e cobertura antes de alterar a estrutura de testes.**
- [ ] **Step 1: Confirmar como o banco `game_match_test` é criado no ambiente e se pode ser recriado com segurança sem afetar dados de desenvolvimento.**
- [ ] **Step 2: Definir preflight fail-closed: abortar antes de escrever se a URL não for exatamente o banco de teste esperado.**
- [ ] **Step 3: Definir limpeza ou rollback compatível com Flyway e com as transações do Spring; não truncar dados fora do banco isolado.**
- [ ] **Step 4: Executar uma prova mínima da estratégia e documentar setup, comando e limpeza.**

### Task 2: Validar esquema e persistência das entidades

**Files:**
- Create: testes de integração em `backend/src/test/java/com/gamematch/backend/integration/`
- Reference: `backend/src/main/resources/db/migration/V1__create_initial_schema.sql`
- Reference: `backend/src/main/resources/db/migration/V2__enforce_unique_user_email.sql`
- Reference: `backend/src/main/java/com/gamematch/backend/model/` e `repository/`

- [ ] **Step 1: Escrever teste de inicialização que aplique as migrações no banco de teste e confirme validação do esquema JPA.**
- [ ] **Step 2: Cobrir persistência, leitura e restrição de email único no PostgreSQL para usuários.**
- [ ] **Step 3: Cobrir relações e chaves estrangeiras de jogos, avaliações, amizades e convites com fixture mínima.**
- [ ] **Step 4: Reexecutar os testes direcionados e confirmar independência da ordem dos casos.**

### Task 3: Validar fluxos funcionais com dados persistidos

**Files:**
- Create/Modify: testes de integração em `backend/src/test/java/com/gamematch/backend/integration/`
- Reference: `RatingController`, `FriendshipController`, `MatchController`, `PlayInviteController` e respectivos repositórios

- [ ] **Step 1: Cobrir criação/atualização de avaliação e sua leitura em nova transação.**
- [ ] **Step 2: Cobrir ciclo de amizade pendente → aceita e confirmar persistência/releitura.**
- [ ] **Step 3: Cobrir criação e transição de estado de convite vinculado a amizade aceita.**
- [ ] **Step 4: Confirmar que resultados de compatibilidade usam as avaliações persistidas conforme as regras existentes de LIKE/FAVORITE.**
- [ ] **Step 5: Executar casos específicos e suíte Maven completa com o banco isolado.**

### Task 4: Fechar documentação e revisão

**Files:**
- Modify: `quality/test-inventory.md`
- Modify: `quality/test-plan.md`
- Modify: `quality/backlog.md`

- [ ] **Step 1: Registrar setup, comandos, fluxos cobertos e resultado real; identificar banco explicitamente como `game_match_test`.**
- [ ] **Step 2: Marcar como concluídas somente as tarefas com evidência repetível.**
- [ ] **Step 3: Revisar diff, isolamento do banco e resultados com o Code Reviewer.**

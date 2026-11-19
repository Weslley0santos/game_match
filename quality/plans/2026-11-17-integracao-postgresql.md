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

- [x] **Step 0: Acionar o Test Automation Engineer para revisar a estratégia de integração, isolamento e cobertura antes de alterar a estrutura de testes.** Recomendou PostgreSQL real, guarda antes de Flyway, rollback transacional, sem limpeza destrutiva e chamadas IGDB ausentes.
- [x] **Step 1: Confirmar como o banco `game_match_test` é criado no ambiente e se pode ser recriado com segurança sem afetar dados de desenvolvimento.** O banco já existe localmente; não foi recriado nem truncado.
- [x] **Step 2: Definir preflight fail-closed: abortar antes de escrever se a URL não for exatamente o banco de teste esperado.** `PostgresTestDatabaseGuard` exige a URL integral; uma inicialização configurada com `game_match` foi rejeitada antes de Flyway.
- [x] **Step 3: Definir limpeza ou rollback compatível com Flyway e com as transações do Spring; não truncar dados fora do banco isolado.** Cada teste de persistência usa `@Transactional` e rollback; Flyway mantém o schema. Nenhum `TRUNCATE`, `DROP` ou recriação.
- [x] **Step 4: Executar uma prova mínima da estratégia e documentar setup, comando e limpeza.** `test.ps1` configura a URL alvo; testes PostgreSQL direcionados passaram duas vezes.

### Task 2: Validar esquema e persistência das entidades

**Files:**
- Create: testes de integração em `backend/src/test/java/com/gamematch/backend/integration/`
- Reference: `backend/src/main/resources/db/migration/V1__create_initial_schema.sql`
- Reference: `backend/src/main/resources/db/migration/V2__enforce_unique_user_email.sql`
- Reference: `backend/src/main/java/com/gamematch/backend/model/` e `repository/`

- [x] **Step 1: Escrever teste de inicialização que aplique as migrações no banco de teste e confirme validação do esquema JPA.** Flyway validou V1/V2 e Hibernate iniciou com `ddl-auto=validate`.
- [x] **Step 2: Cobrir persistência, leitura e restrição de email único no PostgreSQL para usuários.** Releitura após `flush/clear` e índice case-insensitive confirmados.
- [x] **Step 3: Cobrir relações e chaves estrangeiras de jogos, avaliações, amizades e convites com fixture mínima.** Relações JPA e FKs existentes de plataformas, amizades e convites cobertas. `ratings` não tem FKs declaradas em V1/V2; persistência foi coberta, e a lacuna de integridade ficou registrada no backlog.
- [x] **Step 4: Reexecutar os testes direcionados e confirmar independência da ordem dos casos.** 10 testes direcionados passaram em duas execuções consecutivas; fixtures usam emails únicos e rollback.

### Task 3: Validar fluxos funcionais com dados persistidos

**Files:**
- Create/Modify: testes de integração em `backend/src/test/java/com/gamematch/backend/integration/`
- Reference: `RatingController`, `FriendshipController`, `MatchController`, `PlayInviteController` e respectivos repositórios

- [x] **Step 1: Cobrir criação/atualização de avaliação e sua releitura no PostgreSQL após limpar o persistence context.** A leitura ocorre no mesmo caso transacional, que sofre rollback ao final para evitar dados residuais.
- [x] **Step 2: Cobrir ciclo de amizade pendente → aceita e confirmar persistência/releitura.**
- [x] **Step 3: Cobrir criação e transição de estado de convite vinculado a amizade aceita.**
- [x] **Step 4: Confirmar que resultados de compatibilidade usam as avaliações persistidas conforme as regras existentes de LIKE/FAVORITE.** Também confirma exclusão de `DISLIKE`.
- [x] **Step 5: Executar casos específicos e suíte Maven completa com o banco isolado.** 10 direcionados passaram duas vezes; Maven 70/70 e Flutter 83/83 no comando agregado.

### Task 4: Fechar documentação e revisão

**Files:**
- Modify: `quality/test-inventory.md`
- Modify: `quality/test-plan.md`
- Modify: `quality/backlog.md`

- [x] **Step 1: Registrar setup, comandos, fluxos cobertos e resultado real; identificar banco explicitamente como `game_match_test`.**
- [x] **Step 2: Marcar como concluídas somente as tarefas com evidência repetível.**
- [x] **Step 3: Revisar diff, isolamento do banco e resultados com o Code Reviewer.** Revisão final aprovou os critérios e a descrição ajustada da leitura após `flush/clear` na mesma transação; sem achados pendentes.

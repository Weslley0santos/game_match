# Plano de integridade referencial das avaliações

**Estado** — Implementado e aplicado em `game_match_test` em 22/11/2026. A aplicação em outros ambientes continua pendente. Classificação C3/R3 pela mudança de esquema, contrato HTTP e integridade de dados existentes.

**Objetivo** — Impedir que `ratings.user_id` e `ratings.game_id` referenciem usuários ou jogos inexistentes, preservando as avaliações válidas e os fluxos de avaliação e compatibilidade.

**Escopo** — PostgreSQL e Flyway do backend. Em V1, `ratings` guarda IDs simples e aceita `NULL` nas duas colunas. A proposta inicial é uma nova migração versionada com `ON DELETE NO ACTION`, para que excluir um usuário ou jogo referenciado não apague avaliações automaticamente. A obrigatoriedade das colunas (`NOT NULL`), a unicidade do par usuário/jogo e o fluxo de exclusão de conta precisam de decisões próprias.

## 1. Diagnosticar antes de alterar o esquema

- [x] Confirmar o banco e o esquema alvo, o histórico Flyway e o volume de `ratings` em `game_match_test`, com a guarda de banco dos testes. Documentar somente contagens, sem IDs ou dados pessoais.
- [x] Contar separadamente referências órfãs e campos nulos. Uma avaliação pode aparecer em mais de uma contagem.

```sql
SELECT
    count(*) AS total_ratings,
    count(*) FILTER (WHERE r.user_id IS NULL) AS null_user_ids,
    count(*) FILTER (WHERE r.game_id IS NULL) AS null_game_ids,
    count(*) FILTER (WHERE r.user_id IS NOT NULL AND u.id IS NULL) AS orphan_user_ids,
    count(*) FILTER (WHERE r.game_id IS NOT NULL AND g.id IS NULL) AS orphan_game_ids
FROM ratings AS r
LEFT JOIN users AS u ON u.id = r.user_id
LEFT JOIN games AS g ON g.id = r.game_id;
```

- [ ] Se houver órfãos, interromper a implantação e definir com o responsável como recuperar a referência ou tratar cada conjunto afetado. Qualquer correção destrutiva exige autorização, backup restaurável e validação em cópia isolada. Repetir a contagem após o tratamento. Registrar campos nulos como lacuna separada, pois as chaves estrangeiras não os rejeitam.

## 2. Preparar migração e proteger o contrato da API

- [x] Verificar a rejeição por cada chave, a recarga de avaliação válida, a compatibilidade e o bloqueio da exclusão de usuário ou jogo referenciado em `PostgresPersistenceIntegrationTest`. Cada escrita que falha roda em um caso com rollback próprio.
- [x] Criar `backend/src/main/resources/db/migration/V3__add_ratings_foreign_keys.sql` com `fk_ratings_user` e `fk_ratings_game`. Usar `ON DELETE NO ACTION` e preservar V1/V2.
- [x] Exercitar `POST /ratings` com jogo inexistente (`404`), usuário do token inexistente (`401`) e criação/atualização válidas. Preservar a identificação do dono pelo JWT, os bloqueios de acesso alheio e a propagação de falhas de integridade alheias às duas chaves.
- [x] Executar os testes de `PostgresRatingMigrationTest`, `PostgresPersistenceIntegrationTest`, `RatingControllerTest` e `AuthorizationBoundaryTest`, com o Maven apontado para `jdbc:postgresql://localhost:5432/game_match_test`. Executar `./test.ps1` na raiz e atualizar o inventário.

## 3. Ensaiar atualização, falha e recuperação

- [x] Ensaiar V1–V3 em esquema vazio e V2→V3 em esquema de teste com dados existentes. Confirmar as restrições validadas e a preservação dos registros. No ensaio com órfão, confirmar rollback integral e reexecução depois da correção do dado descartável.
- [ ] Medir aquisição de locks e duração em uma cópia representativa. Caso a janela de bloqueio das escritas seja inadequada, planejar duas etapas com commits separados, uma para `ADD CONSTRAINT ... NOT VALID` e outra para `VALIDATE CONSTRAINT`. O trabalho encerra com ambas as chaves validadas. [PostgreSQL — ALTER TABLE](https://www.postgresql.org/docs/18/sql-altertable.html#SQL-ALTERTABLE-NOTES)
- [ ] Definir responsáveis pela aplicação e recuperação. Em falha dentro da migração transacional, verificar o rollback e a consistência do histórico antes de tentar novamente. Após uma aplicação bem-sucedida, ensaiar uma migração compensatória que remova somente as duas chaves, caso o rollback seja necessário. Qualquer restauração de dados deve usar o procedimento de backup validado e considerar escritas posteriores ao backup.
- [x] Obter revisão independente de código e de segurança do SQL, do contrato HTTP e das evidências de falha e recuperação. Ambas concluídas sem achados no escopo.
- [ ] Antes de aplicar em ambiente compartilhado, executar a auditoria nesse ambiente e confirmar backup restaurável, janela e aprovação do responsável.

## Execução em 22/11/2026

- `game_match_test/public` estava na V2 com quatro avaliações, zero referências nulas e zero órfãs. Após a aplicação da V3, as duas chaves estavam validadas, as quatro avaliações permaneceram e a contagem de nulos e órfãos continuou zero. O índice existente em `ratings` era o da chave primária. A necessidade de índices adicionais e a duração dos bloqueios em uma base representativa ainda precisam ser avaliadas.
- Foram usados esquemas descartáveis para os ensaios Flyway em base vazia e em base V2. A V3 preservou as avaliações existentes, inclusive onde havia um campo nulo. Com um órfão, a V3 falhou, o histórico permaneceu na V2, nenhuma chave ficou aplicada e os dados foram preservados. Após restaurar a referência na base descartável, a V3 pôde ser reaplicada sem `repair`. Nenhum esquema descartável permaneceu após os testes.
- O `POST /ratings` responde `404` se o jogo não existe e `401` se a referência ao usuário do token falha. A tradução usa o código e o nome da restrição fornecidos pelo driver PostgreSQL já presente, independentemente do idioma da mensagem. O QA verificou os resultados via MockMvc e PostgreSQL, sem requisições a um servidor HTTP em execução.
- A execução direcionada passou com 36 testes. `./test.ps1` passou com 80 testes Maven e 86 Flutter. O banco de desenvolvimento e a produção não foram usados.
- Para reverter uma aplicação bem-sucedida, preparar uma nova migração que remova `fk_ratings_user` e `fk_ratings_game` com `ALTER TABLE ratings DROP CONSTRAINT ...`. Revisar o SQL e ensaiar a migração compensatória em cópia isolada antes de usá-la em ambiente compartilhado.

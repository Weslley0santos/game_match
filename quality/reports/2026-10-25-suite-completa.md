# Execução completa das suítes — 2026-10-25

## Comandos e resultados

| Comando | Resultado | Evidência |
| --- | --- | --- |
| `mvn test` em `backend/` | **Falhou** | 58 testes: 0 falhas de asserção, 1 erro, 0 ignorados. Os outros 57 testes passaram. O erro foi `BackendApplicationTests.contextLoads`. |
| `flutter test --no-pub --verbose` em `frontend/` | **Passou** | 14 testes passaram, código de saída 0. Executado com permissão para usar o cache do SDK Flutter, conforme `AGENTS.md`. |
| Maven direcionado aos fluxos restantes em `backend/` | **Passou** | 41 testes: 0 falhas, 0 erros, 0 ignorados. Inclui avaliações, amizades, compatibilidade, convites, catálogo e isolamento. |

## Falha do backend

Mensagem relevante do Maven/Flyway:

```text
Found non-empty schema(s) "public" but no schema history table. Use baseline() or set baselineOnMigrate to true to initialize the schema history table.
```

O erro ocorreu ao carregar o contexto Spring e inicializar `flywayInitializer`. Não foram executados baseline ou migrações manuais, nem alterados arquivos ou dependências. O teste depende de um PostgreSQL com schema compatível e histórico Flyway inicializado; a integração completa permanece sem aprovação até a execução em banco isolado apropriado.

## Limite

A suíte Flutter passou integralmente. A suíte backend executou todos os testes, mas não passou integralmente devido ao erro ambiental/configuracional acima. Não declarar o backend validado como um todo até corrigir a configuração em ambiente isolado e repetir `mvn test`.

## QA dos fluxos restantes

QA tentou percorrer avaliações, amizades, compatibilidade, convites, catálogo/admin e isolamento por usuário. Todos ficaram **bloqueados**: não havia frontend/API local acessível (nenhuma porta em estado `Listen`) nem contas de teste isoladas. Os testes direcionados 41/41 são evidência automatizada de backend, mas não substituem a validação desses fluxos pela interface. A validação manual deve ser repetida em ambiente de teste com serviços e contas isolados.

## Revisão independente

Code Reviewer aprovou o escopo dos testes direcionados e não identificou omissão crítica nos critérios atribuídos. Confirmou que a fixture de avaliações duplicadas não viola constraint de unicidade existente: entidade e migração inicial não definem essa constraint, e o controller consulta todos os registros do usuário/jogo. Permanecem os limites de integração real com PostgreSQL/IGDB e de fluxo Flutter, além do erro Flyway na suíte completa.

## Reexecução com PostgreSQL isolado — 2026-10-25

Foi criado o banco local vazio `game_match_test`, pertencente ao usuário `postgres`. A URL de teste foi acrescentada ao `.env` como comentário; a URL ativa para desenvolvimento permaneceu `jdbc:postgresql://localhost:5432/game_match`.

Com `SPRING_DATASOURCE_URL` sobrescrita apenas no processo Maven para `jdbc:postgresql://localhost:5432/game_match_test`, `BackendApplicationTests` passou (1/1) e o Flyway aplicou as migrações V1 e V2. A verificação posterior encontrou ambas registradas com sucesso e 7 tabelas no schema `public`.

A suíte completa `mvn test`, executada com a mesma sobrescrita temporária, passou: 58 testes, 0 falhas, 0 erros, `BUILD SUCCESS`. Portanto, a falha anterior de contexto foi resolvida ao usar o banco de testes isolado; ela não deve ser resolvida fazendo baseline ou alterando o banco local de desenvolvimento.

## QA manual pela interface — 2026-10-25

A segunda tentativa ocorreu com Flutter Web em `http://localhost:3000` e API em `http://localhost:8080`, enquanto o backend estava conectado a `game_match_test`. O `.env` foi restaurado ao valor de desenvolvimento após iniciar os serviços. QA usou duas contas descartáveis e três jogos sintéticos, todos criados somente no banco de teste.

| Fluxo | Resultado | Evidência observada |
| --- | --- | --- |
| Cadastro e login | **Passou** | Duas contas foram cadastradas pela interface; ambas autenticaram e chegaram à área principal. `POST /users` e `POST /users/login` retornaram 200. |
| Avaliações | **Passou** | Ações “Gostei”, “Não gostei” e “Quero jogar” avançaram os cards e a última mostrou “Você avaliou todos os jogos”. `GET /games`, `GET /ratings/user/2` e as gravações de avaliação retornaram 200. |
| Amizades | **Passou** | Uma conta enviou solicitação; a outra aceitou pela tela. A interface mostrou os toasts de sucesso e `PUT /friendships/1/accept` retornou 200. |
| Compatibilidade | **Passou** | Após ambas gostarem de Hollow Knight, a tela mostrou Buddy com um jogo em comum e exibiu o jogo como “Tem interesse”; `GET /matches/1/2` retornou 200. |
| Convites | **Passou** | O convite foi enviado pelo detalhe do jogo, recebido e aceito pela segunda conta; a interface atualizou para “Status: Aceito”. `POST /play-invites` e `PUT /play-invites/1/accept` retornaram 200. |
| Catálogo/admin | **Parcial / bloqueado** | A lista de jogos foi lida na interface, mas pesquisa/importação administrativa não foi exercitada: não havia conta admin de teste nem fluxo administrativo visível. |
| Isolamento entre usuários | **Parcial / não confirmado** | A avaliação exibida foi independente entre contas. A interface não ofereceu caminho para tentar ler ou alterar diretamente dados alheios; a autorização cruzada foi coberta separadamente por testes automatizados, não por esta sessão manual. |

As telas vazias de amigos, solicitações, convites e compatibilidade também foram observadas antes de criar relações/dados. Nenhuma falha funcional foi observada nos fluxos exercitados. Os dados descartáveis permanecem em `game_match_test`; o frontend e backend de QA foram encerrados. O serviço PostgreSQL permaneceu ativo para os bancos locais.

## Reexecução após os testes das regras de descoberta e compartilhamento — 2026-10-25

O comando `.\test.ps1` passou após a inclusão dos testes de política: Maven, 60 testes, 0 falhas e 0 erros no banco isolado `game_match_test`; Flutter, 14 testes, todos aprovados. A URL ativa do `.env` de desenvolvimento permaneceu em `game_match`.

# Inventário e diagnóstico dos testes

## Como interpretar este inventário

- **Fato observado:** aparece em arquivo, configuração ou documentação inspecionada.
- **Não confirmado:** não foi possível concluir apenas pela inspeção; não significa necessariamente que não exista fora do repositório ou em ambiente externo.
- Última execução agregada registrada: em 2026-11-22, `.\test.ps1` passou com 80 testes Maven e 86 Flutter. O Maven apontou para o PostgreSQL isolado `game_match_test`.

## Tecnologias e organização

| Área | Fatos observados |
| --- | --- |
| Frontend | Flutter/Dart; aplicação em `frontend/lib/`; testes em `frontend/test/`; dependências de desenvolvimento `flutter_test` e `flutter_lints` em `frontend/pubspec.yaml`. |
| Backend | Java 21 e Spring Boot 4.0.6 em `backend/pom.xml`; testes em `backend/src/test/java/`; dependências de teste Spring Data JPA e WebMVC. Os testes usam JUnit Jupiter, Mockito, AssertJ e MockMvc. |
| Persistência | PostgreSQL e Flyway configurados no backend, com migrações `V1` a `V3`. |
| Ambiente local | `start-dev.ps1` inicia backend e Flutter Web e verifica disponibilidade HTTP; não executa as suítes de teste. `docker-compose.yml` declara PostgreSQL e backend. |

## Testes encontrados

### Frontend — 9 arquivos de teste, 86 testes

| Arquivo | Casos observados |
| --- | --- |
| `frontend/test/game_card_test.dart` | 2 casos: URL de capa IGDB convertida para resolução alta e imagem configurada com `BoxFit.contain`. |
| `frontend/test/games_screen_test.dart` | 14 casos: cabeçalho; estados de compatibilidade e convites; amigos interessados; aceitar/recusar e enviar convites; fallback da capa. |
| `frontend/test/friends_screen_test.dart` | 11 casos: carregamento/erro/vazio, busca, envio/falha e aceite/recusa de solicitações, compatibilidade e envio de convite. |
| `frontend/test/widget_test.dart` | 1 smoke test verifica que o app abre na tela de login e exibe título, campos de email/senha e botão Entrar. Passou como parte da suíte Flutter executada com acesso elevado. |
| `frontend/test/auth_validation_test.dart` | 6 testes unitários: nome obrigatório e trim, email ausente/malformado/normalizado e senha obrigatória sem regra de tamanho inventada. |
| `frontend/test/auth_form_validation_test.dart` | 4 testes de widget: campos obrigatórios e email malformado nas telas de login e cadastro. |
| `frontend/test/service_contract_test.dart` | 39 testes: contratos HTTP de avaliações, amizades, compatibilidade e convites; valida método, caminho/query, autenticação, payload, respostas, erros HTTP e falha de transporte com `MockClient`. |
| `frontend/test/swipe_controller_test.dart` | 7 testes: filtra avaliações anteriores, reinicia incluindo avaliados, sinaliza falha de carregamento e recupera após nova consulta, envia os três tipos de avaliação e preserva estado após falha de gravação. |
| `frontend/test/swipe_screen_test.dart` | 2 testes de widget: estado de erro e nova tentativa após falha de catálogo, recuperação do catálogo e preservação do modo de reinício e da conclusão real. |

Tipos confirmados: testes de widget/apresentação, testes unitários de validadores e controller e contratos HTTP simulados. Não há integração real ou E2E Flutter identificada.

### Backend — 15 classes de teste, 80 casos executados

| Arquivo | Casos observados |
| --- | --- |
| `BackendApplicationTests.java` | 1: carregamento do contexto Spring. |
| `controller/UserControllerTest.java` | 4: conflito de email durante persistência convertido em HTTP 409; rejeita formatos de email malformados e campos vazios/nulos sem salvar. |
| `controller/UserAuthenticationFlowTest.java` | 9: percorre cadastro → login → uso de JWT; rejeita credenciais inválidas e cadastro duplicado; confirma que usuários autenticados podem encontrar todas as contas pela listagem com apenas ID/nome e que o acesso anônimo é negado. |
| `controller/GameControllerTest.java` | 6: seleção/reutilização do jogo principal, filtros contra conteúdo extra e ids repetidos, exclusão de jogos não principais, consulta do catálogo e query vazia. |
| `controller/RatingControllerTest.java` | 7: criação e atualização, dados incompletos, bloqueio de exclusão de avaliação alheia, tradução das duas chaves estrangeiras para 401/404 e propagação de falha de integridade alheia à V3. |
| `controller/FriendshipControllerTest.java` | 5: envia pedido pendente, impede auto pedido e duplicata, permite novo pedido após rejeição, aceita/rejeita pedido pendente e consulta pedidos/amigos. |
| `controller/MatchControllerTest.java` | 5: exige amizade aceita, calcula jogos e prioridade compartilhados, agrega contagens, ordena interessados, impede consulta em nome de outra conta e verifica que os três endpoints de compatibilidade consultam somente `LIKE`/`FAVORITE`. |
| `controller/PlayInviteControllerTest.java` | 6: cria convite apenas para amizade aceita, recusa autoenvio e duplicata, aceita/rejeita somente convite pendente e lista enviados/recebidos. |
| `service/IgdbGameServiceTest.java` | 1: corpo de busca filtra categoria de jogo principal e versões. |
| `config/IgdbPropertiesTest.java` | 1: remoção de espaços e aspas das credenciais IGDB. |
| `config/GameSearchSecurityTest.java` | 3: busca IGDB retorna 401 para anônimo, 403 para usuário comum e 200 para administrador. |
| `config/AuthorizationBoundaryTest.java` | 15: nega rotas protegidas sem token; barra leitura, alteração, listagem e exclusão de avaliações alheias; impede leitura de amizades e aceite/rejeição de pedidos alheios; bloqueia listagem, aceite/rejeição de convites alheios; protege os três endpoints de compatibilidade por conta; restringe criação/importação de jogos a administradores. Verifica ausência de escrita/consulta em recusas selecionadas. |
| `integration/PostgresTestDatabaseGuardTest.java` | 3: aceita apenas a URL exata de `game_match_test`; rejeita URL ausente, banco de desenvolvimento e variação inesperada. |
| `integration/PostgresPersistenceIntegrationTest.java` | 11: confirma conexão e migrações V1–V3, persistência dos fluxos principais, FKs existentes, rejeição de exclusão de jogo/usuário referenciado e retornos 404/401 do `POST /ratings` via MockMvc com banco real. Cada caso usa transação revertida. |
| `integration/PostgresRatingMigrationTest.java` | 3: aplica V3 em esquema vazio, preserva avaliações no upgrade V2→V3 e confirma reversão integral quando existe avaliação órfã, seguida de reaplicação após restaurar a referência no esquema descartável. |

Tipos confirmados: testes de unidade com mocks, teste de contexto Spring, camada web com MockMvc e integração real com PostgreSQL. O teste de fluxo de autenticação usa repositório em memória mockado; não é evidência de persistência PostgreSQL ou integração com IGDB.

## Ferramentas e comandos

| Ferramenta/comando | Evidência e status |
| --- | --- |
| `.\test.ps1` | Comando canônico na raiz: executa Maven Wrapper com `--batch-mode --no-transfer-progress test` em `game_match_test` e depois `flutter test --no-pub`; restaura variáveis de ambiente, preserva a saída de erro dos processos nativos sem confundi-la com falha e decide pelo código de saída. Requer `.env` com credenciais PostgreSQL e o banco de teste criado. |
| JUnit Jupiter | Importado pelos testes Java; executado pelo ciclo de testes Maven. |
| Mockito / AssertJ | Usados diretamente nos testes Java inspecionados. |
| Spring MockMvc | Usado pelos testes de segurança/autorização para requisições simuladas. |
| `mvnw.cmd --batch-mode --no-transfer-progress test` | Comando do backend pelo Maven Wrapper, usado pelo comando agregado. A URL deve apontar para `game_match_test`, conforme a guarda antes da inicialização de Spring/Flyway. Em 2026-11-22, 80 testes passaram sem falhas, erros ou skips. |
| `-Dtest=PostgresTestDatabaseGuardTest,PostgresPersistenceIntegrationTest` | Executado duas vezes em `backend/`; em ambas: 10 testes, 0 falhas, 0 erros, exit code 0. A URL `game_match` também foi rejeitada pelo teste de contexto antes de qualquer inicialização do Flyway. |
| Testes direcionados dos fluxos (`-Dtest=RatingControllerTest,FriendshipControllerTest,MatchControllerTest,PlayInviteControllerTest,GameControllerTest,AuthorizationBoundaryTest`) | Executados em `backend/`: 41 testes, 0 falhas, 0 erros. Cobrem avaliações, amizades, compatibilidade, convites, catálogo e isolamento. |
| `flutter_test` / `flutter test --no-pub` | Pacote `flutter_test` declarado no `frontend/pubspec.yaml`. Em 2026-11-22, a execução separada do Flutter passou com 86 testes e código de saída 0. Requer acesso de escrita ao cache do SDK Flutter neste ambiente. |
| `flutter analyze` | Citado em comentário de `frontend/analysis_options.yaml`; comando do analisador estático, não da suíte de testes. Não executado. |
| `start-dev.ps1` | Script presente para iniciar o ambiente de desenvolvimento, não uma suíte de testes. |

## Cobertura identificável

- Há cobertura automatizada identificável para apresentação do cartão/detalhe de jogo, validação de formulários no cliente, cadastro/login com uso de JWT, avaliações, amizades, compatibilidade, convites, catálogo/importação IGDB, normalização de configuração e fronteiras de autorização/isolation por usuário na API.
- QA manual HTTP em 2026-11-18 confirmou `GET /games` 200, `POST /games` 200 para administrador e 403 para usuário comum sem persistência da tentativa negada. Duas contas descartáveis confirmaram leituras próprias e bloqueio 403 para leitura cruzada de avaliações, amizades, compatibilidade/convites e atualização de avaliação alheia; o valor original permaneceu. Dados removidos e verificação posterior confirmou zero contas/jogos temporários. Nenhuma chamada IGDB foi feita.
- QA HTTP positivo adicional em 2026-11-18, apenas em `game_match_test`: duas contas descartáveis criaram interesses diferentes no mesmo jogo e aceitaram amizade. Os endpoints de comparação, lista de jogos compatíveis e amigos interessados retornaram o jogo/amigo compartilhado (1 resultado em cada). As contas e relações temporárias foram removidas; a contagem posterior de contas QA foi zero.
- QA visual em 2026-11-18 percorreu cadastro e login Flutter, carregamento atrasado de catálogo, lista de avaliação preenchida, estado após avaliar todos os jogos, logout, login em outra conta e compartilhamento compatível na aba Jogos. A conta B voltou a ver jogos que A já havia avaliado; os jogos compartilhados mostraram uma amiga interessada.
- Falha P2 observada em 2026-11-18 e corrigida em 2026-11-22. A aba Avaliar passou a exibir erro e nova tentativa quando o catálogo fica indisponível. [Relatório de catálogo offline](reports/2026-11-18-catalogo-offline-mostrado-como-vazio.md).
- A cobertura de autorização de backend é a área funcional mais explícita nos testes encontrados.
- Não foi localizada configuração de JaCoCo, relatório de cobertura ou meta percentual no `pom.xml` inspecionado.
- O `.gitignore` do frontend contém regra para `/coverage/`, mas isso por si só não confirma ferramenta, geração ou medição de cobertura.
- **Percentual de cobertura: não confirmado.** Não há relatório de cobertura inspecionado nem configuração de geração identificada.

## Lacunas e itens não confirmados

- O cadastro/login tem testes Flutter para mensagens e validadores, mas não há teste Flutter do percurso completo até API, persistência, sessão e navegação após login.
- Swipe tem testes unitários do controller; serviços Flutter de avaliações, amizades, compatibilidade e convites têm contratos HTTP simulados. `FriendsScreen` e `GamesScreen` agora têm cobertura widget para fluxos sociais, compatibilidade e convites; gestos do swipe ainda não têm teste de widget.
- Há testes unitários dos controllers para regras de avaliação, amizade, compatibilidade e convites, testes MockMvc para autorização e testes de integração real com PostgreSQL para persistência/migrações.
- A interface administrativa de catálogo no Flutter foi adiada por decisão de produto. O QA administrativo HTTP cobriu `POST /games`. Os fluxos IGDB seguem cobertos por testes automatizados, sem chamadas externas.
- A V3 valida as duas chaves estrangeiras de `ratings`; as colunas continuam aceitando `NULL` no banco. O ensaio da V3 usou `game_match_test`. A integração real com IGDB não foi executada.
- Testes instrumentados Android, E2E e execução em navegador **não confirmados**.
- Não há arquivos de workflow de CI sob `.github` identificados; há apenas diretório de configuração de modernização Java. Execução externa de CI **não confirmada**.
- Playwright, Cypress e configuração equivalente **não encontrados**; não se presume seu uso.
- O README documenta `.\test.ps1` como comando agregado e os comandos direcionados por stack.
- Em 2026-11-22, a execução direcionada de migração, persistência, avaliações e autorização passou com 36 testes. A execução agregada passou com 80 testes Maven e 86 Flutter no mesmo dia.
- Percentual de cobertura e estabilidade/flakiness **não confirmados**; não foi gerado relatório de cobertura nem feita execução repetida para medir flakiness.


- QA manual pela interface em 2026-10-25 cobriu cadastro/login, avaliações, amizades, compatibilidade e convites. Em 2026-11-18, QA HTTP e visual confirmou limites de catálogo, isolamento e compartilhamento positivo em `game_match_test`, e documentou uma falha visual offline. A interface administrativa não existe. Consulte os relatórios em `quality/reports/`.

# Inventário e diagnóstico dos testes

## Como interpretar este inventário

- **Fato observado:** aparece em arquivo, configuração ou documentação inspecionada.
- **Não confirmado:** não foi possível concluir apenas pela inspeção; não significa necessariamente que não exista fora do repositório ou em ambiente externo.
- Execução mais recente: `mvn test` passou com 60 testes no PostgreSQL isolado `game_match_test`; Flutter passou com 14 testes. Flyway aplicou V1 e V2 nesse banco. A falha anterior ocorreu ao usar o banco local `game_match`, que não foi alterado.

## Tecnologias e organização

| Área | Fatos observados |
| --- | --- |
| Frontend | Flutter/Dart; aplicação em `frontend/lib/`; testes em `frontend/test/`; dependências de desenvolvimento `flutter_test` e `flutter_lints` em `frontend/pubspec.yaml`. |
| Backend | Java 21 e Spring Boot 4.0.6 em `backend/pom.xml`; testes em `backend/src/test/java/`; dependências de teste Spring Data JPA e WebMVC. Os testes usam JUnit Jupiter, Mockito, AssertJ e MockMvc. |
| Persistência | PostgreSQL e Flyway configurados no backend; existem migrações `V1` e `V2`. |
| Ambiente local | `start-dev.ps1` inicia backend e Flutter Web e verifica disponibilidade HTTP; não executa as suítes de teste. `docker-compose.yml` declara PostgreSQL e backend. |

## Testes encontrados

### Frontend — 5 arquivos, 14 testes

| Arquivo | Casos observados |
| --- | --- |
| `frontend/test/game_card_test.dart` | 2 casos: URL de capa IGDB convertida para resolução alta e imagem configurada com `BoxFit.contain`. |
| `frontend/test/games_screen_test.dart` | 1 caso: cabeçalho apresenta título, contagem de amigos interessados/favoritos e imagem do jogo. |
| `frontend/test/widget_test.dart` | 1 smoke test verifica que o app abre na tela de login e exibe título, campos de email/senha e botão Entrar. Passou como parte da suíte Flutter executada com acesso elevado. |
| `frontend/test/auth_validation_test.dart` | 6 testes unitários: nome obrigatório e trim, email ausente/malformado/normalizado e senha obrigatória sem regra de tamanho inventada. |
| `frontend/test/auth_form_validation_test.dart` | 4 testes de widget: campos obrigatórios e email malformado nas telas de login e cadastro. |

Tipos confirmados: testes de widget/apresentação e testes unitários puros dos validadores. Não identifiquei teste de serviço HTTP, unidade de estado/controller, integração ou E2E Flutter entre os arquivos encontrados.

### Backend — 12 arquivos, 60 métodos de teste anotados com `@Test`

| Arquivo | Casos observados |
| --- | --- |
| `BackendApplicationTests.java` | 1: carregamento do contexto Spring. |
| `controller/UserControllerTest.java` | 4: conflito de email durante persistência convertido em HTTP 409; rejeita formatos de email malformados e campos vazios/nulos sem salvar. |
| `controller/UserAuthenticationFlowTest.java` | 9: percorre cadastro → login → uso de JWT; rejeita credenciais inválidas e cadastro duplicado; confirma que usuários autenticados podem encontrar todas as contas pela listagem com apenas ID/nome e que o acesso anônimo é negado. |
| `controller/GameControllerTest.java` | 6: seleção/reutilização do jogo principal, filtros contra conteúdo extra e ids repetidos, exclusão de jogos não principais, consulta do catálogo e query vazia. |
| `controller/RatingControllerTest.java` | 4: cria avaliação para usuário autenticado, atualiza avaliação do mesmo jogo, rejeita dados incompletos e impede exclusão de avaliação alheia. |
| `controller/FriendshipControllerTest.java` | 5: envia pedido pendente, impede auto pedido e duplicata, permite novo pedido após rejeição, aceita/rejeita pedido pendente e consulta pedidos/amigos. |
| `controller/MatchControllerTest.java` | 5: exige amizade aceita, calcula jogos e prioridade compartilhados, agrega contagens, ordena interessados, impede consulta em nome de outra conta e verifica que os três endpoints de compatibilidade consultam somente `LIKE`/`FAVORITE`. |
| `controller/PlayInviteControllerTest.java` | 6: cria convite apenas para amizade aceita, recusa autoenvio e duplicata, aceita/rejeita somente convite pendente e lista enviados/recebidos. |
| `service/IgdbGameServiceTest.java` | 1: corpo de busca filtra categoria de jogo principal e versões. |
| `config/IgdbPropertiesTest.java` | 1: remoção de espaços e aspas das credenciais IGDB. |
| `config/GameSearchSecurityTest.java` | 3: busca IGDB retorna 401 para anônimo, 403 para usuário comum e 200 para administrador. |
| `config/AuthorizationBoundaryTest.java` | 15: nega rotas protegidas sem token; barra leitura, alteração, listagem e exclusão de avaliações alheias; impede leitura de amizades e aceite/rejeição de pedidos alheios; bloqueia listagem, aceite/rejeição de convites alheios; protege os três endpoints de compatibilidade por conta; restringe criação/importação de jogos a administradores. Verifica ausência de escrita/consulta em recusas selecionadas. |

Tipos confirmados: testes de unidade com mocks, teste de contexto Spring e testes de camada web com MockMvc. O teste de fluxo de autenticação exercita endpoints HTTP, BCrypt e geração/validação de JWT reais, mas usa repositório em memória mockado; não é evidência de integração com PostgreSQL ou IGDB.

## Ferramentas e comandos

| Ferramenta/comando | Evidência e status |
| --- | --- |
| `.\test.ps1` | Comando padrão na raiz: executa `mvn test` com a URL de banco temporariamente apontada a `game_match_test` e depois `flutter test --no-pub --verbose`; restaura as variáveis de ambiente ao terminar. Requer `.env` com usuário/senha PostgreSQL e o banco de teste criado. |
| JUnit Jupiter | Importado pelos testes Java; executado pelo ciclo de testes Maven. |
| Mockito / AssertJ | Usados diretamente nos testes Java inspecionados. |
| Spring MockMvc | Usado pelos testes de segurança/autorização para requisições simuladas. |
| `mvn test` | Documentado no `README.md` da raiz para execução em `backend/`. Última execução: 60 testes, 0 falhas/erros, `BUILD SUCCESS`, com `SPRING_DATASOURCE_URL` temporariamente apontado a `game_match_test`. |
| Testes direcionados dos fluxos (`-Dtest=RatingControllerTest,FriendshipControllerTest,MatchControllerTest,PlayInviteControllerTest,GameControllerTest,AuthorizationBoundaryTest`) | Executados em `backend/`: 41 testes, 0 falhas, 0 erros. Cobrem avaliações, amizades, compatibilidade, convites, catálogo e isolamento. |
| `flutter_test` / `flutter test --no-pub --verbose` | Pacote `flutter_test` declarado no `frontend/pubspec.yaml`. Suíte completa executada com acesso elevado: 14 testes, 0 falhas, 0 erros. No sandbox padrão, a chamada direta falhou ao abrir `C:\flutter\bin\cache\lockfile`; `AGENTS.md` registra a execução com elevação necessária neste ambiente. |
| `flutter analyze` | Citado em comentário de `frontend/analysis_options.yaml`; comando do analisador estático, não da suíte de testes. Não executado. |
| `start-dev.ps1` | Script presente para iniciar o ambiente de desenvolvimento, não uma suíte de testes. |

## Cobertura identificável

- Há cobertura automatizada identificável para apresentação do cartão/detalhe de jogo, validação de formulários no cliente, cadastro/login com uso de JWT, avaliações, amizades, compatibilidade, convites, catálogo/importação IGDB, normalização de configuração e fronteiras de autorização/isolation por usuário na API.
- A cobertura de autorização de backend é a área funcional mais explícita nos testes encontrados.
- Não foi localizada configuração de JaCoCo, relatório de cobertura ou meta percentual no `pom.xml` inspecionado.
- O `.gitignore` do frontend contém regra para `/coverage/`, mas isso por si só não confirma ferramenta, geração ou medição de cobertura.
- **Percentual de cobertura: não confirmado.** Não há relatório de cobertura inspecionado nem configuração de geração identificada.

## Lacunas e itens não confirmados

- O cadastro/login tem testes Flutter para mensagens e validadores, mas não há teste Flutter do percurso completo até API, persistência, sessão e navegação após login.
- Os fluxos de avaliação/swipe, amizades, compatibilidade, convites e administração têm testes de controller no backend; interação e estados correspondentes nas telas Flutter ainda não estão cobertos.
- Há testes unitários dos controllers para regras de avaliação, amizade, compatibilidade e convites e testes MockMvc para suas fronteiras de autorização. Integração real com banco e cobertura das telas Flutter desses fluxos continuam pendentes.
- Fluxos de sucesso/erro da interface e interação real frontend/API não aparecem cobertos pelos testes listados.
- Flyway aplicou as migrações V1 e V2 no PostgreSQL isolado `game_match_test`, e o teste de contexto Spring passou; testes de persistência real dos fluxos funcionais continuam não confirmados. A integração real com IGDB também não foi executada.
- Testes instrumentados Android, E2E e execução em navegador **não confirmados**.
- Não há arquivos de workflow de CI sob `.github` identificados; há apenas diretório de configuração de modernização Java. Execução externa de CI **não confirmada**.
- Playwright, Cypress e configuração equivalente **não encontrados**; não se presume seu uso.
- O README documenta `mvn test`, mas não documenta o comando da suíte Flutter; `flutter test` deriva do executor configurado.
- As 14 verificações Flutter passaram. Os 60 testes Maven também passaram quando a URL foi direcionada explicitamente ao banco isolado `game_match_test`; veja `quality/reports/2026-10-25-suite-completa.md`.
- Percentual de cobertura e estabilidade/flakiness **não confirmados**; não foi gerado relatório de cobertura nem feita execução repetida para medir flakiness.


- QA manual pela interface foi concluído para cadastro/login, avaliações, amizades, compatibilidade e convites; todos passaram com contas/jogos descartáveis somente em `game_match_test`. Catálogo/admin e isolamento manual ficaram parciais; consulte `quality/reports/2026-10-25-suite-completa.md`.

# Qualidade e testes

## Objetivo

Este documento registra a estrutura atual dos testes do Game Match, os fluxos principais que precisam de cobertura e os critérios para considerar essas verificações bem-sucedidas. É um mapa de qualidade inicial; não representa uma medição de cobertura nem certifica que a suíte passou.

## Estrutura do projeto

- `frontend/`: aplicativo Flutter, com telas, serviços HTTP, modelos e widgets.
- `backend/`: API Spring Boot, com controladores REST, serviços, repositórios, segurança e migrações Flyway para PostgreSQL.
- `frontend/test/`: testes de widgets executados pelo Flutter Test.
- `backend/src/test/java/`: testes Java executados pelo Maven, com JUnit, Mockito, AssertJ e MockMvc.

## Testes existentes

### Frontend Flutter

| Arquivo | Escopo atual |
| --- | --- |
| `frontend/test/game_card_test.dart` | Verifica que a capa da IGDB usa resolução alta e que a imagem é exibida inteira (`BoxFit.contain`). |
| `frontend/test/games_screen_test.dart` | Verifica o cabeçalho do detalhe do jogo, incluindo título, contagem de amigos interessados/favoritos e URL da imagem. |
| `frontend/test/widget_test.dart` | Smoke test confirma que o app abre na tela de login. |
| `frontend/test/auth_validation_test.dart` | Valida regras de nome, email e senha. |
| `frontend/test/auth_form_validation_test.dart` | Verifica validações visíveis nos formulários de login e cadastro. |
| `frontend/test/service_contract_test.dart` | Verifica contratos HTTP autenticados de avaliações, amizades, compatibilidade e convites com cliente simulado. |
| `frontend/test/swipe_controller_test.dart` | Valida filtro de jogos avaliados, tipos de avaliação, avanço após sucesso e preservação do estado após falha. |

Os testes Flutter incluem widgets, validação, contratos HTTP simulados e regras do controller de swipe. Ainda não há cobertura de integração real com a API/PostgreSQL nem testes de widgets para todos os fluxos de amizades, compatibilidade, convites e administração.

### Backend Spring Boot

| Arquivo | Escopo atual |
| --- | --- |
| `BackendApplicationTests.java` | Confirma que o contexto da aplicação inicia. |
| `controller/UserControllerTest.java` | Confirma que conflito de email ao persistir cadastro é convertido em HTTP 409. |
| `controller/UserAuthenticationFlowTest.java` | Exercita cadastro, login e uso de JWT em requisições HTTP. |
| `controller/GameControllerTest.java` | Confirma que importação individual prefere jogo principal a um port homônimo e que importação em lote exclui jogos que não são principais. |
| `controller/RatingControllerTest.java` | Valida criação/atualização de avaliações, dados inválidos e bloqueio de avaliação de outra conta. |
| `controller/FriendshipControllerTest.java` | Valida solicitações, duplicatas, aceite/rejeição e consulta de amizades. |
| `controller/MatchControllerTest.java` | Valida amizade aceita, interesses compartilhados, prioridade, ordenação e exclusão de dislikes. |
| `controller/PlayInviteControllerTest.java` | Valida convite entre amigos aceitos, duplicatas, estados pendentes e respostas. |
| `service/IgdbGameServiceTest.java` | Confirma que a consulta à IGDB filtra jogos principais e versões na origem. |
| `config/IgdbPropertiesTest.java` | Confirma a limpeza de espaços e aspas nas credenciais da IGDB. |
| `config/GameSearchSecurityTest.java` | Confirma que busca IGDB rejeita anônimo (401), rejeita usuário comum (403) e permite administrador (200). |
| `config/AuthorizationBoundaryTest.java` | Verifica autenticação e limites de acesso por usuário em avaliações, amizades e convites, além de restringir criação/importação de jogos a administradores. |

Os testes do backend cobrem as regras principais de domínio e autorização com JUnit/Mockito/MockMvc. Os controller tests usam dependências simuladas; não equivalem a integração completa de persistência em PostgreSQL.

## Fluxos críticos do produto

1. **Cadastro e login:** validar campos, criar conta, autenticar e manter os dados da sessão para uso nas telas autenticadas.
2. **Avaliação de jogos:** carregar jogos disponíveis, registrar dislike/like/favorito e atualizar as escolhas do usuário.
3. **Amizades:** enviar solicitação, consultar solicitações pendentes, aceitar/rejeitar e listar amizades aceitas.
4. **Compatibilidade:** comparar interesses entre amigos e exibir jogos compatíveis e quais amigos demonstraram interesse.
5. **Convites para jogar:** criar convite somente entre amigos aceitos, listar recebidos/enviados e aceitar/rejeitar convite pendente.
6. **Administração de catálogo:** buscar/importar jogos da IGDB e criar jogos somente com papel administrativo.
7. **Isolamento entre contas:** impedir que um usuário leia ou altere avaliações, amizades e convites pertencentes a outra conta.

## Critérios de sucesso

- O comando agregado canônico é `.\test.ps1` na raiz; executa Maven no banco isolado `game_match_test` e Flutter com `--no-pub`.
- Para um ciclo direcionado de Maven, `SPRING_DATASOURCE_URL` precisa apontar explicitamente para `game_match_test`; o comando agregado já faz isso. Veja no README raiz como executar o wrapper diretamente com essa proteção.
- Para um ciclo direcionado Flutter, usar `flutter test --no-pub` em `frontend/`.
- Casos de acesso sem autenticação devem retornar 401 nas rotas protegidas; usuários autenticados sem autorização devem receber 403.
- Operações de escrita recusadas por autorização não devem persistir alterações.
- Regras de domínio devem cobrir resultados válidos e limites relevantes, como convite apenas entre amizades aceitas e importação apenas de jogos principais.
- Testes de interface devem verificar estados observáveis pelo usuário, incluindo carregamento, sucesso, erro e listas vazias nos fluxos críticos.
- Verificações dependentes de PostgreSQL, IGDB ou rede devem usar doubles controlados nos testes unitários/de controlador; integrações reais devem ser identificadas como tais e executadas em ambiente configurado.

## Lacunas iniciais observadas

- Ainda faltam testes Flutter de widget/interação para telas de amizades, compatibilidade, convites e administração; cobertura HTTP dessas telas não é substituída pelos testes de contrato dos serviços.
- Os testes de controller das regras principais usam dependências simuladas; falta validar persistência funcional real com PostgreSQL isolado.
- Não foi localizada configuração de cobertura. Portanto, este documento não informa percentual de cobertura.
- A aprovação da suíte deve ser baseada na execução registrada em `quality/test-inventory.md`, não presumida pela existência dos testes.

## Comandos de execução

Na raiz do projeto, para validar as duas stacks:

```powershell
.\test.ps1
```

Execução separada do Flutter, quando necessária:

```powershell
cd frontend
flutter test --no-pub
```

O backend requer PostgreSQL configurado. O comando agregado aponta para o banco isolado `game_match_test` e não usa o banco de desenvolvimento. Não execute o wrapper Maven sem definir essa URL isolada.

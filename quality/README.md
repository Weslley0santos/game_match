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
| `frontend/test/widget_test.dart` | Teste padrão de contador do template Flutter. A expectativa de contador não parece corresponder à aplicação Game Match e deve ser revisada antes de ser considerada uma verificação útil. |

Os testes atuais são testes de apresentação de widgets. Não encontrei testes automatizados para autenticação, navegação, avaliações, tela de amigos, convites ou chamadas HTTP.

### Backend Spring Boot

| Arquivo | Escopo atual |
| --- | --- |
| `BackendApplicationTests.java` | Confirma que o contexto da aplicação inicia. |
| `controller/UserControllerTest.java` | Confirma que conflito de email ao persistir cadastro é convertido em HTTP 409. |
| `controller/GameControllerTest.java` | Confirma que importação individual prefere jogo principal a um port homônimo e que importação em lote exclui jogos que não são principais. |
| `service/IgdbGameServiceTest.java` | Confirma que a consulta à IGDB filtra jogos principais e versões na origem. |
| `config/IgdbPropertiesTest.java` | Confirma a limpeza de espaços e aspas nas credenciais da IGDB. |
| `config/GameSearchSecurityTest.java` | Confirma que busca IGDB rejeita anônimo (401), rejeita usuário comum (403) e permite administrador (200). |
| `config/AuthorizationBoundaryTest.java` | Verifica autenticação e limites de acesso por usuário em avaliações, amizades e convites, além de restringir criação/importação de jogos a administradores. |

## Fluxos críticos do produto

1. **Cadastro e login:** validar campos, criar conta, autenticar e manter os dados da sessão para uso nas telas autenticadas.
2. **Avaliação de jogos:** carregar jogos disponíveis, registrar dislike/like/favorito e atualizar as escolhas do usuário.
3. **Amizades:** enviar solicitação, consultar solicitações pendentes, aceitar/rejeitar e listar amizades aceitas.
4. **Compatibilidade:** comparar interesses entre amigos e exibir jogos compatíveis e quais amigos demonstraram interesse.
5. **Convites para jogar:** criar convite somente entre amigos aceitos, listar recebidos/enviados e aceitar/rejeitar convite pendente.
6. **Administração de catálogo:** buscar/importar jogos da IGDB e criar jogos somente com papel administrativo.
7. **Isolamento entre contas:** impedir que um usuário leia ou altere avaliações, amizades e convites pertencentes a outra conta.

## Critérios de sucesso

- Testes automatizados devem passar nos executores já adotados pelo projeto: `flutter test` em `frontend/` e `mvn test` em `backend/`.
- Casos de acesso sem autenticação devem retornar 401 nas rotas protegidas; usuários autenticados sem autorização devem receber 403.
- Operações de escrita recusadas por autorização não devem persistir alterações.
- Regras de domínio devem cobrir resultados válidos e limites relevantes, como convite apenas entre amizades aceitas e importação apenas de jogos principais.
- Testes de interface devem verificar estados observáveis pelo usuário, incluindo carregamento, sucesso, erro e listas vazias nos fluxos críticos.
- Verificações dependentes de PostgreSQL, IGDB ou rede devem usar doubles controlados nos testes unitários/de controlador; integrações reais devem ser identificadas como tais e executadas em ambiente configurado.

## Lacunas iniciais observadas

- Não há testes Flutter identificados para telas/fluxos de login, cadastro, swipe/avaliação, amizades ou convites.
- Não há testes dedicados identificados para os controladores de avaliações, amizades, compatibilidade e convites; parte das fronteiras de autorização desses recursos é coberta por `AuthorizationBoundaryTest`.
- O teste padrão de contador do Flutter parece obsoleto para o aplicativo e pode falhar por não refletir a interface atual.
- Não foi localizada configuração de cobertura. Portanto, este documento não informa percentual de cobertura.
- Os testes não foram executados durante a elaboração deste documento; o estado de aprovação da suíte permanece desconhecido.

## Comandos de execução

Na pasta `frontend/`:

```powershell
flutter test
```

Na pasta `backend/`:

```powershell
mvn test
```

Os comandos acima são referências documentadas; não foram executados nesta análise.

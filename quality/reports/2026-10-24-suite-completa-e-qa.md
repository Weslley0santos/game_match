# Execução das suítes e QA — 2026-10-24

## Escopo e critérios

Foram executados os comandos de teste documentados em `quality/test-inventory.md`. Esta rodada não alterou código, testes, dependências ou configurações. `flutter analyze` não foi executado porque é análise estática, não teste unitário.

## Resultados automatizados

| Comando | Resultado | Evidência |
| --- | --- | --- |
| `mvn test` (em `backend/`) | **Falhou** | 20 testes: 0 falhas de asserção, 1 erro, 0 ignorados. O único erro foi `BackendApplicationTests.contextLoads`. |
| `mvnw.cmd -Dtest=UserAuthenticationFlowTest test` (em `backend/`; wrapper local no PowerShell) | **Passou** | 3 testes: 0 falhas, 0 erros, 0 ignorados. |
| `flutter test --no-pub --verbose` (em `frontend/`) | **Passou** | Código de saída 0; 4 testes passaram. O comando foi executado com acesso ao cache do SDK Flutter, conforme instrução local do projeto. Log da execução: `%TEMP%\game_match_flutter_test_2026-10-24.log`. |
| `flutter analyze` (em `frontend/`) | **Não executado** | Fora do escopo solicitado de testes unitários. |

### Falha do contexto Spring

Mensagem relevante preservada do relatório Surefire:

```text
Found non-empty schema(s) "public" but no schema history table. Use baseline() or set baselineOnMigrate to true to initialize the schema history table.
```

O contexto tentou conectar ao PostgreSQL local configurado como `jdbc:postgresql://localhost:5432/game_match`; o Flyway validou duas migrações e parou ao detectar o schema preenchido sem `flyway_schema_history`. Não foi feita tentativa de baseline, migração manual ou correção nesta rodada. A execução alcançou a conexão com o banco; não foi possível confirmar se ocorreu alguma alteração no banco antes do erro.

## QA dos fluxos funcionais

O QA independente não iniciou serviços e não alterou dados. Não havia portas locais em estado `Listen`. Evidência de aplicação funcional não foi obtida; por isso, nenhum fluxo abaixo foi validado:

| Fluxo de `quality/test-plan.md` | Resultado | Limite observado |
| --- | --- | --- |
| Cadastro e login | **Bloqueado** | Aplicação indisponível; usuário de teste e ambiente isolado não confirmados. |
| Avaliação de jogos | **Bloqueado** | Requer sessão e API disponíveis. |
| Amizades | **Bloqueado** | Requer ambiente seguro para operações que gravam dados. |
| Compatibilidade | **Bloqueado** | Requer sessão e dados de usuários/jogos. |
| Convites para jogar | **Bloqueado** | Requer ambiente seguro para criar/alterar convites. |
| Catálogo e administração | **Bloqueado** | Aplicação indisponível; credenciais administrativas e acesso à IGDB não confirmados. |
| Isolamento por usuário | **Bloqueado** | Contas e ambiente isolado não disponíveis para validação funcional. |
| Inicialização local | **Bloqueado** | O carregamento do contexto Spring falhou pelo erro de Flyway; os serviços não foram reiniciados. |

Os testes automatizados não foram tratados como evidência de navegação ou validação da interface por QA.

## Revisão independente

O Code Reviewer considerou coerentes as classificações e as evidências. Recomendou não repetir a inicialização contra esse schema sem antes dispor de banco de teste isolado. Também observou que a suíte Flutter e o teste de autenticação passaram, mas não substituem validação funcional.

## Próximo passo mínimo

Configurar ou identificar um PostgreSQL isolado para testes e apontar nele a configuração de teste antes de repetir `mvn test`. Não ativar baseline nem executar migrações no banco local atual sem confirmar que esse é o banco descartável destinado aos testes.

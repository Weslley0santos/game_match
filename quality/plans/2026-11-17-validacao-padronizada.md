# Padronização de testes e cobertura — Plano de implementação

> **Spec:** [desenho aprovado](../design-test-standardization.md)

**Objetivo:** Padronizar a validação Maven/Flutter no comando agregado existente e ampliar os testes Flutter dos contratos HTTP e das regras de avaliação.

**Arquitetura:** Manter `test.ps1` como único orquestrador, preservando o banco PostgreSQL isolado `game_match_test`, a execução das duas suítes e a restauração do ambiente. Acrescentar testes unitários Flutter sem novas dependências, usando `http/testing.dart` e `http.runWithClient` para simular as chamadas dos serviços e do controller de swipe.

**Stack:** PowerShell, Maven Wrapper, Flutter Test, JUnit já existente.

## Restrições globais

- Não apontar testes ao banco de desenvolvimento `game_match`.
- Usar Maven Wrapper e `flutter test --no-pub`; não atualizar dependências.
- Novos testes de serviço devem usar `MockClient` e nenhuma rede externa.
- O script deve executar as duas suítes, restaurar diretório/variáveis e sair com código diferente de zero se qualquer uma falhar.
- Atualizar documentos em `quality/` e README para refletir comandos e cobertura observados.

## Revisão de limites

- Se Maven falhar, Flutter ainda deve ser executado e ambos os resultados devem aparecer.
- Se Flutter não iniciar ou falhar, o código de saída agregado ainda deve refletir a falha.
- Em erro de inicialização do script, variáveis de ambiente e diretório precisam ser restaurados.
- Avaliações existentes devem filtrar jogos já avaliados; gravação malsucedida não deve registrar sucesso local nem avançar o jogo.
- Métodos e URLs dos serviços devem manter autenticação e payload compatíveis com as rotas existentes.

---

### Tarefa 1: Testes de contrato HTTP dos serviços Flutter

**Responsável:** Test Automation Engineer.

**Arquivos:**
- Criar: `frontend/test/service_contract_test.dart`
- Consultar: `quality/design-test-standardization.md`, `quality/test-plan.md`, `frontend/lib/data/services/`

**Interfaces:** usar `package:http/testing.dart` e `http.runWithClient`; limpar `UserSession` entre testes. Não alterar produção.

- [x] Cobrir Rating, Friendship, Match e PlayInvite: método HTTP, caminho/query, corpo JSON quando aplicável e token bearer.
- [x] Cobrir respostas JSON/lista vazia e erros HTTP mapeados pelo helper.
- [x] Executar os testes direcionados com `flutter test --no-pub test/service_contract_test.dart` conforme regra de acesso ao cache Flutter (39 passaram).
- [x] Revisar que nenhum teste chama rede real nem depende de ordem.

### Tarefa 2: Regras do controller de swipe

**Arquivos:**
- Modificar: `frontend/lib/features/swipe/controllers/swipe_controller.dart`
- Criar: `frontend/test/swipe_controller_test.dart`

**Interfaces:** usar `http.runWithClient` e `MockClient` para isolar as chamadas feitas pelos serviços existentes; manter o construtor público sem alterações.

- [x] Escrever testes para filtrar jogos avaliados, permitir inclusão de avaliados, enviar `LIKE`/`DISLIKE`/`FAVORITE`, avançar após sucesso e preservar estado/índice em erro.
- [x] Executar o arquivo de teste e confirmar falha específica na regra de estado quando o POST falha.
- [x] Alterar o controller minimamente para registrar a avaliação local e avançar apenas depois do sucesso remoto.
- [x] Reexecutar testes do controller: 6 passaram.

### Tarefa 3: Comando agregado canônico

**Arquivos:**
- Modificar: `test.ps1`
- Modificar: `README.md`

- [x] Padronizar preflight, nomes/saídas dos comandos e apresentação separada dos resultados Maven e Flutter.
- [x] Preservar execução da segunda suíte quando a primeira falha, restauração de ambiente e código final de falha agregado.
- [x] Documentar `.\test.ps1` como comando único recomendado e os comandos direcionados por stack.
- [x] Não adicionar analyzer ao comando padrão sem baseline limpo confirmado.

### Tarefa 4: Documentação da cobertura e verificação completa

**Arquivos:**
- Modificar: `quality/test-plan.md`
- Modificar: `quality/test-inventory.md`
- Modificar: `quality/backlog.md`
- Modificar: `quality/README.md`

- [x] Atualizar comandos e lacunas sem repetir contagens manuais até executar as suítes.
- [x] Executar Maven em banco isolado e Flutter com `--no-pub`, seguindo o `AGENTS.md` local.
- [x] Registrar resultados reais no inventário; sem bloqueios.
- [x] Revisar diff, links e coerência do plano com os testes implementados; Code Reviewer aprovou após corrigir os achados.

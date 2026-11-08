# Inicialização do Flutter no sandbox e smoke test obsoleto

## Resumo

Na rodada QA, `flutter test` não produziu saída por aproximadamente 80 segundos e foi interrompido. Uma execução isolada identificou o smoke test do template que esperava o contador `0`; ele foi atualizado para verificar a tela de login real. O acesso elevado ao cache do SDK permitiu iniciar o Flutter e executar a suíte completa com sucesso.

## Evidência reproduzível

- Comando isolado anterior: `flutter test --no-pub --verbose test/widget_test.dart`
- Resultado: executou em cerca de 11,6 segundos e falhou na linha 19 porque o app não exibe `0`; a aplicação inicia na tela de login.
- Comando da suíte: `flutter test --no-pub --verbose` em `frontend/`.
- Resultado: mais de 80 segundos sem saída, sem iniciar um novo processo Dart/`flutter_tester`; o comando foi interrompido.
- Diagnóstico direto no sandbox padrão: invocar o `flutter_tools.snapshot` retornou `Flutter failed to open a file at "C:\\flutter\\bin\\cache\\lockfile"`. O `cmd.exe` do launcher consumia CPU; `shared.bat` repete tentativas sem pausa e suprime stderr.
- Confirmação: com `sandbox_permissions: require_escalated`, `flutter test --no-pub --verbose` em `frontend/` iniciou normalmente e passou nos 4 testes. Isso indica que o bloqueio anterior era o acesso do sandbox ao cache do SDK, não uma falha da suíte.

## Impacto e limites

- O teste antigo do contador falhava porque a aplicação abre na tela de login; foi substituído por uma verificação do conteúdo inicial real.
- A suíte completa passou quando o agente recebeu acesso ao cache do SDK.
- A interface de cadastro/login não foi percorrida manualmente. O repositório não tem executor E2E configurado e o ambiente local não foi iniciado.
- A suíte Maven completa também não foi executada porque o teste de contexto pode conectar ao PostgreSQL configurado localmente.
- Em separado, `mvnw.cmd -Dtest=UserAuthenticationFlowTest test` passou com 3 testes, sem falhas nem erros.

## Acompanhamento

Instrução operacional registrada em `AGENTS.md`: agentes devem executar `flutter test --no-pub` com acesso elevado ao cache do SDK. Se a elevação for negada, registrar bloqueio ambiental em vez de manter o launcher em retry.

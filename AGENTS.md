# Instruções locais para agentes

## Testes Flutter

- O comando agregado oficial é `.\test.ps1` executado na raiz: roda Maven no banco isolado `game_match_test` e Flutter com `--no-pub`.
- Ao executar o Maven diretamente, defina `SPRING_DATASOURCE_URL` para `jdbc:postgresql://localhost:5432/game_match_test`; o backend importa o `.env`, que pode apontar para o banco de desenvolvimento.
- O frontend está em `frontend/`; o SDK usado neste ambiente está em `C:\flutter`.
- O Flutter precisa escrever no próprio cache, especialmente em `C:\flutter\bin\cache\lockfile`. O sandbox padrão dos agentes pode impedir esse acesso e deixar o launcher repetindo tentativas antes de iniciar Dart.
- Ao executar testes Flutter neste ambiente, use `flutter test --no-pub` e solicite `sandbox_permissions: require_escalated` com justificativa de acesso ao cache do SDK. Acrescente `--verbose` para diagnosticar falhas.
- Não execute `dart pub upgrade` como parte da validação normal: isso pode alterar `frontend/pubspec.lock`. Use as dependências já resolvidas.
- Se o acesso elevado for negado, registre o erro como bloqueio do ambiente; não classifique os testes como falhos nem deixe um processo preso no launcher.

## Planejamento de qualidade

- Antes de iniciar uma mudança funcional, consulte `quality/test-plan.md` e `quality/backlog.md` para conhecer os fluxos críticos, critérios de sucesso e pendências registradas.
- Mantenha o plano, o inventário de testes e o backlog nos arquivos de `quality/`; não duplique essas listas neste arquivo.

## Revisão especializada

- Depois da implementação e das verificações aplicáveis, acione o agente especializado **Code Reviewer** para revisar a mudança de forma independente.
- Forneça ao revisor o pedido e os critérios de aceitação, o diff completo, os comandos executados e seus resultados; inclua evidências de QA quando houver mudanças de comportamento, interface ou integração.
- O revisor não altera arquivos. Ele verifica atendimento aos requisitos, correção, regressões, cobertura relevante e consistência entre o diff e os resultados apresentados.
- Para cada achado, informe gravidade, arquivo e linha, motivo e impacto. Registre também os critérios verificados, os que falharam e os que ficaram sem evidência ou bloqueados.
- Se houver achados, o agente implementador corrige os pertinentes, executa novamente as verificações afetadas e solicita nova revisão dessas correções.
- Considere a revisão aprovada somente quando os requisitos estiverem atendidos e não houver achados bloqueadores ou importantes pendentes. Não declare aprovação com base apenas em impressão ou em testes sem resultado registrado.

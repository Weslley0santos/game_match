# Instruções locais para agentes

## Testes Flutter

- O frontend está em `frontend/`; o SDK usado neste ambiente está em `C:\flutter`.
- O Flutter precisa escrever no próprio cache, especialmente em `C:\flutter\bin\cache\lockfile`. O sandbox padrão dos agentes pode impedir esse acesso e deixar o launcher repetindo tentativas antes de iniciar Dart.
- Ao executar testes Flutter neste ambiente, use `flutter test --no-pub` e solicite `sandbox_permissions: require_escalated` com justificativa de acesso ao cache do SDK. Acrescente `--verbose` para diagnosticar falhas.
- Não execute `dart pub upgrade` como parte da validação normal: isso pode alterar `frontend/pubspec.lock`. Use as dependências já resolvidas.
- Se o acesso elevado for negado, registre o erro como bloqueio do ambiente; não classifique os testes como falhos nem deixe um processo preso no launcher.
- A suíte validada nesta configuração contém 5 arquivos e 14 testes: 8 de widget e 6 unitários dos validadores de autenticação.


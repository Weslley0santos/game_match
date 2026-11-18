# Desenho: validação padronizada e cobertura dos fluxos principais

## Objetivo

Padronizar como a suíte Java/Maven e a suíte Flutter são executadas, ampliar evidência automatizada para regras principais no cliente e manter os comandos e o estado de cobertura documentados em um único lugar.

## Abordagem

- Manter `.\test.ps1` como comando agregado oficial, aproveitando o wrapper Maven e `flutter test --no-pub` já presentes.
- Preservar o isolamento do backend em `game_match_test`, a execução de ambas as suítes mesmo se uma falhar, a restauração das variáveis de ambiente e códigos de saída que falhem se qualquer suíte falhar.
- Padronizar mensagens e pré-requisitos do script sem expor valores de configuração. Não incluir `flutter analyze` na suíte agregada até que haja baseline confirmando que a análise está limpa.
- Acrescentar testes Flutter dos contratos HTTP de avaliações, amizades, compatibilidade e convites, usando `http/testing.dart` já incluído na dependência `http`.
- Testar filtragem de jogos avaliados, tipos de avaliação enviados, avanço após sucesso e estado quando a gravação falha no `SwipeController`, usando o cliente HTTP simulado do pacote existente.
- Atualizar README e documentos de `quality/` para refletir comandos, cobertura e lacunas efetivamente verificadas.

## Critérios de sucesso

1. `.\test.ps1` executa Maven e Flutter, sempre reporta o código de saída de ambos, restaura o ambiente mesmo em falha e encerra com código diferente de zero se qualquer suíte falhar.
2. O teste agregado nunca aponta o backend para o banco de desenvolvimento `game_match`; usa apenas `game_match_test`.
3. Testes novos exercitam contratos de método, rota, autenticação, payload e resposta dos serviços Flutter principais sem rede real.
4. Testes do controller de swipe cobrem filtros e transições de estado de sucesso/falha das regras de avaliação, sem exigir alterações de arquitetura apenas para facilitar mocks.
5. A documentação distingue testes existentes, adicionados e pendências restantes; só registra aprovação após executar os comandos correspondentes.

## Fora do escopo

- Adicionar novas bibliotecas de teste ou um novo executor de CI/E2E.
- Executar testes contra IGDB ou banco de desenvolvimento.
- Adicionar cobertura percentual/Métricas sem configuração existente e baseline validado.
- Reescrever todas as telas para facilitar testes de widgets.

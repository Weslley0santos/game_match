# Catálogo offline apresentado como lista concluída

**Prioridade:** P2  
**Data:** 2026-11-18  
**Ambiente:** Flutter Web local, backend Spring Boot e PostgreSQL `game_match_test`; conta descartável.  
**Área:** avaliação de jogos / tratamento de erro do catálogo.

## Pré-condição

Entrar com uma conta de teste que ainda não avaliou todos os jogos. O catálogo contém jogos, e a conexão com o backend está ativa.

## Passos para reproduzir

1. Abrir a aba **Avaliar** e confirmar que um jogo é carregado.
2. Emular a rede offline no navegador.
3. Abrir **Jogos** e confirmar a mensagem de indisponibilidade do backend.
4. Voltar para **Avaliar**, que cria uma nova tela e tenta consultar `GET /games`.

## Resultado esperado

A tela de avaliação informa que não conseguiu consultar o catálogo e permite tentar novamente. Não deve afirmar que todos os jogos foram avaliados.

## Resultado observado

A aba **Jogos** mostra “Não foi possível carregar jogos compatíveis. Verifique se o backend está rodando.”. Na aba **Avaliar**, a falha de `GET /games` é capturada por `SwipeController.loadGames`, que deixa a lista vazia; `SwipeScreen` interpreta a lista vazia como conclusão normal e mostra “Você já avaliou todos os jogos disponíveis.”. O texto atribui a falha de backend ao progresso da conta.

O fluxo foi reproduzido com dois jogos de estado distintos: com rede ativa, os jogos do catálogo apareceram; após avaliar todos os três jogos fixture, a tela mostrou a conclusão esperada; com rede offline antes de recarregar a tela, apareceu a mesma mensagem de conclusão, embora o backend estivesse inacessível. A captura textual do navegador também registrou o estado e os controles “Ver jogos compatíveis”, “Ver amigos” e “Reiniciar avaliação”.

## Impacto

O usuário pode acreditar que terminou de avaliar o catálogo e não perceber que a API está indisponível. O botão “Reiniciar avaliação” repete a consulta, mas a tela não explica a falha nem oferece uma ação explícita de nova tentativa para erro.

## Referências de código

- `frontend/lib/features/swipe/controllers/swipe_controller.dart:40` captura a exceção e só escreve no log.
- `frontend/lib/features/swipe/screens/swipe_screen.dart:75` trata qualquer lista vazia como avaliações concluídas.

## Limites da rodada

QA não alterou o produto. O estado de carregamento foi observado com um atraso temporário de resposta no navegador, restaurado ao fim da validação. Contas, avaliações e amizade descartáveis foram removidas de `game_match_test`; a verificação final retornou zero usuários, avaliações, amizades e convites para os dois IDs. Nenhuma chamada à IGDB foi feita.

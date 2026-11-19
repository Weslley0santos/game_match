# Backlog de implementações futuras

Este backlog transforma as lacunas identificadas em tarefas executáveis. As funcionalidades principais já existem; a exceção é a possível interface administrativa Flutter, que ainda precisa ser confirmada antes de planejar testes de tela para ela.

O QA registrado em `reports/2026-10-25-suite-completa.md` cobriu cadastro/login, avaliações, amizades, compatibilidade e convites; catálogo/admin e isolamento entre contas ficaram parciais.

## Ordem sugerida

1. **P1 — Testes de widget Flutter** para amizades, compatibilidade e convites concluídos; confirmar separadamente se haverá interface administrativa do catálogo.
2. **P1 — Validar persistência com PostgreSQL real** em ambiente isolado, começando por garantir provisionamento e limpeza seguros do banco `game_match_test` — concluído em 2026-11-18.
3. **P2 — Completar QA manual** de catálogo/admin e isolamento entre contas, usando contas descartáveis e registrando apenas falhas, riscos ou decisões relevantes.
4. **P3 — Preparar release Android** quando a distribuição for priorizada; identificar aplicativo e definir assinatura antes de configurar o build.

## Tarefas e critérios de conclusão

### P1 — Testes de widget Flutter

- [x] Mapear estados e ações observáveis em `FriendsScreen` e `GamesScreen`, usando as telas e serviços atuais.
- [x] Cobrir carregamento, erro, sucesso e listas vazias de amizades, compatibilidade e convites; cobrir busca, envio e resposta a solicitações/convites.
- [ ] Confirmar com o responsável pelo produto se haverá uma interface administrativa Flutter. A inspeção não encontrou tela/fluxo de admin; manter essa cobertura pendente até a decisão de produto.
- [x] Manter os testes em `frontend/test/`, usando `flutter_test` e `http/testing.dart` já disponíveis, sem chamadas de rede real.
- [x] Executar `.\test.ps1` e atualizar o inventário: 70 testes Maven e 83 Flutter passaram em 2026-11-18.

Plano: [testes de widget Flutter](plans/2026-11-17-testes-widget-flutter.md).

### P1 — Integração com PostgreSQL

- [x] Definir setup repetível em `game_match_test`, com guarda fail-closed e rollback transacional por caso; não há recriação nem limpeza global.
- [x] Validar V1/V2 do Flyway, validação JPA, email case-insensitive único e FKs existentes de amizade, convite e plataforma.
- [x] Exercitar persistência e recarga de usuários, jogos/plataformas, avaliações, amizade, convite e compatibilidade sem depender da IGDB.
- [x] Executar testes direcionados duas vezes e a suíte agregada (70 Maven e 83 Flutter); atualizar inventário e plano com evidências.

Limitação identificada: a migração atual não declara chaves estrangeiras em `ratings.user_id` e `ratings.game_id`. A integração valida persistência e regras de compatibilidade dessa tabela, mas não inventa uma constraint; avaliar a migração de integridade como tarefa separada antes de aplicá-la a dados existentes.

Plano: [integração PostgreSQL](plans/2026-11-17-integracao-postgresql.md).

### P2 — QA manual de catálogo/admin e isolamento

- [x] Preparar ambiente e contas descartáveis com perfis usuário e administrador em `game_match_test`; contas e jogo temporários foram removidos.
- [x] Percorrer a consulta do catálogo e os estados visuais disponíveis. Dados, carregamento e conclusão das avaliações foram observados; offline, a aba Avaliar exibiu estado vazio como se todos os jogos estivessem avaliados. Defeito P2 registrado em [relatório](reports/2026-11-18-catalogo-offline-mostrado-como-vazio.md). Não há interface admin.
- [x] Completar o QA de isolamento pelo cliente. Leituras/escritas cruzadas foram negadas via API; o compartilhamento positivo apareceu na tela Jogos; logout e login em outra conta confirmaram troca de nome e avaliações independentes.
- [x] Registrar escopo/limitações relevantes sem senhas ou tokens; o defeito observado foi documentado no relatório de QA.

Plano: [QA manual de catálogo e isolamento](plans/2026-11-17-qa-catalogo-isolamento.md).

Correção pendente identificada pelo QA:

- [ ] **P2 — Distinguir erro ao consultar o catálogo de uma lista de jogos já avaliada.** Em falha de `GET /games`, `SwipeScreen` apresenta a mensagem de conclusão normal. Exibir o estado de erro e uma ação de nova tentativa; ver [relatório](reports/2026-11-18-catalogo-offline-mostrado-como-vazio.md).

### P3 — Release Android

- [ ] Confirmar o identificador definitivo do aplicativo e quem controla a chave de assinatura.
- [ ] Definir armazenamento seguro da chave e injeção de segredos sem versionar arquivos ou credenciais.
- [ ] Configurar e validar um build de release assinado e atualizar as instruções de distribuição.
- [ ] Não publicar nem distribuir artefatos como parte desta preparação.

Plano: [preparação do release Android](plans/2026-11-17-release-android.md).

## Referências

- [Plano de testes](test-plan.md)
- [Inventário de testes e lacunas](test-inventory.md)
- [Relatório de suíte e QA de 2026-10-25](reports/2026-10-25-suite-completa.md)
- [Desenho das tarefas e planos futuros](design-future-implementations.md)

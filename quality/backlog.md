# Backlog de implementações futuras

Este backlog transforma as lacunas identificadas em tarefas executáveis. As funcionalidades principais já existem; a exceção é a possível interface administrativa Flutter, que ainda precisa ser confirmada antes de planejar testes de tela para ela.

O QA registrado em `reports/2026-10-25-suite-completa.md` cobriu cadastro/login, avaliações, amizades, compatibilidade e convites; catálogo/admin e isolamento entre contas ficaram parciais.

## Ordem sugerida

1. **P1 — Completar testes de widget Flutter** para amizades, compatibilidade e convites; confirmar se existe ou se será criada uma interface de administração do catálogo antes de incluir essa cobertura.
2. **P1 — Validar persistência com PostgreSQL real** em ambiente isolado, começando por garantir provisionamento e limpeza seguros do banco `game_match_test`.
3. **P2 — Completar QA manual** de catálogo/admin e isolamento entre contas, usando contas descartáveis e registrando apenas falhas, riscos ou decisões relevantes.
4. **P3 — Preparar release Android** quando a distribuição for priorizada; identificar aplicativo e definir assinatura antes de configurar o build.

## Tarefas e critérios de conclusão

### P1 — Testes de widget Flutter

- [ ] Mapear estados e ações observáveis em `FriendsScreen` e `GamesScreen`, usando as telas e serviços atuais.
- [ ] Cobrir carregamento, erro, sucesso e listas vazias de amizades, compatibilidade e convites; cobrir busca, envio e resposta a solicitações/convites.
- [ ] Confirmar com o responsável pelo produto se há uma interface administrativa Flutter a testar. Não inventar comportamento nem marcar cobertura de admin sem uma tela/fluxo existente.
- [ ] Manter os testes em `frontend/test/`, usando `flutter_test` e `http/testing.dart` já disponíveis, sem chamadas de rede real.
- [ ] Executar `flutter test --no-pub` e atualizar o inventário com os casos efetivamente executados.

Plano: [testes de widget Flutter](plans/2026-11-17-testes-widget-flutter.md).

### P1 — Integração com PostgreSQL

- [ ] Definir setup repetível para executar testes de integração exclusivamente em `game_match_test`, com limpeza previsível e proteção contra uso de `game_match`.
- [ ] Validar as migrações Flyway, restrições e relações com PostgreSQL real.
- [ ] Exercitar persistência e recarga de dados nos fluxos de usuário/jogos/avaliações e amizade/convites, sem depender da IGDB.
- [ ] Executar os testes direcionados e a suíte agregada; atualizar inventário e plano de testes com evidências reais.

Plano: [integração PostgreSQL](plans/2026-11-17-integracao-postgresql.md).

### P2 — QA manual de catálogo/admin e isolamento

- [ ] Preparar ambiente e contas descartáveis com perfis usuário e administrador, sempre usando `game_match_test`.
- [ ] Percorrer consulta do catálogo e os fluxos administrativos disponíveis; confirmar a disponibilidade de interface antes de declarar QA de interface concluído.
- [ ] Validar que uma conta não consegue consultar ou alterar dados privados de outra pelos fluxos disponíveis.
- [ ] Registrar evidências reproduzíveis somente para falhas, riscos relevantes ou decisões; não incluir credenciais ou tokens.

Plano: [QA manual de catálogo e isolamento](plans/2026-11-17-qa-catalogo-isolamento.md).

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

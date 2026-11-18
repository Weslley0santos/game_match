# Backlog de implementações

Este arquivo registra as próximas frentes identificadas na análise do projeto. As funcionalidades principais já existem; os itens abaixo tratam principalmente de cobertura, validação e preparação para distribuição.

## Próximas frentes

1. **Cobrir os fluxos no Flutter:** adicionar testes de serviços e de interface para avaliações/swipe, amizades, compatibilidade, convites e administração do catálogo. Incluir estados de carregamento, erro, sucesso e lista vazia conforme aplicável.
2. **Validar integração com PostgreSQL:** cobrir persistência real dos fluxos funcionais em banco isolado, mantendo os dados de desenvolvimento protegidos.
3. **Completar QA manual pela interface:** validar catálogo/admin e isolamento entre contas. O QA anterior cobriu cadastro/login, avaliações, amizades, compatibilidade e convites; catálogo/admin e isolamento ficaram parciais.
4. **Preparar distribuição Android, quando priorizado:** definir o identificador definitivo do aplicativo e a configuração de assinatura de release, hoje indicados por TODOs no projeto Flutter.

## Ordem sugerida

Começar pelos testes dos fluxos Flutter já implementados, depois validar persistência em PostgreSQL e completar o QA manual de catálogo/admin e isolamento. A preparação de release Android pode ser planejada quando houver intenção de distribuir o app.

## Referências

- [Plano de testes](test-plan.md)
- [Inventário de testes e lacunas](test-inventory.md)
- [Relatório da suíte e QA de 2026-10-25](reports/2026-10-25-suite-completa.md)

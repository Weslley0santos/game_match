# Desenho: tarefas e planos para implementações futuras

## Intenção

Transformar as quatro frentes já registradas em `quality/backlog.md` em tarefas priorizáveis e planos independentes. Isso permitirá iniciar cada implementação futura com escopo, arquivos prováveis, sequência de trabalho e critérios de verificação claros.

## Abordagens consideradas

- **Um plano único:** mantém tudo em um documento, mas mistura testes de interface, integração de banco, QA manual e distribuição Android.
- **Planos separados por frente (escolhida):** facilita priorização e execução independente; requer links no backlog para navegar entre tarefas e planos.

A opção escolhida foi separar os planos por frente e manter `quality/backlog.md` como índice de tarefas futuras.

## Escopo proposto

Criar planos separados para:

1. Testes de widget/interação Flutter de amizades, compatibilidade, convites e catálogo/admin, cobrindo carregamento, sucesso, erro e lista vazia onde aplicável.
2. Testes de integração com PostgreSQL para persistência de fluxos funcionais, usando exclusivamente o banco isolado `game_match_test`.
3. QA manual de catálogo/admin e isolamento entre contas, continuando o roteiro e evidências já registrados em `quality/`.
4. Descoberta e preparação de release Android, incluindo decisão do identificador definitivo do aplicativo e configuração de assinatura; não presumir credenciais ou publicar artefatos.

Atualizar o backlog com tarefas verificáveis, prioridade sugerida, dependências conhecidas e links para os planos. Quando uma decisão ou ambiente estiver indefinido, a primeira tarefa do plano deve esclarecer esse ponto antes de implementar.

## Restrições

- Seguir tecnologias, dependências e executores já presentes no projeto; justificar qualquer necessidade nova no respectivo plano.
- Não usar o banco de desenvolvimento `game_match` para testes.
- Não declarar execução, cobertura ou QA concluídos sem evidência.
- Registrar em `quality/` somente lacunas, riscos e decisões relevantes, conforme as instruções existentes.
- Não implementar funcionalidades agora; este trabalho organiza implementações futuras.

## Critério de sucesso

O backlog aponta tarefas priorizadas e rastreáveis, e cada frente tem um plano independente com objetivo, escopo, tarefas com resultados verificáveis, comandos/critério de sucesso quando conhecidos, riscos e pendências de descoberta explícitas.

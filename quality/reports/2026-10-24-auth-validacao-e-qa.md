# Validação de cadastro e login — 2026-10-24

## Achados adversariais e correções

O QA tentou quebrar a validação e encontrou problemas que os testes anteriores não cobriam:

- As telas e a API aceitavam emails como `player@example`, endereços com pontos em posições inválidas, domínios com hífen no início/fim, sublinhado e vírgula. A validação anterior verificava apenas se o email continha `@`.
- O login com email válido e senha ausente consultava o repositório antes de responder `401`.
- Faltava testar valores `null` e campos omitidos no binding HTTP de cadastro.

As telas passaram a compartilhar validadores de nome, email e senha. O frontend e o backend agora rejeitam emails comuns malformados; cadastro responde `400` sem salvar e login responde `401` para email malformado ou senha em branco antes de consultar o usuário. Foram adicionados testes de widget, unitários do validador e do controller, e testes HTTP com MockMvc para cadastro/login.

**Política de email:** a validação implementa um formato ASCII usual para endereços sem aspas. Não pretende cobrir todos os formatos raros da RFC, como parte local entre aspas ou endereço internacionalizado. Nenhuma regra mínima de comprimento de senha foi inventada.

## Verificação final

- `flutter test --no-pub --verbose` em `frontend/`: **passou**, 14 testes, código de saída 0.
- Maven em `backend/`, selecionando `AuthorizationBoundaryTest`, `GameSearchSecurityTest`, `IgdbPropertiesTest`, `GameControllerTest`, `UserAuthenticationFlowTest`, `UserControllerTest` e `IgdbGameServiceTest`: **passou**, 26 testes, 0 falhas e 0 erros.
- `BackendApplicationTests.contextLoads` não foi repetido. Em execução anterior, Flyway falhou ao encontrar o schema PostgreSQL local preenchido sem `flyway_schema_history`; essa verificação exige um banco isolado antes de ser tentada novamente.

## QA e revisão

O QA final confirmou por inspeção que os casos encontrados estão representados nos testes, inclusive campos ausentes/nulos em `POST /users`, e que casos inválidos não salvam nem consultam o repositório conforme os critérios. O Code Reviewer aprovou a alteração dentro do escopo verificado.

O Test Automation Engineer considerou a cobertura adequada para validação de campos e contratos HTTP e recomendou, como próximo passo proporcional, um teste widget do cliente para sucesso/erro até sessão, navegação principal e logout usando um serviço substituível por fake. O projeto não tem executor E2E configurado; não foi recomendada a introdução de Playwright sem decisão específica.

O fluxo completo pela interface — submissão à API, gravação real, sessão e navegação após login — **não foi validado**. Os testes HTTP usam repositório em memória mockado; não comprovam integração com PostgreSQL. A regex também não comprova conformidade total com RFC.

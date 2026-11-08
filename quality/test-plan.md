# Plano de testes

## Objetivo

Definir como verificar os fluxos de maior impacto do Game Match usando as tecnologias e convenções já presentes no repositório. Este plano orienta o trabalho de implementação, QA e revisão; não afirma que os fluxos já estejam cobertos nem que os testes tenham sido executados.

## Escopo

- Cliente Flutter para Android, com execução web indicada pelo README como apoio ao desenvolvimento local.
- API Java 21 com Spring Boot, Spring Security, JPA, PostgreSQL e migrações Flyway.
- Testes de widgets Flutter e testes Java/JUnit já presentes.
- Verificação manual ou automatizada dos fluxos críticos de interface e integração quando houver ambiente e executor apropriados.

Não há evidência de Playwright, Cypress, outra ferramenta E2E, configuração de cobertura ou pipeline de CI. A seleção de ferramenta para E2E deve seguir o executor que o projeto vier a adotar; não se presume Playwright.

## Fluxos críticos

Os fluxos abaixo foram identificados nas telas, serviços e controladores presentes. O inventário de cobertura atual está em [test-inventory.md](test-inventory.md).

1. **Cadastro e login:** validar dados, cadastrar conta, autenticar, guardar a sessão e entrar na navegação principal.
2. **Avaliação de jogos:** carregar jogos, registrar dislike/like/favorito e refletir as avaliações no estado exibido.
3. **Amizades:** enviar solicitação, consultar pendentes, aceitar/rejeitar e consultar amigos.
4. **Compatibilidade:** comparar interesses e mostrar jogos compatíveis e amigos interessados.
5. **Convites para jogar:** permitir envio conforme regra de amizade, listar recebidos/enviados e aceitar/rejeitar convites pendentes.
6. **Catálogo e administração:** consultar jogos e restringir criação, busca e importação da IGDB a administradores.
7. **Isolamento por usuário:** impedir acesso ou alteração de dados de outra conta nas rotas autenticadas.
8. **Inicialização local:** iniciar frontend e backend com configurações válidas e informar indisponibilidades de banco/serviços externos. A inicialização é documentada; sua cobertura automatizada não foi confirmada.

## Regras confirmadas de descoberta e compartilhamento

- Qualquer usuário autenticado pode buscar os demais usuários. A listagem expõe somente ID e nome; visitantes anônimos não acessam essa rota.
- Nas telas e endpoints de compatibilidade entre amigos aceitos, somente avaliações `LIKE` e `FAVORITE` são compartilhadas. `DISLIKE` não deve aparecer nos resultados de compatibilidade ou interesse de amigos.

## Estratégia e critérios de sucesso

- **Testes unitários e de controlador:** validar regras de domínio, mapeamento de erros e fronteiras de autorização com dependências controladas por mocks quando apropriado. Critério: entradas válidas produzem resultado esperado; entradas inválidas e falhas produzem resposta definida sem efeitos de escrita indevidos.
- **Testes de interface Flutter:** verificar conteúdo e estados observáveis das telas, incluindo carregamento, sucesso, erro e ausência de itens. Critério: usuário vê resultado coerente com o estado e as ações levam ao fluxo esperado.
- **Testes de integração:** quando necessários, verificar componentes reais juntos (por exemplo, persistência e migrações) em ambiente isolado e documentar dependências externas. Não há executor/configuração de integração com banco confirmado no inventário atual.
- **Autorização:** rotas protegidas devem rejeitar requisição sem credencial (401); credencial válida sem permissão deve receber 403; recusas de escrita não devem persistir dados.
- **Regras do produto:** convites devem respeitar amizade aceita e estado pendente; importação deve respeitar os critérios de jogo principal e privilégio administrativo.
- **Regressão:** executar a suíte pertinente ao código alterado com o executor documentado e registrar falhas/bloqueios sem declarar aprovado o que não foi executado.
- **Cobertura:** não há meta percentual configurada ou confirmada. Priorizar evidência para os fluxos críticos acima em vez de reportar percentuais inexistentes.

## Responsabilidades e acionamento

- **Agente responsável pela tarefa:** sempre que uma mudança funcional alterar comportamento, implementar os testes unitários correspondentes seguindo tecnologia, executor e locais já existentes. Investigar falhas da suíte relacionadas à mudança e repetir as verificações afetadas. Para mudanças internas sem alteração de comportamento, executar as verificações automáticas relevantes existentes.
- **QA:** acionar quando uma mudança puder alterar comportamento percebido, interface ou integração. QA percorre o fluxo como usuário, explora casos inesperados e registra evidências reproduzíveis sem modificar o produto. Para interface, usar Playwright apenas se o projeto já tiver ou comportar esse executor; caso contrário, escolher abordagem compatível com o ambiente e marcar limites de execução.
- **Code Reviewer:** acionar ao concluir mudanças de código, especialmente mudanças funcionais, ou antes de integrar uma alteração. Deve comparar pedido, critérios, diff, testes e evidências de QA quando aplicáveis, registrando o que passou, falhou, ficou bloqueado ou não foi verificado. Não altera o produto.
- **Test Automation Engineer:** acionar adicionalmente quando a regra for complexa, o fluxo for crítico ou a estrutura de testes mudar. Deve planejar/ampliar cobertura de integração e E2E e ajudar a definir a cobertura; não substitui os testes unitários do agente responsável.

Os resultados devem ser associados a critérios verificáveis, sem declarar aprovação apenas por impressão. Em `quality/reports/`, registrar somente falhas, riscos relevantes ou decisões importantes; não criar relatório para uma rodada normal sem achados relevantes.

## Execução Flutter no sandbox dos agentes

O SDK selecionado é `C:\flutter`, fora da raiz gravável do projeto. A suíte foi aprovada quando executada com acesso elevado; no sandbox padrão, o launcher pode falhar ao acessar `C:\flutter\bin\cache\lockfile`. Para execuções de agentes, use `flutter test --no-pub` com `sandbox_permissions: require_escalated` e justificativa para escrita no cache do SDK. O sinalizador `--no-pub` evita resolver/atualizar dependências do projeto. Se a elevação for negada, registre bloqueio ambiental em vez de falha de teste.

+## Comandos conhecidos

- Backend: `mvn test` em `backend/`, explicitamente documentado no README da raiz.
- Frontend: `flutter test` em `frontend/` é o comando padrão do executor `flutter_test` presente nas dependências, mas não foi encontrado documentado como comando de projeto.
- `flutter analyze` é citado nos comentários de `frontend/analysis_options.yaml` como comando possível do analisador; não é teste automatizado.

Nenhum dos comandos foi executado para elaborar este plano.


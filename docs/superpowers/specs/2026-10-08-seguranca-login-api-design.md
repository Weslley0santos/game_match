# Segurança de login e API — desenho

## Objetivo

Proteger o login e os dados dos usuários antes do deploy, mantendo o Spring Boot como autoridade de autenticação e autorização. O app Android deve continuar oferecendo cadastro, login, amizades, avaliações, compatibilidade e convites.

## Contexto atual

- O cadastro armazena senha em texto puro e o login compara esse valor diretamente.
- O app mantém apenas `userId`, nome e email em memória; a API não recebe uma prova de identidade.
- Várias rotas aceitam IDs de usuário fornecidos pelo cliente e não confirmam propriedade.
- A tela de amigos usa `GET /users` para descobrir outros usuários.
- As rotas de importação e criação de jogos podem alterar o catálogo sem autenticação.

## Desenho aprovado

### Autenticação

- Usar Spring Security, Spring Security Crypto e suporte a JWT Bearer do Spring Security; não integrar Supabase Auth.
- O cadastro grava a senha com BCrypt. A resposta nunca inclui senha ou hash.
- O login público valida a senha com `PasswordEncoder` e retorna os dados seguros do usuário e um JWT assinado pelo backend.
- O token identifica o usuário pelo `sub` com o ID interno e expira em 12 horas. A primeira versão não terá refresh token; expirado o JWT, o app pede novo login.
- A chave de assinatura vem de `JWT_SECRET`, nunca do código, e a aplicação não inicia em modo de produção sem essa configuração.
- O token fica em memória no app, como a sessão atual; logout limpa token e dados do usuário.
- Senhas já existentes no banco local serão preservadas por uma conversão pontual para BCrypt, sem aceitar senhas em texto puro no fluxo normal depois da migração.

### Autorização

- O Spring Security é stateless: cadastro e login são públicos; as demais rotas exigem Bearer token por padrão, exceto leituras públicas explicitamente listadas.
- A identidade do solicitante vem do token validado. IDs de remetente/dono enviados pelo cliente não são fonte de autorização.
- Avaliações, amizades, convites e recomendações só podem ser consultados ou alterados conforme a identidade e os relacionamentos do usuário autenticado.
- Somente o destinatário pode aceitar ou rejeitar uma amizade ou convite.
- `GET /users` exige autenticação e devolve apenas os campos necessários à tela de amigos, sem senha, hash ou email.
- Criar/importar jogos exige papel administrativo. Usuários novos recebem papel `USER`; a promoção inicial de um administrador é feita manualmente pelo operador no banco, sem rota pública de promoção.
- Leitura de jogos e busca IGDB permanecem acessíveis sem login para preservar o fluxo atual de catálogo.

### App Android

- O login guarda o JWT na sessão em memória.
- As chamadas autenticadas enviam `Authorization: Bearer <token>`.
- O app não envia credenciais do banco nem segredo de assinatura; esses segredos ficam no ambiente do backend.

## Fora de escopo

- Supabase Auth, login social, recuperação de senha por email, refresh token, sessões persistentes entre reinicializações do app e gestão de usuários administradores pela interface.
- Alterações na distribuição Android ou no deploy da Vercel.

## Migração e compatibilidade

- Fazer backup do banco local antes da conversão de senhas.
- A conversão pontual deve reconhecer hashes BCrypt já gerados para não aplicar hash duas vezes; após a migração, remover/desativar o conversor.
- Os IDs existentes e as relações de avaliações, amizades e convites permanecem inalterados.
- Rotas atuais podem manter seus formatos quando isso não enfraquecer a autorização; o backend deve rejeitar operações para as quais o token não tem permissão.

## Critérios de aceite

- O backend recusa chamadas protegidas sem token, com token inválido ou expirado.
- Nenhuma senha em texto puro ou hash é retornado pela API.
- Um usuário não consegue ler ou alterar avaliações, amizades ou convites de outro usuário apenas trocando IDs.
- Somente o destinatário pode aceitar/rejeitar solicitações e convites.
- Cadastro/login e os fluxos Android existentes continuam funcionando com token.
- Rotas administrativas não podem ser usadas por contas `USER`.

## Riscos e decisões operacionais

- A migração das senhas deve ocorrer com backup e em banco controlado; não usar fallback que compare texto puro após a conversão.
- Um JWT roubado permanece utilizável até expirar; a expiração de 12 horas limita essa janela, mas a primeira versão não oferece revogação individual nem renovação.
- A proteção de endpoints depende da validação de propriedade no backend; ocultar IDs ou botões no Flutter não substitui essa regra.

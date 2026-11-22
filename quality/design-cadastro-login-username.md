# Especificação do cadastro e login com nome de usuário

## Comportamento

Cadastro e login oferecem dois campos, nome de usuário e senha. O nome de usuário tem de 3 a 32 caracteres e aceita letras ASCII, números e sublinhado. O app e a API aceitam espaços nas pontas e diferenças de caixa. A API guarda o identificador em minúsculas e rejeita duplicatas, inclusive em cadastros concorrentes. A senha mantém os caracteres digitados e aceita até 72 bytes em UTF-8, o limite do BCrypt.

O nome exibido nas contas novas é o nome de usuário normalizado. Contas migradas preservam seu nome de exibição, ID, senha, papel e demais vínculos. Recuperação de senha fica fora desta entrega.

## Contrato

- `POST /users` recebe `{ "username": "Jogador_27", "password": "minha-senha" }`. Sucesso retorna HTTP 200 e `id`, `name` e `username`. Entrada inválida retorna 400 e usuário indisponível retorna 409.
- `POST /users/login` recebe os mesmos campos. Sucesso retorna HTTP 200 com `id`, `name`, `username`, `accessToken`, `tokenType` e `expiresAt`. Credenciais inválidas, usuário inexistente e entrada inválida retornam 401 com mensagem genérica. O limite de tentativas permanece no endpoint.
- O login continua usando BCrypt e emitindo JWT com o ID numérico e o papel já aceitos pela API. O diretório autenticado continua retornando ID e nome de exibição.
- A sessão Flutter usa `username` no lugar de `email`. Após criar a conta, a tela retorna ao login. Duplicata deve produzir uma mensagem específica no cadastro, e senha incorreta deve impedir a entrada.

## Migração e reversão

Flyway V4 acrescenta `users.username`, preenche linhas existentes com `legacy_<id>` (IDs negativos usam `legacy_n<valor absoluto>`) e aplica obrigatoriedade, formato e unicidade no PostgreSQL. A coluna de e-mail anterior é preservada para manter os dados históricos e permitir preparar uma reversão. Novas contas usam somente o nome de usuário na autenticação e deixam essa coluna sem valor.

O banco de desenvolvimento local já teve as contas descartáveis removidas. A migração também funciona com contas em outros ambientes. A associação entre ID e novo login deve ser fornecida a cada titular antes de uma publicação. A troca quebra o contrato dos APKs antigos e exige coordenar a atualização da API e do app. Antes de uma implantação futura, verifique o backup e a estratégia de recuperação. Uma reversão para o código anterior exige liberar a obrigatoriedade de `username` em uma migração posterior ou restaurar o banco anterior. Novas contas sem e-mail não conseguirão usar o login antigo sem migração de dados.

## Validação

Verificar criação, login por outra caixa, senha incorreta, duplicata, entrada inválida, hash de senha e uso do JWT em rota protegida. Em PostgreSQL isolado, verificar V4 com linhas antigas, unicidade no banco e preservação de IDs e vínculos. No Flutter, verificar formulários, JSON, tratamento de falhas e navegação de cadastro e login.

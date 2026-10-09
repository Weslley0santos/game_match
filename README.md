# Game Match

Aplicação para avaliar jogos, encontrar compatibilidades entre amigos e enviar convites para jogar.

O aplicativo continua tendo o Android como plataforma principal. A execução no navegador existe apenas para facilitar o desenvolvimento e os testes locais.

## Pré-requisitos

Antes de iniciar, instale:

- Java 21;
- Maven;
- Flutter;
- PostgreSQL;
- PowerShell 7, recomendado para executar os scripts.

O PostgreSQL precisa estar acessível no endereço que será informado no arquivo `.env`.

## Primeira configuração

Na raiz do projeto, crie o arquivo local de configuração a partir do exemplo:

```powershell
Copy-Item .env.example .env
```

Abra o arquivo `.env` e preencha as configurações do seu banco local:

```env
POSTGRES_DB=game_match
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/game_match
SPRING_DATASOURCE_USERNAME=seu_usuario_local
SPRING_DATASOURCE_PASSWORD=sua_senha_local
```

Para utilizar a importação de jogos, preencha também as credenciais da aplicação cadastrada na Twitch/IGDB:

```env
IGDB_CLIENT_ID=seu_client_id
IGDB_CLIENT_SECRET=seu_client_secret
```

Defina tambÃ©m `JWT_SECRET` no `.env`. Gere uma chave aleatÃ³ria com 32 bytes e codifique em Base64 no PowerShell:

```powershell
$bytes = [byte[]]::new(32)
[System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
[Convert]::ToBase64String($bytes)
```

Copie o resultado para `JWT_SECRET`. O backend exige essa chave para iniciar; mantenha-a privada e estÃ¡vel, pois trocÃ¡-la invalida todas as sessÃµes ativas. O login retorna um token JWT com validade de 12 horas. Quando expirar, entre novamente.

### Migração das senhas existentes

Neste banco local, a migração para BCrypt foi concluída e o login após a migração foi validado. A ferramenta usada nessa conversão pontual foi removida do código. Se outro banco com senhas legadas for conectado ao backend, planeje uma migração específica com backup antes de usá-lo; não execute uma migração manual no fluxo normal da aplicação.

Para conceder acesso administrativo a uma conta, altere manualmente seu papel no banco apÃ³s verificar o email:

```sql
UPDATE users SET role = 'ADMIN' WHERE email = 'email-verificado@example.com';
```

Novas contas recebem apenas o papel `USER`. O papel `ADMIN` Ã© necessÃ¡rio para criar jogos e importar jogos da IGDB.

Não compartilhe nem faça commit do `.env`. O arquivo já está ignorado pelo Git. O `README.md` e o `.env.example` contêm somente exemplos, nunca credenciais reais.

## Iniciar a aplicação

Abra o PowerShell na raiz do projeto e execute:

```powershell
.\start-dev.ps1
```

Se a política de execução do Windows bloquear o arquivo, use:

```powershell
pwsh -NoProfile -File .\start-dev.ps1
```

O script:

- verifica PostgreSQL, Maven, Flutter e o `.env`;
- verifica se as portas necessárias estão disponíveis;
- inicia o backend Spring Boot;
- inicia o Flutter Web para testes;
- aguarda os dois serviços responderem antes de terminar.

Depois da inicialização, acesse:

- Aplicação: [http://localhost:3000](http://localhost:3000);
- Backend: [http://localhost:8080](http://localhost:8080).

Executar `start-dev.ps1` novamente não cria processos duplicados.

## Parar a aplicação

Na raiz do projeto, execute:

```powershell
.\stop-dev.ps1
```

Ou, se necessário:

```powershell
pwsh -NoProfile -File .\stop-dev.ps1
```

O script encerra somente os processos registrados pelo `start-dev.ps1`. O PostgreSQL e processos externos não são encerrados.

## Logs

Os logs e o arquivo temporário com os processos ficam na pasta `.dev/`:

- `.dev/backend.out.log`;
- `.dev/backend.err.log`;
- `.dev/frontend.out.log`;
- `.dev/frontend.err.log`.

Essa pasta é local e está ignorada pelo Git.

## Problemas comuns

### PostgreSQL indisponível

Confirme que o serviço está iniciado e aceitando conexões na porta `5432`.

### Porta 8080 ou 3000 ocupada

O script não encerra processos desconhecidos. Feche o programa que está usando a porta, libere as portas `8080` e `3000` e execute novamente.

### Importação da IGDB indisponível

Confirme que `IGDB_CLIENT_ID` e `IGDB_CLIENT_SECRET` pertencem à mesma aplicação cadastrada na Twitch e reinicie o ambiente.

## Executar os testes do backend

```powershell
cd backend
mvn test
```

## Limite de tentativas de login

A API permite ate 10 tentativas de login por IP a cada 15 minutos. A tentativa seguinte recebe HTTP 429; um login bem-sucedido limpa o contador.

## Logs do backend

Cada requisição gera uma linha `http_request` com `requestId`, método, caminho, status HTTP e duração. O mesmo identificador vai no header `X-Request-Id` da resposta e no prefixo das mensagens da aplicação durante a requisição. Corpos, query strings, headers de autenticação, senhas, tokens e IPs não são registrados.

O SQL do Hibernate fica desligado por padrão. Para investigar consultas localmente, adicione `HIBERNATE_SQL_LOG_LEVEL=DEBUG` ao `.env` e reinicie o backend. Depois da investigação, remova a variável ou defina-a como `OFF`. Os valores dos parâmetros SQL continuam ocultos.

### Ordem de rollout antes de produção

1. Fazer backup dos bancos de origem e destino.
2. Confirmar que as senhas do banco de destino já estão em BCrypt; se houver senhas legadas em texto puro, planejar uma conversão pontual com backup antes de conectar a API protegida.
3. Configurar `JWT_SECRET` e as credenciais do banco no ambiente de hospedagem e implantar o backend protegido.
4. Atualizar a URL da API no app Android, gerar uma nova build e validar login e chamadas autenticadas.

## Android

O navegador é apenas um ambiente de teste. No emulador Android, o backend local continua sendo acessado pelo endereço `http://10.0.2.2:8080`.

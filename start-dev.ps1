[CmdletBinding()]
param(
    [int]$BackendPort = 8080,
    [int]$FrontendPort = 3000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$backendDirectory = Join-Path $projectRoot 'backend'
$frontendDirectory = Join-Path $projectRoot 'frontend'
$stateDirectory = Join-Path $projectRoot '.dev'
$stateFile = Join-Path $stateDirectory 'processes.json'
$backendOutputLog = Join-Path $stateDirectory 'backend.out.log'
$backendErrorLog = Join-Path $stateDirectory 'backend.err.log'
$frontendOutputLog = Join-Path $stateDirectory 'frontend.out.log'
$frontendErrorLog = Join-Path $stateDirectory 'frontend.err.log'
$backendUrl = "http://localhost:$BackendPort/games"
$frontendUrl = "http://localhost:$FrontendPort"

function Write-Status {
    param(
        [string]$Label,
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    Write-Host ("{0,-12} {1}" -f "${Label}:", $Message) -ForegroundColor $Color
}

function Test-TcpPort {
    param(
        [string]$HostName,
        [int]$Port,
        [int]$TimeoutMilliseconds = 1500
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $connection = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $connection.AsyncWaitHandle.WaitOne($TimeoutMilliseconds)) {
            return $false
        }

        $client.EndConnect($connection)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $client.Dispose()
    }
}

function Test-HttpEndpoint {
    param(
        [string]$Uri,
        [int]$TimeoutSeconds = 3
    )

    try {
        $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec $TimeoutSeconds
        return $response.StatusCode -ge 200 -and $response.StatusCode -lt 400
    }
    catch {
        return $false
    }
}

function Wait-HttpEndpoint {
    param(
        [string]$Uri,
        [int]$TimeoutSeconds
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        if (Test-HttpEndpoint -Uri $Uri) {
            return $true
        }

        Start-Sleep -Seconds 1
    } while ([DateTime]::UtcNow -lt $deadline)

    return $false
}

function Get-DotEnvValue {
    param(
        [string[]]$Lines,
        [string]$Name
    )

    $matchingLine = $Lines |
        Where-Object { $_ -match "^\s*$([Regex]::Escape($Name))\s*=" } |
        Select-Object -First 1

    if ($null -eq $matchingLine) {
        return ''
    }

    $value = ($matchingLine -replace "^\s*$([Regex]::Escape($Name))\s*=", '').Trim()
    if ($value.Length -ge 2) {
        $firstCharacter = $value[0]
        $lastCharacter = $value[$value.Length - 1]
        if (($firstCharacter -eq '"' -and $lastCharacter -eq '"') -or
            ($firstCharacter -eq "'" -and $lastCharacter -eq "'")) {
            $value = $value.Substring(1, $value.Length - 2).Trim()
        }
    }

    return $value
}

function Test-RecordedProcess {
    param($Record)

    if ($null -eq $Record -or -not $Record.managed -or $null -eq $Record.pid) {
        return $false
    }

    try {
        $process = Get-Process -Id ([int]$Record.pid) -ErrorAction Stop
        if ($null -ne $Record.PSObject.Properties['startedAtUtcTicks']) {
            $expectedStartTicks = [long]$Record.startedAtUtcTicks
        }
        elseif ($Record.startedAtUtc -is [DateTime]) {
            $expectedStartTicks = $Record.startedAtUtc.ToUniversalTime().Ticks
        }
        else {
            $expectedStartTicks = [DateTime]::Parse(
                [string]$Record.startedAtUtc,
                [Globalization.CultureInfo]::InvariantCulture,
                [Globalization.DateTimeStyles]::RoundtripKind
            ).ToUniversalTime().Ticks
        }

        $actualStartTicks = $process.StartTime.ToUniversalTime().Ticks
        $sameStartTime = [Math]::Abs($actualStartTicks - $expectedStartTicks) -lt (2 * [TimeSpan]::TicksPerSecond)
        return $sameStartTime -and $process.ProcessName -eq [string]$Record.processName
    }
    catch {
        return $false
    }
}

function Stop-StartedProcessTree {
    param([System.Diagnostics.Process]$Process)

    if ($null -eq $Process) {
        return
    }

    try {
        if (-not $Process.HasExited) {
            & "$env:SystemRoot\System32\taskkill.exe" /PID $Process.Id /T /F *> $null
        }
    }
    catch {
        Write-Warning "Não foi possível limpar o processo $($Process.Id) após a falha de inicialização."
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $backendDirectory 'pom.xml'))) {
    throw 'backend/pom.xml não foi encontrado. Execute o script na cópia correta do projeto.'
}

if (-not (Test-Path -LiteralPath (Join-Path $frontendDirectory 'pubspec.yaml'))) {
    throw 'frontend/pubspec.yaml não foi encontrado. Execute o script na cópia correta do projeto.'
}

New-Item -ItemType Directory -Path $stateDirectory -Force | Out-Null

if (Test-Path -LiteralPath $stateFile) {
    try {
        $previousState = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
        $hasRunningManagedProcess = (Test-RecordedProcess -Record $previousState.backend) -or
            (Test-RecordedProcess -Record $previousState.frontend)

        if ($hasRunningManagedProcess) {
            Write-Status -Label 'Ambiente' -Message 'já foi iniciado por este script.' -Color Yellow
            Write-Status -Label 'Backend' -Message $(if (Test-HttpEndpoint -Uri $backendUrl) { $backendUrl } else { 'processo ativo, mas sem resposta HTTP' })
            Write-Status -Label 'Frontend' -Message $(if (Test-HttpEndpoint -Uri $frontendUrl) { $frontendUrl } else { 'processo ativo, mas sem resposta HTTP' })
            Write-Host 'Use .\stop-dev.ps1 antes de iniciar novamente.'
            exit 0
        }
    }
    catch {
        Write-Warning 'O estado anterior não pôde ser lido e será substituído.'
    }

    Remove-Item -LiteralPath $stateFile -Force
}

$mavenCommand = Get-Command mvn -ErrorAction Stop
$flutterCommand = Get-Command flutter -ErrorAction Stop

$envFile = Join-Path $projectRoot '.env'
if (-not (Test-Path -LiteralPath $envFile)) {
    throw 'O arquivo .env não foi encontrado. Copie .env.example para .env e preencha as configurações.'
}

$envLines = Get-Content -LiteralPath $envFile
$requiredDatabaseVariables = @(
    'SPRING_DATASOURCE_URL',
    'SPRING_DATASOURCE_USERNAME',
    'SPRING_DATASOURCE_PASSWORD'
)
$missingDatabaseVariables = @(
    $requiredDatabaseVariables | Where-Object {
        [string]::IsNullOrWhiteSpace((Get-DotEnvValue -Lines $envLines -Name $_))
    }
)

if ($missingDatabaseVariables.Count -gt 0) {
    throw "Preencha no .env as configurações obrigatórias do banco: $($missingDatabaseVariables -join ', ')."
}

$datasourceUrl = Get-DotEnvValue -Lines $envLines -Name 'SPRING_DATASOURCE_URL'
if ($datasourceUrl -notmatch '^jdbc:postgresql://(?<host>\[[^\]]+\]|[^:/?#]+)(?::(?<port>\d+))?/(?<database>[^?]+)') {
    throw 'SPRING_DATASOURCE_URL deve usar o formato jdbc:postgresql://host:porta/banco.'
}

$databaseHost = $Matches['host'].Trim('[', ']')
$databasePort = if ([string]::IsNullOrWhiteSpace($Matches['port'])) { 5432 } else { [int]$Matches['port'] }
if (-not (Test-TcpPort -HostName $databaseHost -Port $databasePort)) {
    throw "PostgreSQL não está acessível em ${databaseHost}:$databasePort. Verifique o serviço e o SPRING_DATASOURCE_URL do .env."
}
Write-Status -Label 'PostgreSQL' -Message "${databaseHost}:$databasePort OK" -Color Green

$hasClientId = -not [string]::IsNullOrWhiteSpace((Get-DotEnvValue -Lines $envLines -Name 'IGDB_CLIENT_ID'))
$hasClientSecret = -not [string]::IsNullOrWhiteSpace((Get-DotEnvValue -Lines $envLines -Name 'IGDB_CLIENT_SECRET'))
if ($hasClientId -and $hasClientSecret) {
    Write-Status -Label 'IGDB' -Message 'credenciais encontradas' -Color Green
}
else {
    Write-Status -Label 'IGDB' -Message 'credenciais incompletas; importações ficarão indisponíveis' -Color Yellow
}

$backendProcess = $null
$frontendProcess = $null
$backendManaged = $false
$frontendManaged = $false

try {
    if (Test-HttpEndpoint -Uri $backendUrl) {
        Write-Status -Label 'Backend' -Message "já estava disponível em $backendUrl" -Color Yellow
    }
    elseif (Test-TcpPort -HostName 'localhost' -Port $BackendPort) {
        throw "A porta $BackendPort está ocupada por outro serviço que não respondeu como o backend do GameMatch."
    }
    else {
        $backendProcess = Start-Process `
            -FilePath $mavenCommand.Source `
            -ArgumentList @('-q', 'spring-boot:run') `
            -WorkingDirectory $backendDirectory `
            -WindowStyle Hidden `
            -RedirectStandardOutput $backendOutputLog `
            -RedirectStandardError $backendErrorLog `
            -PassThru
        $backendManaged = $true

        if (-not (Wait-HttpEndpoint -Uri $backendUrl -TimeoutSeconds 90)) {
            throw "O backend não respondeu em até 90 segundos. Consulte $backendErrorLog e $backendOutputLog."
        }
        Write-Status -Label 'Backend' -Message $backendUrl -Color Green
    }

    if (Test-HttpEndpoint -Uri $frontendUrl) {
        Write-Status -Label 'Frontend' -Message "já estava disponível em $frontendUrl" -Color Yellow
    }
    elseif (Test-TcpPort -HostName 'localhost' -Port $FrontendPort) {
        throw "A porta $FrontendPort está ocupada por outro serviço que não respondeu como o frontend do GameMatch."
    }
    else {
        $frontendProcess = Start-Process `
            -FilePath $flutterCommand.Source `
            -ArgumentList @('run', '-d', 'web-server', '--web-hostname=127.0.0.1', "--web-port=$FrontendPort") `
            -WorkingDirectory $frontendDirectory `
            -WindowStyle Hidden `
            -RedirectStandardOutput $frontendOutputLog `
            -RedirectStandardError $frontendErrorLog `
            -PassThru
        $frontendManaged = $true

        if (-not (Wait-HttpEndpoint -Uri $frontendUrl -TimeoutSeconds 180)) {
            throw "O frontend não respondeu em até 180 segundos. Consulte $frontendErrorLog e $frontendOutputLog."
        }
        Write-Status -Label 'Frontend' -Message $frontendUrl -Color Green
    }

    $state = [ordered]@{
        version = 1
        projectRoot = $projectRoot
        createdAtUtc = [DateTime]::UtcNow.ToString('o')
        backend = [ordered]@{
            managed = $backendManaged
            pid = if ($backendManaged) { $backendProcess.Id } else { $null }
            processName = if ($backendManaged) { $backendProcess.ProcessName } else { $null }
            startedAtUtc = if ($backendManaged) { $backendProcess.StartTime.ToUniversalTime().ToString('o') } else { $null }
            startedAtUtcTicks = if ($backendManaged) { $backendProcess.StartTime.ToUniversalTime().Ticks } else { $null }
            url = $backendUrl
        }
        frontend = [ordered]@{
            managed = $frontendManaged
            pid = if ($frontendManaged) { $frontendProcess.Id } else { $null }
            processName = if ($frontendManaged) { $frontendProcess.ProcessName } else { $null }
            startedAtUtc = if ($frontendManaged) { $frontendProcess.StartTime.ToUniversalTime().ToString('o') } else { $null }
            startedAtUtcTicks = if ($frontendManaged) { $frontendProcess.StartTime.ToUniversalTime().Ticks } else { $null }
            url = $frontendUrl
        }
    }

    $state | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $stateFile -Encoding UTF8

    Write-Host ''
    Write-Host 'Ambiente local iniciado com sucesso.' -ForegroundColor Green
    Write-Host "Abra $frontendUrl no navegador."
    Write-Host 'Para encerrar os processos iniciados pelo script, execute .\stop-dev.ps1.'
}
catch {
    if ($frontendManaged) {
        Stop-StartedProcessTree -Process $frontendProcess
    }
    if ($backendManaged) {
        Stop-StartedProcessTree -Process $backendProcess
    }
    if (Test-Path -LiteralPath $stateFile) {
        Remove-Item -LiteralPath $stateFile -Force
    }
    throw
}

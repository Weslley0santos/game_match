# Execute na raiz do projeto com: .\test.ps1
# Usa o banco isolado game_match_test para o backend e executa a suíte Flutter.
$ErrorActionPreference = 'Stop'

$rootPath = $PSScriptRoot
$envFilePath = Join-Path $rootPath '.env'

if (-not (Test-Path -LiteralPath $envFilePath)) {
    throw "Arquivo .env não encontrado em $rootPath. Crie-o a partir de .env.example e configure as credenciais locais do PostgreSQL."
}

$settings = @{}
foreach ($line in Get-Content -LiteralPath $envFilePath) {
    if ($line -match '^\s*(?<key>[^#=\s]+)\s*=\s*(?<value>.*)\s*$') {
        $value = $Matches['value'].Trim()
        if ($value.Length -ge 2 -and (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'")))) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        $settings[$Matches['key']] = $value
    }
}

foreach ($requiredSetting in @('SPRING_DATASOURCE_USERNAME', 'SPRING_DATASOURCE_PASSWORD')) {
    if ([string]::IsNullOrWhiteSpace($settings[$requiredSetting])) {
        throw "A configuração $requiredSetting está ausente ou vazia no .env."
    }
}

$testDatabaseUrl = 'jdbc:postgresql://localhost:5432/game_match_test'
$environmentNames = @(
    'SPRING_DATASOURCE_URL',
    'SPRING_DATASOURCE_USERNAME',
    'SPRING_DATASOURCE_PASSWORD'
)
$previousEnvironment = @{}
foreach ($name in $environmentNames) {
    $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}

$backendExitCode = 1
$flutterExitCode = 1

try {
    $env:SPRING_DATASOURCE_URL = $testDatabaseUrl
    $env:SPRING_DATASOURCE_USERNAME = $settings['SPRING_DATASOURCE_USERNAME']
    $env:SPRING_DATASOURCE_PASSWORD = $settings['SPRING_DATASOURCE_PASSWORD']

    Write-Host "Executando testes do backend em game_match_test..." -ForegroundColor Cyan
    Push-Location (Join-Path $rootPath 'backend')
    try {
        & .\mvnw.cmd test
        $backendExitCode = $LASTEXITCODE
    }
    catch {
        Write-Host "Falha ao iniciar os testes do backend: $($_.Exception.Message)" -ForegroundColor Red
        $backendExitCode = 1
    }
    finally {
        Pop-Location
    }

    Write-Host "Executando testes do Flutter..." -ForegroundColor Cyan
    Push-Location (Join-Path $rootPath 'frontend')
    try {
        & flutter test --no-pub --verbose
        $flutterExitCode = $LASTEXITCODE
    }
    catch {
        Write-Host "Falha ao iniciar os testes do Flutter: $($_.Exception.Message)" -ForegroundColor Red
        $flutterExitCode = 1
    }
    finally {
        Pop-Location
    }
}
finally {
    foreach ($name in $environmentNames) {
        if ($null -eq $previousEnvironment[$name]) {
            Remove-Item "Env:$name" -ErrorAction SilentlyContinue
        }
        else {
            [Environment]::SetEnvironmentVariable($name, $previousEnvironment[$name], 'Process')
        }
    }
}

Write-Host ''
Write-Host "Backend exit code: $backendExitCode"
Write-Host "Flutter exit code: $flutterExitCode"

if ($backendExitCode -ne 0 -or $flutterExitCode -ne 0) {
    exit 1
}

Write-Host 'Todas as suítes passaram.' -ForegroundColor Green
exit 0

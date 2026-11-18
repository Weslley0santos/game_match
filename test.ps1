# Execute na raiz do projeto com: .\test.ps1
# Usa o banco isolado game_match_test para o backend e executa a suíte Flutter.
$ErrorActionPreference = 'Stop'

$rootPath = $PSScriptRoot
$envFilePath = Join-Path $rootPath '.env'
$backendPath = Join-Path $rootPath 'backend'
$frontendPath = Join-Path $rootPath 'frontend'
$mavenWrapperPath = Join-Path $backendPath 'mvnw.cmd'
$testDatabaseName = 'game_match_test'
$testDatabaseUrl = "jdbc:postgresql://localhost:5432/$testDatabaseName"
$mavenIssues = [System.Collections.Generic.List[string]]::new()
$flutterIssue = $null
$settings = @{}
$settingsFileLoaded = $false

if (-not (Test-Path -LiteralPath $envFilePath)) {
    $mavenIssues.Add("Arquivo .env não encontrado em $rootPath. Crie-o a partir de .env.example e configure as credenciais PostgreSQL.")
}
else {
    try {
        foreach ($line in Get-Content -LiteralPath $envFilePath) {
            if ($line -match '^\s*(?<key>[^#=\s]+)\s*=\s*(?<value>.*)\s*$') {
                $value = $Matches['value'].Trim()
                if ($value.Length -ge 2 -and (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'")))) {
                    $value = $value.Substring(1, $value.Length - 2)
                }
                $settings[$Matches['key']] = $value
            }
        }
        $settingsFileLoaded = $true
    }
    catch {
        $mavenIssues.Add("Não foi possível ler o arquivo .env: $($_.Exception.Message)")
    }
}

if ($settingsFileLoaded) {
    foreach ($requiredSetting in @('SPRING_DATASOURCE_USERNAME', 'SPRING_DATASOURCE_PASSWORD')) {
        if ([string]::IsNullOrWhiteSpace($settings[$requiredSetting])) {
            $mavenIssues.Add("A configuração $requiredSetting está ausente ou vazia no .env.")
        }
    }
}

if (-not (Test-Path -LiteralPath $mavenWrapperPath)) {
    $mavenIssues.Add("Maven Wrapper não encontrado em $mavenWrapperPath.")
}

$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCommand) {
    $flutterIssue = 'Flutter não encontrado no PATH.'
}

$environmentNames = @(
    'SPRING_DATASOURCE_URL',
    'SPRING_DATASOURCE_USERNAME',
    'SPRING_DATASOURCE_PASSWORD'
)
$previousEnvironment = @{}
foreach ($name in $environmentNames) {
    $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}

$mavenExitCode = 1
$flutterExitCode = 1

try {
    if ($mavenIssues.Count -gt 0) {
        Write-Host "Maven não executado: $($mavenIssues -join ' ')" -ForegroundColor Red
    }
    else {
        $env:SPRING_DATASOURCE_URL = $testDatabaseUrl
        $env:SPRING_DATASOURCE_USERNAME = $settings['SPRING_DATASOURCE_USERNAME']
        $env:SPRING_DATASOURCE_PASSWORD = $settings['SPRING_DATASOURCE_PASSWORD']

        Write-Host "Executando Maven: .\mvnw.cmd --batch-mode --no-transfer-progress test (banco $testDatabaseName)..." -ForegroundColor Cyan
        Push-Location $backendPath
        try {
            & $mavenWrapperPath --batch-mode --no-transfer-progress test
            $mavenExitCode = $LASTEXITCODE
        }
        catch {
            Write-Host "Falha ao iniciar os testes do Maven: $($_.Exception.Message)" -ForegroundColor Red
            $mavenExitCode = 1
        }
        finally {
            Pop-Location
        }
    }

    if ($flutterIssue) {
        Write-Host "Flutter não executado: $flutterIssue" -ForegroundColor Red
    }
    else {
        Write-Host 'Executando Flutter: flutter test --no-pub...' -ForegroundColor Cyan
        Push-Location $frontendPath
        try {
            & flutter test --no-pub
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
$mavenStatus = if ($mavenExitCode -eq 0) { 'PASS' } else { 'FAIL' }
$flutterStatus = if ($flutterExitCode -eq 0) { 'PASS' } else { 'FAIL' }

Write-Host "Maven: $mavenStatus (exit code $mavenExitCode)"
Write-Host "Flutter: $flutterStatus (exit code $flutterExitCode)"

if ($mavenExitCode -ne 0 -or $flutterExitCode -ne 0) {
    Write-Host 'Uma ou mais suítes falharam.' -ForegroundColor Red
    exit 1
}

Write-Host 'Todas as suítes passaram.' -ForegroundColor Green
exit 0

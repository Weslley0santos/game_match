[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$stateFile = Join-Path (Join-Path $projectRoot '.dev') 'processes.json'

function Write-Status {
    param(
        [string]$Label,
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    Write-Host ("{0,-12} {1}" -f "${Label}:", $Message) -ForegroundColor $Color
}

function Stop-RecordedProcess {
    param(
        [string]$Label,
        $Record
    )

    if ($null -eq $Record -or -not $Record.managed -or $null -eq $Record.pid) {
        Write-Status -Label $Label -Message 'não foi iniciado pelo script; mantido em execução' -Color Yellow
        return $true
    }

    $processId = [int]$Record.pid
    try {
        $process = Get-Process -Id $processId -ErrorAction Stop
    }
    catch {
        Write-Status -Label $Label -Message "processo $processId já estava encerrado" -Color Yellow
        return $true
    }

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
    $sameProcessName = $process.ProcessName -eq [string]$Record.processName

    if (-not $sameStartTime -or -not $sameProcessName) {
        Write-Warning "$Label usa agora um PID reaproveitado. O processo $processId não será encerrado."
        return $false
    }

    & "$env:SystemRoot\System32\taskkill.exe" /PID $processId /T /F *> $null
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    do {
        Start-Sleep -Milliseconds 250
        $stillRunning = $null -ne (Get-Process -Id $processId -ErrorAction SilentlyContinue)
    } while ($stillRunning -and [DateTime]::UtcNow -lt $deadline)

    if ($stillRunning) {
        Write-Warning "$Label não foi encerrado dentro do tempo esperado."
        return $false
    }

    Write-Status -Label $Label -Message "processo $processId encerrado" -Color Green
    return $true
}

if (-not (Test-Path -LiteralPath $stateFile)) {
    Write-Host 'Nenhum ambiente iniciado por start-dev.ps1 foi encontrado.' -ForegroundColor Yellow
    exit 0
}

$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
if ([string]$state.projectRoot -ne $projectRoot) {
    throw 'O arquivo de estado pertence a outra cópia do projeto e não será utilizado.'
}

$frontendStopped = Stop-RecordedProcess -Label 'Frontend' -Record $state.frontend
$backendStopped = Stop-RecordedProcess -Label 'Backend' -Record $state.backend

if ($frontendStopped -and $backendStopped) {
    Remove-Item -LiteralPath $stateFile -Force
    Write-Host ''
    Write-Host 'Ambiente local encerrado com segurança.' -ForegroundColor Green
}
else {
    Write-Warning "Nem todos os processos puderam ser encerrados. O estado foi mantido em $stateFile."
    exit 1
}

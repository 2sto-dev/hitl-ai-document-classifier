$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendRoot = Join-Path $projectRoot 'backend'
$flutterRoot = Join-Path $projectRoot 'flutter_app\hitl_flutter'
$pythonPath = Join-Path $backendRoot 'venv\Scripts\python.exe'
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue

if (-not (Test-Path $pythonPath)) {
    $pythonPath = Join-Path $projectRoot '.venv\Scripts\python.exe'
}

if (-not (Test-Path $pythonPath)) {
    throw 'Python virtual environment not found.'
}

if (-not $flutterCommand) {
    throw 'Flutter was not found on PATH.'
}
$flutterPath = $flutterCommand.Source

$ollamaCommand = Get-Command ollama -ErrorAction SilentlyContinue
try {
    Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 2 | Out-Null
} catch {
    if (-not $ollamaCommand) {
        throw 'Ollama is required for document summaries but was not found.'
    }
    Start-Process -FilePath $ollamaCommand.Source `
        -ArgumentList 'serve' `
        -WindowStyle Hidden
    Start-Sleep -Seconds 2
}

Start-Process -FilePath $pythonPath `
    -ArgumentList 'manage.py', 'runserver', '127.0.0.1:8000', '--noreload' `
    -WorkingDirectory $backendRoot `
    -WindowStyle Hidden

Start-Sleep -Seconds 2

Write-Host 'Local backend started at http://127.0.0.1:8000' -ForegroundColor Green
Write-Host 'Ollama summaries enabled with phi3:latest.' -ForegroundColor Green
Write-Host 'Starting Flutter in offline/local mode. Press q to stop Flutter.'

& $flutterPath run -d web-server `
    --web-hostname 127.0.0.1 `
    --dart-define=API_BASE_URL=http://127.0.0.1:8000/api

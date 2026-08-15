$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendRoot = Join-Path $projectRoot 'backend'
$pythonPath = Join-Path $backendRoot 'venv\Scripts\python.exe'
$ngrokPath = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\ngrok.exe'
$demoDomain = 'https://sublabial-unpondered-tiffanie.ngrok-free.dev'
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

Start-Process -FilePath $ngrokPath `
    -ArgumentList 'http', '8000', '--url', $demoDomain `
    -WindowStyle Hidden

Write-Host "Demo started: $demoDomain" -ForegroundColor Magenta
Write-Host 'Ollama summaries enabled with phi3:latest.' -ForegroundColor Green
Write-Host 'Keep this laptop connected to the phone hotspot and keep ngrok running.'

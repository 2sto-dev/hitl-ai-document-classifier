$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendRoot = Join-Path $projectRoot 'backend'
$pythonPath = Join-Path $backendRoot 'venv\Scripts\python.exe'

Push-Location $backendRoot
try {
    & $pythonPath manage.py test --settings=core.settings_test @args
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}

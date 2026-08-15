@echo off
setlocal
cd /d "%~dp0backend"
"%~dp0backend\venv\Scripts\python.exe" manage.py test --settings=core.settings_test %*
exit /b %ERRORLEVEL%

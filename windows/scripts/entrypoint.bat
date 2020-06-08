@echo off

@echo =======================================================
@echo          ____        __        ____
@echo         / __ \____ _/ /_____ _/ __ \____  ____ _
@echo        / / / / __ `/ __/ __ `/ / / / __ \/ __ `/
@echo       / /_/ / /_/ / /_/ /_/ / /_/ / /_/ / /_/ /
@echo      /_____/\__,_/\__/\__,_/_____/\____/\__, /
@echo                                        /____/
@echo =======================================================
@echo.
@echo Agent Windows Build Docker Container

@echo AWS_NETWORKING is %AWS_NETWORKING%
if defined AWS_NETWORKING (
    @echo Detected AWS container, setting up networking
    powershell -C "c:\scripts\aws_networking.ps1"
)
%*
exit /b %ERRORLEVEL%

# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host -ForegroundColor Green "Running RIDK Install"
##  create output directory for stdout
new-item -Path c:\ -Name tmp -force -ItemType Directory

$processparams = @{
    FilePath = "powershell"
    NoNewWindow = $true
    Wait = $true
    ArgumentList = "-C ridk install 2 3"
    RedirectStandardError = "c:\tmp\ridk_stderr.txt"
    RedirectStandardOutput = "c:\tmp\ridk_stdout.txt"
}

Start-Process @processparams

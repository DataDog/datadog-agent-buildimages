param (
    [Parameter(Mandatory=$true)][string]$Version
)
$InstallPath = "c:\tools"
<#
.SYNOPSIS
 Invoke-Msys2Shell  Runs the shell once to do first-time startup.  

.NOTES
Taken from chocolatey installer.
#>
function Invoke-Msys2Shell($Arguments) {
    if (![string]::IsNullOrWhiteSpace($Arguments)) { $Arguments += "; " }
    $Arguments += "ps -ef | grep '[?]' | awk '{print `$2}' | xargs -r kill"
    $basepath = Join-Path $InstallPath msys64

    $params = @{
        FilePath     = Join-Path $basepath msys2_shell.cmd
        NoNewWindow  = $true
        Wait         = $true
        ArgumentList = "-defterm", "-no-start", "-c", "`"$Arguments`""
    }
    Write-Host "Invoking msys2 shell command:" $params.ArgumentList
    Start-Process @params
}
# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20200629.tar.xz
$splitver = $Version.split(".")
$msysver = "$($splitver[0])" 

$msyszip = "http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-$($msysver).tar.xz"

Write-Host  -ForegroundColor Green starting with MSYS
$out = "$($PSScriptRoot)\msys.tar.xz"
(New-Object System.Net.WebClient).DownloadFile($msyszip, $out)

# uncompress the tar-xz into a tar
$msystar = "msys.tar"
& 7z x $out
start-process 7z -ArgumentList "x -o$($InstallPath) $msystar" -Wait

Remove-Item $out
Remove-Item $msystar

## invoke the first-run shell
Invoke-Msys2Shell

Write-Host -ForegroundColor Green Done with MSYS
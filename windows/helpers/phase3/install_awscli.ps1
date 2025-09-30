# PowerShell script to install AWS CLI v2 on Windows
# This script is similar to other installer files in the common directory

param (
    [Parameter(Mandatory=$true)][string]$Sha256,
    [Parameter(Mandatory=$true)][string]$Version
)

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "AWSCLI" -Keyname "version" -TargetValue $Version
if($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "AWS CLI v2 up to date"
    return
}

# AWS CLI MSI URL
$awsCliUrl = "https://awscli.amazonaws.com/AWSCLIV2-${Version}.msi"
$installPath = "$env:ProgramFiles\Amazon\AWSCLIV2"

Write-Host -ForegroundColor Green "Starting with AWS CLI v2 installation"
$out = Join-Path ([IO.Path]::GetTempPath()) 'awscli.msi'

Get-RemoteFile -RemoteFile $awsCliUrl -LocalFile $out -VerifyHash $Sha256

Start-Process msiexec -ArgumentList "/q /i $($out) /norestart INSTALLDIR=`"$installPath`"" -Wait

Remove-Item $out

# Verify installation
if (Test-Path "$installPath\aws.exe") {
    # Add to PATH if not already in it
    Add-ToPath -NewPath $installPath -Local -Global
    Reload-Path
    Set-InstalledVersionKey -Component "AWSCLI" -Keyname "version" -TargetValue $Version
    Write-Host -ForegroundColor Green "Done with AWS CLI v2"
} else {
    Write-Host -ForegroundColor Red "AWS CLI v2 installation failed. aws.exe not found at $installPath"
    exit 1
}

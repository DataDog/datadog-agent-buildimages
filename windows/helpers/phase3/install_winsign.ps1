$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Write-Host -ForegroundColor Green "Installing Windows Codesign Helper $ENV:WINSIGN_VERSION"

## need to have more rigorous download at some point, but
$codesign_wheel = "https://s3.amazonaws.com/dd-agent-omnibus/windows-code-signer/windows_code_signer-$($ENV:WINSIGN_VERSION)-py3-none-any.whl"
$codesign_wheel_target = "c:\devtools\windows_code_signer.whl"
(New-Object System.Net.WebClient).DownloadFile($codesign_wheel, $codesign_wheel_target)

Get-RemoteFile -RemoteFile $codesign_wheel -LocalFile $codesign_wheel_target -VerifyHash $ENV:WINSIGN_SHA256

python -m pip install $codesign_wheel_target
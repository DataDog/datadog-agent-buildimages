$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "codeql" -Keyname "version" -TargetValue $ENV:CODEQL_VERSION
if($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "Codeql up to date"
    return
}
if($isInstalled -and -not $isCurrent){
    Remove-Item -Recurse -Force c:\CodeQL -ErrorAction SilentlyContinue
}
Write-Host -ForegroundColor Green "Installing CodeQL $ENV:CODEQL_VERSION"
#             https://github.com/github/codeql-cli-binaries/releases/download/v2.10.3/codeql-win64.zip
$codeqlzip = "https://github.com/github/codeql-cli-binaries/releases/download/v$ENV:CODEQL_VERSION/codeql-win64.zip"
$out = "$($PSScriptRoot)\codeql.zip"

Write-Host -ForegroundColor Green "Downloading $codeqlzip to $out"

Get-RemoteFile -RemoteFile $codeqlzip -LocalFile $out -VerifyHash $ENV:CODEQL_HASH

Write-Host -ForegroundColor Green "Extracting $out to c:\"

Start-Process "7z" -ArgumentList "x -oc:\ $out" -Wait

Write-Host -ForegroundColor Green "Removing temporary file $out"

Remove-Item $out

Add-ToPath -NewPath "c:\CodeQL" -Global
Set-InstalledVersionKey -Component "codeql" -Keyname "version" -TargetValue $ENV:CODEQL_VERSION
Write-Host -ForegroundColor Green "Installed CodeQL $ENV:CODEQL_VERSION"

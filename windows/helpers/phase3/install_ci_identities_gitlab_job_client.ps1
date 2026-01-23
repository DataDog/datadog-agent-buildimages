# Installs ci-identities-gitlab-job-client
# see https://github.com/DataDog/ci-identities/tree/main/apps/ci-identities-gitlab-job-client

param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$Sha256
)

$DESTINATION = "C:\devtools\ci-identities-gitlab-job-client.exe"

# the file was downloaded in the CI job before running the "docker build" command
# because it's hard to run "aws s3 cp" in the build container;
# see .gitlab/build.yml
Copy-Item -Path "C:\mnt\ci-identities-gitlab-job-client-windows-amd64.exe" -Destination $DESTINATION

if ( -not (Test-Path $DESTINATION)) {
    Write-Host -ForegroundColor Red "$DESTINATION not found"
    exit 1
}

# Verify version
$versionOutput = & $DESTINATION version 2>&1
if ($versionOutput -notmatch [regex]::Escape($Version)) {
    Write-Host -ForegroundColor Red "Version mismatch for $DESTINATION"
    Write-Host -ForegroundColor Red "Expected version: $Version"
    Write-Host -ForegroundColor Red "Actual output: $versionOutput"
    Remove-Item $DESTINATION
    exit 1
}

$actualHash = (Get-FileHash -Algorithm SHA256 $DESTINATION).Hash
if ($actualHash -ne $Sha256) {
    Write-Host -ForegroundColor Red "Hash mismatch for $DESTINATION"
    Write-Host -ForegroundColor Red "Expected: $Sha256"
    Write-Host -ForegroundColor Red "Actual:   $actualHash"
    Remove-Item $DESTINATION
    exit 1
}

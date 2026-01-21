# Installs ci-identities-gitlab-job-client
# see https://github.com/DataDog/ci-identities/tree/main/apps/ci-identities-gitlab-job-client

param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$Sha256
)

$DESTINATION = "C:\devtools\ci-identities-gitlab-job-client.exe"

aws s3 cp s3://binaries-ddbuild-io-prod/ci-identities/ci-identities-gitlab-job-client/versions/$Version/ci-identities-gitlab-job-client-windows-amd64.exe $DESTINATION

if ( -not (Test-Path $DESTINATION)) {
    Write-Host -ForegroundColor Red "$DESTINATION not found"
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

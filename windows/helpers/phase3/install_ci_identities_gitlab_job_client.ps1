# Installs ci-identities-gitlab-job-client
# see https://github.com/DataDog/ci-identities/tree/main/apps/ci-identities-gitlab-job-client

param (
    [Parameter(Mandatory=$true)][string]$VERSION,
)

$DESTINATION = "C:\devtools\ci-identities-gitlab-job-client.exe"

aws s3 cp s3://binaries-ddbuild-io-prod/ci-identities/ci-identities-gitlab-job-client/versions/$VERSION/ci-identities-gitlab-job-client-windows-amd64.exe $DESTINATION

if ( -not (Test-Path $DESTINATION)) {
    Write-Host -ForegroundColor Red "$DESTINATION not found"
    exit 1
}

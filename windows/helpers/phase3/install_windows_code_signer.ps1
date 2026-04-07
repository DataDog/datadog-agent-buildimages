# Checks the installed version of windows-code-signer.exe.
# See https://github.com/DataDog/windows-code-signer.
# The file was downloaded during the "docker build"
# with a "COPY --from" instruction in the Dockerfile

param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$Sha256
)

$DESTINATION = "C:\devtools\windows-code-signer.exe"

if ( -not (Test-Path $DESTINATION)) {
    Write-Host -ForegroundColor Red "$DESTINATION not found"
    throw "$DESTINATION not found"
}

$actualHash = (Get-FileHash -Algorithm SHA256 $DESTINATION).Hash
if ($actualHash.ToUpper() -ne $Sha256.ToUpper()) {
    Write-Host -ForegroundColor Red "Hash mismatch for $DESTINATION"
    Write-Host -ForegroundColor Red "Expected: $Sha256"
    Write-Host -ForegroundColor Red "Actual:   $actualHash"
    Remove-Item $DESTINATION
    throw "Hash mismatch for $DESTINATION. Expected: $Sha256, Actual: $actualHash"
}

# Verify version
$versionOutput = (& $DESTINATION version 2>&1) | Out-String
if ($versionOutput -notmatch [regex]::Escape($Version)) {
    Write-Host -ForegroundColor Red "Version mismatch for $DESTINATION"
    Write-Host -ForegroundColor Red "Expected version: $Version"
    Write-Host -ForegroundColor Red "Actual output: $versionOutput"
    Remove-Item $DESTINATION
    throw "Version mismatch for $DESTINATION. Expected: $Version, Got: $versionOutput"
}

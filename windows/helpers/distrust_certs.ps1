param(
    [Parameter(Mandatory = $true)][string] $CertsDir
)

$ErrorActionPreference = 'Stop'

$certs = Get-ChildItem -Path $CertsDir -Filter *.crt
if ($certs.Count -eq 0) {
    Write-Host "[Error]: no certificates found in $CertsDir"
    exit 1
}

foreach ($cert in $certs) {
    $imported = Import-Certificate -FilePath $cert.FullName -CertStoreLocation Cert:\LocalMachine\Disallowed
    if (-not (Test-Path "Cert:\LocalMachine\Disallowed\$($imported.Thumbprint)")) {
        Write-Host "[Error]: $($cert.Name) is missing from the Disallowed store after import"
        exit 1
    }
    Write-Host "Distrusted $($imported.Subject) ($($imported.Thumbprint))"
}

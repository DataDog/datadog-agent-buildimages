. .\helpers.ps1
. .\versions.ps1

foreach ($h in $SoftwareTable.GetEnumerator()){
    $key = $($h.Key)
    $val = $($h.Value)
    [Environment]::SetEnvironmentVariable($key, $val, [System.EnvironmentVariableTarget]::Process)
}

.\helpers\install_7zip.ps1 -Version $ENV:SEVENZIP_VERSION -Sha256 $ENV:SEVENZIP_SHA256
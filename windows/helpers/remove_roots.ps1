$ErrorActionPreference = 'Stop'

# Roots that the compromised eMudhra intermediates chain to, and the emSign roots Mozilla removed with them.
$roots = [ordered]@{
    'D1EB23A46D17D68FD92564C2F1F1601764D8E349' = 'AAA Certificate Services'
    '39D3236E4A609AB6190CBFA1AD02B3CC61DFC2C3' = 'emSign Root TLS CA - G3'
    '1F74B6010A219FD9CA058D07AA053D15EFD9300D' = 'emSign Root CS CA - G3'
    '3043FA4FF257DCA0C380EE2E58EA78B23FE6BBC1' = 'emSign ECC Root CA - G3'
    'B6AF43C29B81537DF6EF6BC31F1F60150CEE4866' = 'emSign ECC Root CA - C3'
    'E72EF1DFFCB20928CF5DD4D56737B151CB864F01' = 'emSign Root CA - C1'
}

# Automatic root update would download a removed root again the first time a chain to it is built.
$policy = 'HKLM:\SOFTWARE\Policies\Microsoft\SystemCertificates\AuthRoot'
New-Item -Path $policy -Force | Out-Null
New-ItemProperty -Path $policy -Name DisableRootAutoUpdate -PropertyType DWord -Value 1 -Force | Out-Null

foreach ($store in 'Root', 'AuthRoot') {
    foreach ($root in $roots.GetEnumerator()) {
        $path = "Cert:\LocalMachine\$store\$($root.Key)"
        if (Test-Path $path) {
            Remove-Item $path
            Write-Host "Removed $($root.Value) from LocalMachine\$store"
        }
        if (Test-Path $path) {
            Write-Host "[Error]: $($root.Value) is still in LocalMachine\$store"
            exit 1
        }
    }
}

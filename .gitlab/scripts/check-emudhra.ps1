# Fails if the image still trusts any chain of the compromised eMudhra intermediates.
# See https://emudhra.we-have-a-problem.com/
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$hosts = @(
    'dv-g3b', 'dv-g3c', 'ov-g3b', 'ov-g3c', 'ev-g3b', 'ev-g3c', 'dv-g3b-noct',
    'dv-g3b-aaa', 'dv-g3c-aaa', 'ov-g3b-aaa', 'ov-g3c-aaa', 'ev-g3b-aaa', 'ev-g3c-aaa', 'dv-g3b-aaa-noct'
)

# Schannel / Windows system store; revocation is skipped so only the trust store decides.
function Test-SchannelCurl($url) {
    & "$env:SystemRoot\System32\curl.exe" -s -o NUL --max-time 20 --ssl-no-revoke $url
    return $LASTEXITCODE -eq 0
}

# .NET / Windows system store. An HTTP error status still means the TLS handshake succeeded.
function Test-DotNet($url) {
    try {
        Invoke-WebRequest -UseBasicParsing -TimeoutSec 20 $url | Out-Null
        return $true
    } catch [System.Net.WebException] {
        return $null -ne $_.Exception.Response
    }
}

# OpenSSL with Python's default context: Windows ROOT/CA stores plus SSL_CERT_FILE.
function Test-Python($url) {
    $code = 'import ssl, sys, urllib.error, urllib.request
try:
    urllib.request.urlopen(sys.argv[1], timeout=20, context=ssl.create_default_context())
except urllib.error.HTTPError:
    pass'
    python -c $code $url 2>$null
    return $LASTEXITCODE -eq 0
}

$clients = [ordered]@{ 'schannel-curl' = 'Test-SchannelCurl'; 'dotnet' = 'Test-DotNet'; 'python' = 'Test-Python' }

Write-Host "SSL_CERT_FILE=$env:SSL_CERT_FILE"
python --version
foreach ($client in $clients.GetEnumerator()) {
    if (-not (& $client.Value 'https://github.com/')) {
        Write-Host "INCONCLUSIVE: control host github.com is unreachable with $($client.Key)"
        exit 2
    }
}

$trusted = $false
foreach ($h in $hosts) {
    $url = "https://$h-emudhra.we-have-a-problem.com/"
    foreach ($client in $clients.GetEnumerator()) {
        if (& $client.Value $url) {
            Write-Host ("TRUSTED   {0,-14} {1}" -f $client.Key, $url)
            $trusted = $true
        } else {
            Write-Host ("rejected  {0,-14} {1}" -f $client.Key, $url)
        }
    }
}
if ($trusted) { exit 1 }
exit 0

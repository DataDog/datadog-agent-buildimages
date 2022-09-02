#
# Install_cert.ps1
#
# downloads the certificate root file necessary for downloads during the agent build.
# Add certificates needed for build & check certificates file hash
# We need to trust the DigiCert High Assurance EV Root CA certificate, which signs python.org,
# to be able to download some Python components during the Agent build.
#
Get-RemoteFile -RemoteFile "https://curl.haxx.se/ca/cacert-${ENV:CACERTS_VERSION}.pem" -LocalFile "c:\cacert.pem" -VerifyHash $ENV:CACERTS_HASH

Add-EnvironmentVariable -Variable "SSL_CERT_FILE" -Value "C:\cacert.pem" -Global
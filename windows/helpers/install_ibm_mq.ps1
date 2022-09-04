param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

$source = "https://s3.amazonaws.com/dd-agent-omnibus/ibm-mq-backup/$($Version)-IBM-MQC-Redist-Win64.zip"
$target = "c:\ibm_mq"

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "ibmmq" -Keyname "version" -TargetValue $Version
if($isInstalled -and $isCurrent){
    Write-Host -ForegroundColor Green "IBM-MQ already installed"
    return
}
if($isInstalled){
    # just delete the existing installation so the new one will replace it
    Remove-Item -Recurse -Force $target -ErrorAction SilentlyContinue
}
DownloadAndExpandTo -TargetDir $target -SourceURL $source -Sha256 $Sha256
Add-EnvironmentVariable -Variable MQ_FILE_PATH -VALUE "c:\ibm_mq" -Global

Set-InstalledVersionKey -Component "ibmmq" -Keyname "version" -TargetValue $Version
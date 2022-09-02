param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

$source = "https://s3.amazonaws.com/dd-agent-omnibus/ibm-mq-backup/$($Version)-IBM-MQC-Redist-Win64.zip"
$target = "c:\ibm_mq"

DownloadAndExpandTo -TargetDir $target -SourceURL $source -Sha256 $Sha256
Add-EnvironmentVariable -Variable MQ_FILE_PATH -VALUE "c:\ibm_mq" -Global
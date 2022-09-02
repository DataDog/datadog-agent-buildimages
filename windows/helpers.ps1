param(
    [Parameter(Mandatory = $false)][switch] $Container
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'Stop'

# Define get-remotefile so that it can be used throughout
function Get-RemoteFile() {
    param(
        [Parameter(Mandatory = $true)][string] $RemoteFile,
        [Parameter(Mandatory = $true)][string] $LocalFile,
        [Parameter(Mandatory = $false)][string] $VerifyHash
    )
    Write-Host -ForegroundColor Green "Downloading: $RemoteFile"
    Write-Host -ForegroundColor Green "         To: $LocalFile"
    (New-Object System.Net.WebClient).DownloadFile($RemoteFile, $LocalFile)
    if ($VerifyHash){
        $dlhash = (Get-FileHash -Algorithm SHA256 $LocalFile).hash.ToLower()
        if($dlhash -ne $VerifyHash){
            Write-Host -ForegroundColor Red "Unexpected file hash downloading $LocalFile from $RemoteFile"
            Write-Host -ForegroundColor Red "Expected $VerifyHash, got $dlhash"
            throw 'Unexpected File Hash'
        }
    }
}

function Add-EnvironmentVariable() {
    param(
        [Parameter(Mandatory = $true)][string] $Variable,
        [Parameter(Mandatory = $true)][string] $Value,
        [Parameter(Mandatory = $false)][switch] $Local,
        [Parameter(Mandatory = $false)][switch] $Global
    )
    if($Local) {
        [Environment]::SetEnvironmentVariable($Variable, $Value, [System.EnvironmentVariableTarget]::Process)
    }
    if($Global){
        [Environment]::SetEnvironmentVariable($Variable, $Value, [System.EnvironmentVariableTarget]::Machine)
    }
}

function Add-ToPath() {
    param(
        [Parameter(Mandatory = $true)][string] $NewPath,
        [Parameter(Mandatory = $false)][switch] $Local,
        [Parameter(Mandatory = $false)][switch] $Global
    )
    if($Local) {
        $Env:Path="$Env:Path;$NewPath"
    }
    if($Global){
        $oldPath=[Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
        $target="$oldPath;$NewPath"
        [Environment]::SetEnvironmentVariable("Path", $target, [System.EnvironmentVariableTarget]::Machine)
    }
}

function DownloadAndExpandTo{
    param(
        [Parameter(Mandatory = $true)][string] $TargetDir,
        [Parameter(Mandatory = $true)][string] $SourceURL,
        [Parameter(Mandatory = $true)][string] $Sha256
    )
    $tmpOutFile = New-TemporaryFile

    Get-RemoteFile -LocalFile $tmpOutFile -RemoteFile $SourceURL -VerifyHash $Sha256

    If(!(Test-Path $TargetDir))
    {
        md $TargetDir
    }

    Start-Process "7z" -ArgumentList "x -o${TargetDir} $tmpOutFile" -Wait
    Remove-Item $tmpOutFile
}

function Reload-Path() {
    $newpath = @()
    $syspath = [Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
    $userpath = [Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
    $existingpath = $Env:PATH
    $all = @()
    $all += $syspath -split ";"
    $all += $userpath -split ";"
    $all += $existingpath -split ";"
    foreach ($p in $all){
        if ($newpath -notcontains $p){
            $newpath += $p
        }
    }
    $Env:PATH=$newpath -join ";"
}
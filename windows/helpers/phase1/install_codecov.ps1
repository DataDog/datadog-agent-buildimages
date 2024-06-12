param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

$CodecovPath = "c:\program files\codecov"
$CodecovUrl = "https://uploader.codecov.io/$Version/windows/codecov.exe"
$OutFile = "codecov.exe"

if (Test-Path -Path "$CodecovPath\codecov.exe") {
    Write-Output "$CodecovPath\codecov.exe already exists on the system."
} else {
    Write-Output "Downloading codecov.exe to $CodecovPath"
    Get-RemoteFile -RemoteFile $CodecovUrl -LocalFile $OutFile -VerifyHash $Sha256

    # Moving codecov.exe to "c:\program files\codecov"
    if (-Not (Test-Path -Path $CodecovPath)) {
        Write-Output "Creating $CodecovPath"
        mkdir $CodecovPath
    }
    Write-Output "Moving codecov.exe to $CodecovPath"
    Move-Item -Path $OutFile -Destination "$CodecovPath\codecov.exe"
}


# Adding codecov folder to the system PATH
Add-ToPath -NewPath $CodecovPath -Local -Global

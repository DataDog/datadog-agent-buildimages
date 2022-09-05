#returns installed go versions in order of latest to oldest. Returns a list of strings
function Get-GoVersions {
    $rawversions =  get-childitem -path "hklm:\Software\DatadogDeveloper\go" | foreach-object { new-object System.Version($_.name | split-path -leaf)}
    $versions = @()
    $res = $rawversions | sort -Descending | ForEach-Object { $versions += $_.ToString() }
    return ,$versions
}
function Get-GoRootDir {
    param (
        [Parameter(Mandatory = $true)][string] $GoVer
    )
    $path = get-itempropertyvalue -path HKLM:Software\DatadogDeveloper\go\$GoVer -name goroot
    if($? -eq $false){
        return $null
    }
    return $path
}

function Set-GoVersion {
    param (
        [Parameter(Mandatory = $true)][string] $GoVer
    )
    $goversions = Get-GoVersions
    $goversion = ""
    if (! [bool]$GoVer) {
        $goversion = $goversions[0]
    } else {
        if ($goversions -match $GoVer){
            $goversion = $GoVer
        } else {
            Write-Host -ForegroundColor Red "Could not find Go version $GoVer"
            return
        }
    }
    Write-Host "Chose version $goversion"
    $gorootdir = Get-GoRootDir $goversion
    if ($null -eq $gorootdir) {
        Write-Host -ForegroundColor Red "Couldn't find goroot"
        return
    }
    $Env:GOROOT="$gorootdir\go"
    $Env:GOPATH="c:\go"
}
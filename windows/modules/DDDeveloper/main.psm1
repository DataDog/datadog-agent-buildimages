function Use-BuildEnv {
    param (
        [Parameter(Mandatory = $false)][string] $GoVer
    )

    # put python in front of `working path`.  Windows 10 includes a dummy python in the path
    # to tell you to go get it from the store, which means that the binary can't be found

    $targetdir = "$($Env:USERPROFILE)\.ddbuild"
    if(!(test-path $targetdir)){
        mkdir $targetdir
    }
    $targetfile = "$targetdir\environment.json"
    $varsToSet = Get-Content $targetfile | convertfrom-json
    
    #    EnvironmentVars = @{}
    #    PathEntries = @()
    #}
    ## first set all the variables we were asked to set
    $varsToSet.EnvironmentVars.psobject.properties | foreach {
        [Environment]::SetEnvironmentVariable($_.Name, $_.Value, [System.EnvironmentVariableTarget]::Process)
    }
    
    ## save the starting path. This allows multiple invocations in the same shell
    if($null -eq $Env:ORIGPATH) {
        $Env:ORIGPATH = $ENV:PATH
    }

    $newPathEntries = $Env:ORIGPATH -split ";"

    ## now walk all the new entries
    foreach($e in $varsToSet.PathEntries) {
        if ([string]::IsNullOrWhiteSpace($e)){
            continue;
        }

        if($newPathEntries -notcontains $e) {
            ##
            ## if this is the `go` path, skip it because we're going to manually add it later
            if($e -like "*\go\*"){
                continue
            }
            ## need to hack this a bit.  Ideally all the path entries would be behind the default
            ## windows entries; but windows10/11 includes a python "stub", so we need to put python
            ## before the windows entries
            if($e -like "*python*"){
                $newPathEntries = @($e) + $newPathEntries
            } else {
                $newPathEntries += $e
            }
        }
    }
    
    ## append the proper go paths.
    $useGoVersion = $GoVer
    if(!$GoVer) {
        $versions = Get-Goversions
        $useGoVersion = $versions[0]
    }
    Set-GoVersion $useGoVersion

    $newPathEntries += "$Env:GOROOT\bin"
    $newPathEntries += "$Env:GOPATH\bin"

    $Env:PATH=$newPathEntries -join ";"
    $Env:BUILDENV="Agent-Build"

    # enable RIDK in this shell
    & $Env:RIDK enable

    # load the developer prompt
    . $PSScriptRoot\prompt.ps1
}
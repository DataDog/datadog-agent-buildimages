param(
    [Parameter(Mandatory = $false)][switch] $TargetContainer,
    [Parameter(Mandatory = $false)][string] $Phase = "0"
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'Stop'

# this includes the master versions variables
. .\versions.ps1

# this includes the helper functions
. .\helpers.ps1

# set the environment variables from the versions file

# Global Variables for saving env variables and path additions on the local build
$GlobalEnvVariables = [PSCustomObject]@{
    EnvironmentVars = @{}
    PathEntries = @()
}

# Read Go variables from go.env file
$lines = Get-Content -Path '..\go.env'
foreach ($line in $lines) {
    $key, $val = $line.split('=')
    [Environment]::SetEnvironmentVariable($key, $val, [System.EnvironmentVariableTarget]::Process)
}

foreach ($h in $SoftwareTable.GetEnumerator()){
    $key = $($h.Key)
    $val = $($h.Value)
    [Environment]::SetEnvironmentVariable($key, $val, [System.EnvironmentVariableTarget]::Process)
}

.\helpers\install_cert.ps1

## only do this if building the container
if($TargetContainer){
    $Env:DD_DEV_TARGET="Container"
    Write-Host "Container Flag Set $TargetContainer"
} else {
    Write-Host "Container flag not set $TargetContainer"
    Read-Variables
}

try {
    # Each phase is its own layer in the Dockerfile, to make it easier to iterate on changes
    # by making use of Docker's layer cache. The phases are roughly organized by dependencies,
    # install time, and frequency of updates, with longer install times and less frequently
    # changed items in the earlier phases.
    #
    # Phase 4 is empty by default. Before starting work on updating an item move the script to Phase 4.
    #
    if ($Phase -eq 0 -or $Phase -eq 1) {
        .\helpers\phase1\install_net35.ps1
        .\helpers\phase1\install_7zip.ps1 -Version $ENV:SEVENZIP_VERSION -Sha256 $ENV:SEVENZIP_SHA256
        .\helpers\phase1\install_mingit.ps1 -Version $ENV:GIT_VERSION -Sha256 $ENV:GIT_SHA256
        .\helpers\phase1\install_vstudio.ps1
        .\helpers\phase1\install_wdk.ps1
        .\helpers\phase1\install_wix.ps1 -Version $ENV:WIX_VERSION -Sha256 $ENV:WIX_SHA256
        .\helpers\phase1\install_dotnetcore.ps1
        .\helpers\phase1\install_nuget.ps1 -Version $ENV:NUGET_VERSION -Sha256 $ENV:NUGET_SHA256
        .\helpers\phase1\install_vcpython.ps1
        .\helpers\phase1\install_cmake.ps1 -Version $ENV:CMAKE_VERSION -Sha256 $ENV:CMAKE_SHA256
        # # vcpkg depends on cmake
        .\helpers\phase1\install_vcpkg.ps1
    }

    if ($Phase -eq 0 -or $Phase -eq 2) {
        .\helpers\phase2\install_docker.ps1
        .\helpers\phase2\install_ruby.ps1 -Version $ENV:RUBY_VERSION -Sha256 $ENV:RUBY_SHA256
        # msys depends on ruby
        .\helpers\phase2\install_msys.ps1 -Version $ENV:MSYS_VERSION -Sha256 $ENV:MSYS_SHA256
        .\helpers\phase2\install_python.ps1 -Version $ENV:PYTHON_VERSION -Sha256 $ENV:PYTHON_SHA256
        .\helpers\phase2\install_gcloud_sdk.ps1
        .\helpers\phase2\install_embedded_pythons.ps1
    }

    if ($Phase -eq 0 -or $Phase -eq 3) {
        .\helpers\phase3\install_ibm_mq.ps1 -Version $ENV:IBM_MQ_VERSION -Sha256 $ENV:IBM_MQ_SHA256
        .\helpers\phase3\install_winget.ps1 -Version $ENV:WINGET_VERSION -Sha256 $ENV:WINGET_SHA256
        .\helpers\phase3\install_go.ps1
        .\helpers\phase3\install_codeql.ps1
        .\helpers\phase3\install_ninja.ps1 -Version $ENV:NINJA_VERSION -Sha256 $ENV:NINJA_SHA256
        .\helpers\phase3\install_java.ps1
        .\helpers\phase3\install_winsign.ps1
        .\helpers\phase3\install_rust.ps1 -Rustup_Version $ENV:RUSTUP_VERSION -Rustup_Sha256 $ENV:RUSTUP_SHA256 -Rust_Version $ENV:RUST_VERSION
        ## # Add signtool to path
        Add-ToPath -NewPath "${env:ProgramFiles(x86)}\Windows Kits\8.1\bin\x64\" -Global
        & .\set_cpython_compiler.cmd
    }

    if ($Phase -eq 0 -or $Phase -eq 4) {
    }
}
catch {
    Write-Host -ForegroundColor Red "Error installing software"
    Write-Host -ForegroundColor Red "$_.ScriptStackTrace"
    exit -1
}
finally {

    if(!$TargetContainer){
        Write-Variables
        $moduleTarget = "$($Env:USERPROFILE)\Documents\WindowsPowerShell\Modules\DDDeveloper"
        if(! (test-path $moduleTarget)){
            mkdir $moduleTarget
        }
        xcopy /y/e/s "$($PSScriptRoot)\modules\DDDeveloper\*" $moduleTarget
        import-module -force DDDeveloper
    }
    Remove-Item -Recurse -Force c:\tmp\* -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $Env:TEMP\* -ErrorAction SilentlyContinue

}

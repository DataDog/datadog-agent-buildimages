param(
    [Parameter(Mandatory = $false)][switch] $TargetContainer
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'Stop'

# this includes the master versions variables
. .\versions.ps1

# this includes the helper functions
. .\helpers.ps1

# set the environment variables from the versions file

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
}

.\helpers\install_net35.ps1
.\helpers\install_7zip.ps1 -Version $ENV:SEVENZIP_VERSION -Sha256 $ENV:SEVENZIP_SHA256
.\helpers\install_mingit.ps1 -Version $ENV:GIT_VERSION -Sha256 $ENV:GIT_SHA256

### HACK: we disable symbolic links when cloning repositories
### to work around a symlink-related failure in the agent-binaries omnibus project
### when copying the datadog-agent project twice.
& git config --system core.symlinks false
.\helpers\install_vstudio.ps1 #-Version $ENV:VS2017BUILDTOOLS_VERSION -Sha256 $ENV:VS2017BUILDTOOLS_SHA256 $ENV:VS2017BUILDTOOLS_DOWNLOAD_URL
.\helpers\install_wdk.ps1
.\helpers\install_wix.ps1 -Version $ENV:WIX_VERSION -Sha256 $ENV:WIX_SHA256
.\helpers\install_dotnetcore.ps1
.\helpers\install_nuget.ps1 -Version $ENV:NUGET_VERSION -Sha256 $ENV:NUGET_SHA256
.\helpers\install_vcpython.ps1
.\helpers\install_ibm_mq.ps1 -Version $ENV:IBM_MQ_VERSION -Sha256 $ENV:IBM_MQ_SHA256
.\helpers\install_cmake.ps1 -Version $ENV:CMAKE_VERSION -Sha256 $ENV:CMAKE_SHA256
.\helpers\install_winget.ps1 -Version $ENV:WINGET_VERSION -Sha256 $ENV:WINGET_SHA256
.\helpers\install_go.ps1
.\helpers\install_python.ps1 -Version $ENV:PYTHON_VERSION -Sha256 $ENV:PYTHON_SHA256
.\helpers\install_ruby.ps1 -Version $ENV:RUBY_VERSION -Sha256 $ENV:RUBY_SHA256
.\helpers\install_msys.ps1 -Version $ENV:MSYS_VERSION -Sha256 $ENV:MSYS_SHA256
.\helpers\install_docker.ps1
.\helpers\install_gcloud_sdk.ps1
.\helpers\install_embedded_pythons.ps1
.\helpers\install_vcpkg.ps1
.\helpers\install_codeql.ps1
.\helpers\install_ninja.ps1 -Version $ENV:NINJA_VERSION -Sha256 $ENV:NINJA_SHA256
## # Add signtool to path
Add-ToPath -NewPath "${env:ProgramFiles(x86)}\Windows Kits\8.1\bin\x64\" -Global
& .\set_cpython_compiler.cmd
if($TargetContainer){
    Remove-Item -Recurse -Force c:\tmp\*
    Remove-Item -Recurse -Force $Env:TEMP\*
}

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

.\Install_cert.ps1

## only do this if building the container
if($TargetContainer){
    Write-Host "Container Flag Set $TargetContainer"
    .\install_net35.ps1
} else {
    Write-Host "Container flag not set $TargetContainer"
}

.\install_7zip.ps1 -Version $ENV:SEVENZIP_VERSION -Sha256 $ENV:SEVENZIP_SHA256
.\install_mingit.ps1 -Version $ENV:GIT_VERSION -Sha256 $ENV:GIT_SHA256

### HACK: we disable symbolic links when cloning repositories
### to work around a symlink-related failure in the agent-binaries omnibus project
### when copying the datadog-agent project twice.
& git config --system core.symlinks false
.\install_vstudio.ps1 -Version $ENV:VS2017BUILDTOOLS_VERSION -Sha256 $ENV:VS2017BUILDTOOLS_SHA256 $ENV:VS2017BUILDTOOLS_DOWNLOAD_URL
.\install_wdk.ps1
.\install_wix.ps1 -Version $ENV:WIX_VERSION -Sha256 $ENV:WIX_SHA256
.\install_dotnetcore.ps1
.\install_nuget.ps1 -Version $ENV:NUGET_VERSION -Sha256 $ENV:NUGET_SHA256
.\install_vcpython.ps1
.\install_ibm_mq.ps1 -Version $ENV:IBM_MQ_VERSION -Sha256 $ENV:IBM_MQ_SHA256
.\install_cmake.ps1 -Version $ENV:CMAKE_VERSION -Sha256 $ENV:CMAKE_SHA256
.\install_winget.ps1 -Version $ENV:WINGET_VERSION -Sha256 $ENV:WINGET_SHA256
.\install_go.ps1
$Env:PATH -split ";"
.\install_python.ps1 -Version $ENV:PYTHON_VERSION -Sha256 $ENV:PYTHON_SHA256
.\install_ruby.ps1 -Version $ENV:RUBY_VERSION -Sha256 $ENV:RUBY_SHA256
.\install_msys.ps1 -Version $ENV:MSYS_VERSION -Sha256 $ENV:MSYS_SHA256
.\install_docker.ps1
.\install_gcloud_sdk.ps1
.\install_embedded_pythons.ps1
.\install_vcpkg.ps1
.\install_codeql.ps1
.\install_ninja.ps1 -Version $ENV:NINJA_VERSION -Sha256 $ENV:NINJA_SHA256
## # Add signtool to path
Add-ToPath -NewPath "${env:ProgramFiles(x86)}\Windows Kits\8.1\bin\x64\" -Global
& .\set_cpython_compiler.cmd
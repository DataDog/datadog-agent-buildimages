$ErrorActionPreference = 'Stop'

# Add certificates needed for build & check certificates file hash
# We need to trust the DigiCert High Assurance EV Root CA certificate, which signs python.org,
# to be able to download some Python components during the Agent build.
(New-Object System.Net.WebClient).DownloadFile("https://curl.haxx.se/ca/cacert.pem", "cacert.pem")
if ((Get-FileHash .\cacert.pem).Hash -ne "$ENV:CACERTS_HASH") { Write-Host "Wrong hashsum for cacert.pem: got '$((Get-FileHash .\cacert.pem).Hash)', expected '$ENV:CACERTS_HASH'."; exit 1 }
setx SSL_CERT_FILE "C:\cacert.pem"

# Set 32-bit flag env var
if ($Env:TARGET_ARCH -eq 'x86') { setx CHOCO_ARCH_FLAG '-x86' ; setx WINDOWS_BUILD_32_BIT 1 }

# Install Chocolatey
$env:chocolateyUseWindowsCompression = 'true'; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install git
$env:chocolateyUseWindowsCompression = 'true'; cinst -y --no-progress git $ENV:CHOCO_ARCH_FLAG --version $ENV:GIT_VERSION

# Install 7zip
$env:chocolateyUseWindowsCompression = 'true'; cinst -y --no-progress 7zip $ENV:CHOCO_ARCH_FLAG --version $ENV:SEVENZIP_VERSION

# Install Cmake and update PATH to include it
cinst -y --no-progress cmake $ENV:CHOCO_ARCH_FLAG --version $ENV:CMAKE_VERSION
if ($Env:TARGET_ARCH -eq 'x86') { [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";${Env:ProgramFiles(x86)}\CMake\bin", [System.EnvironmentVariableTarget]::Machine) }
if ($Env:TARGET_ARCH -eq 'x64') { [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";${env:ProgramFiles}\CMake\bin", [System.EnvironmentVariableTarget]::Machine) }

# Install golang and set GOPATH to the dev path used in builds & tests
cinst -y --no-progress golang $ENV:CHOCO_ARCH_FLAG --version $ENV:GO_VERSION
setx GOPATH C:\dev\go

# Install system Python 2 (to use invoke)
cinst -y --no-progress python2 $ENV:CHOCO_ARCH_FLAG --version $ENV:PYTHON_VERSION

# Install 64-bit ruby (for omnibus builds)
cinst -y --no-progress ruby --version $ENV:RUBY_VERSION

### We need both the .NET 3.5 runtime and the .NET 4.8 runtime.
### To do this, on 1809 we get 4.8 from a base image and we
### manually the install .NET Framework 3.5 runtime using the instructions in
### the mcr.microsoft.com/dotnet/framework/runtime:3.5 Dockerfile:
### https://github.com/microsoft/dotnet-framework-docker/blob/26597e42d157cc1e09d1e0dc8f23c32e6c3d1467/3.5/runtime/windowsservercore-ltsc2019/Dockerfile

### 1909 includes .NET Framework 4.8 by default, so we use the image that includes
### .NET Framework 3.5 as well, and thus we don't need to install it manually here.

### The .NET Fx 3.5 is needed for the Visual C++ Compiler for Python 2.7
### (https://www.microsoft.com/en-us/download/details.aspx?id=44266)
### and to work around a bug in the WiX 3.11 installer
### (https://github.com/wixtoolset/issues/issues/5661).

# Install .NET Fx 3.5
if ($Env:WINDOWS_VERSION -eq '1809') { .\scripts\install_net35_1809.bat }

# Install VS2017
cinst -y --no-progress visualstudio2017buildtools $ENV:CHOCO_ARCH_FLAG --version $ENV:VS2017BUILDTOOLS_VERSION --params "--add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Win81 --add Microsoft.VisualStudio.Workload.VCTools"
setx VSTUDIO_ROOT "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\BuildTools"

# Add signtool to path
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";${env:ProgramFiles(x86)}\Windows Kits\8.1\bin\x64", [System.EnvironmentVariableTarget]::Machine)

# Install VC compiler for Python 2.7
cinst -y --no-progress vcpython27 $ENV:CHOCO_ARCH_FLAG --version $ENV:VCPYTHON27_VERSION

# Install Wix and update PATH to include it
cinst -y --no-progress wixtoolset $ENV:CHOCO_ARCH_FLAG --version $ENV:WIX_VERSION
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";${env:ProgramFiles(x86)}\WiX Toolset v3.11\bin", [System.EnvironmentVariableTarget]::Machine)

# Install msys2 system
cinst -y --no-progress msys2 --params "/NoUpdate" --version $ENV:MSYS_VERSION

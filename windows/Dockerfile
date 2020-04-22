# Use the Microsoft-provided .NET Runtime 4.8 image as the base image
# because installing it in the image with Chocolatey requires a reboot.

# There is a bug in the February 11, 2020 update that makes commands fail in
# docker containers (see: https://support.microsoft.com/en-us/help/4542617/you-might-encounter-issues-when-using-windows-server-containers-with-t)
# To avoid that, there are two solutions:
# - both the host and the container must have the February 11, 2020 update, or
# - neither the host and the container must have the February 11, 2020 update.
# Since our 1809 windows-docker host image does not have this update, we use a base
# container image that does not have this update either (thus the 20200114 tag).
# TODO: Once the 1809 windows-docker host image is updated, update the base container image.
ARG BASE_IMAGE=mcr.microsoft.com/dotnet/framework/runtime:4.8-20200114-windowsservercore-ltsc2019
FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command"]

ARG TARGET_ARCH
ENV TARGET_ARCH ${TARGET_ARCH:-x64}

ENV GO_VERSION "1.13.8"
ENV RUBY_VERSION "2.4.3.1"
ENV PYTHON_VERSION "2.7.17"
ENV WIX_VERSION "3.11.2"

ENV EMBEDDED_PYTHON_2_VERSION "2.7.17"
ENV EMBEDDED_PYTHON_3_VERSION "3.8.1"

LABEL target_agent="Agent 6/7"
LABEL target_arch=${TARGET_ARCH}
LABEL containerbase=${BASE_IMAGE}
LABEL go_version=${GO_VERSION}
LABEL ruby_version=${RUBY_VERSION}
LABEL wix_version=${WIX_VERSION}
LABEL system_python_version=${PYTHON_VERSION}
LABEL embedded_py2_version=${EMBEDDED_PYTHON_2_VERSION}
LABEL embedded_py3_version=${EMBEDDED_PYTHON_3_VERSION}

### Preliminary step: we need both the .NET 3.5 runtime (needed because of a Wix 3.11 bug) and
### the .NET 4.8 runtime. To do this, we get 4.8 from a base image and we
### manually the install .NET Framework 3.5 runtime using the instructions in
### the mcr.microsoft.com/dotnet/framework/runtime:3.5 Dockerfile:
### https://github.com/microsoft/dotnet-framework-docker/blob/26597e42d157cc1e09d1e0dc8f23c32e6c3d1467/3.5/runtime/windowsservercore-ltsc2019/Dockerfile
### TODO: Stop doing this once Wix 3.14 is available

# Install .NET Fx 3.5
COPY ./windows/install_net35.bat install_net35.bat
RUN .\install_net35.bat

### End of preliminary step

RUN if ($Env:TARGET_ARCH -eq 'x86') { setx CHOCO_ARCH_FLAG '-x86' }

# Install Chocolatey
RUN $env:chocolateyUseWindowsCompression = 'true'; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install git
RUN $env:chocolateyUseWindowsCompression = 'true'; cinst -y --no-progress git $ENV:CHOCO_ARCH_FLAG

# Install 7zip
RUN $env:chocolateyUseWindowsCompression = 'true'; cinst -y --no-progress 7zip $ENV:CHOCO_ARCH_FLAG

# Install VS2017
RUN cinst -y --no-progress visualstudio2017buildtools $ENV:CHOCO_ARCH_FLAG --params \"--add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Win81 --add Microsoft.VisualStudio.Workload.VCTools\"
RUN setx VSTUDIO_ROOT \"${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\BuildTools\"

# Install VC compiler for Python 2.7
RUN cinst -y --no-progress vcpython27 $ENV:CHOCO_ARCH_FLAG

# Install Wix and update PATH to include it
RUN cinst -y --no-progress wixtoolset $ENV:CHOCO_ARCH_FLAG --version $ENV:WIX_VERSION
RUN [Environment]::SetEnvironmentVariable(\"Path\", [Environment]::GetEnvironmentVariable(\"Path\", [EnvironmentVariableTarget]::Machine) + \";${env:ProgramFiles(x86)}\WiX Toolset v3.11\bin\", [System.EnvironmentVariableTarget]::Machine)

# Install Cmake and update PATH to include it
RUN cinst -y --no-progress cmake $ENV:CHOCO_ARCH_FLAG
RUN if ($Env:TARGET_ARCH -eq 'x86') { [Environment]::SetEnvironmentVariable(\"Path\", [Environment]::GetEnvironmentVariable(\"Path\", [EnvironmentVariableTarget]::Machine) + \";${Env:ProgramFiles(x86)}\CMake\bin\", [System.EnvironmentVariableTarget]::Machine) }
RUN if ($Env:TARGET_ARCH -eq 'x64') { [Environment]::SetEnvironmentVariable(\"Path\", [Environment]::GetEnvironmentVariable(\"Path\", [EnvironmentVariableTarget]::Machine) + \";${env:ProgramFiles}\CMake\bin\", [System.EnvironmentVariableTarget]::Machine) }

# Install golang and set GOPATH to the dev path used in builds & tests
RUN cinst -y --no-progress golang $ENV:CHOCO_ARCH_FLAG --version $ENV:GO_VERSION
RUN setx GOPATH C:\dev\go

# Install system Python 2 (to use invoke)
RUN cinst -y --no-progress python2 $ENV:CHOCO_ARCH_FLAG --version $ENV:PYTHON_VERSION

# Install 64-bit ruby and bundler (for omnibus builds)
RUN cinst -y --no-progress ruby --version $ENV:RUBY_VERSION
RUN setx RIDK ((Get-Command ridk).Path)
RUN gem install bundler

# Install msys2 system & install 64-bit C/C++ compilation toolchain
RUN cinst -y --no-progress msys2 --params \"/NoUpdate\"
RUN ridk install 3

# (32-bit only) Install 32-bit C/C++ compilation toolchain
RUN if ($Env:TARGET_ARCH -eq 'x86') { ridk enable; bash -c \"pacman -S --needed --noconfirm mingw-w64-i686-binutils mingw-w64-i686-crt-git mingw-w64-i686-gcc mingw-w64-i686-gcc-libs mingw-w64-i686-headers-git mingw-w64-i686-libmangle-git mingw-w64-i686-libwinpthread-git mingw-w64-i686-make mingw-w64-i686-pkg-config mingw-w64-i686-tools-git mingw-w64-i686-winpthreads-git\" }
RUN if ($Env:TARGET_ARCH -eq 'x86') { [Environment]::SetEnvironmentVariable(\"Path\", [Environment]::GetEnvironmentVariable(\"Path\", [EnvironmentVariableTarget]::Machine) + \";C:\tools\msys64\mingw32\bin;C:\tools\msys64\usr\bin\", [System.EnvironmentVariableTarget]::Machine) }

# Install aws cli
COPY ./windows/install_awscli.ps1 install_awscli.ps1
RUN powershell -C .\install_awscli.ps1

# Install embedded pythons (for unit testing)
COPY ./windows/install_embedded_pythons.ps1 install_embedded_pythons.ps1
RUN powershell -C .\install_embedded_pythons.ps1

# Add certificates
COPY ./windows/cert.pem /tools/cert.pem
RUN setx SSL_CERT_FILE \"C:\tools\cert.pem\"

# Add signtool to path
RUN [Environment]::SetEnvironmentVariable(\"Path\", [Environment]::GetEnvironmentVariable(\"Path\", [EnvironmentVariableTarget]::Machine) + \";${env:ProgramFiles(x86)}\Windows Kits\8.1\bin\x64\", [System.EnvironmentVariableTarget]::Machine)

# Set 32-bit flag env var
RUN if ($Env:TARGET_ARCH -eq 'x86') { setx WINDOWS_BUILD_32_BIT 1 }

COPY ./windows/entrypoint.bat /entrypoint.bat
COPY ./windows/aws_networking.ps1 /aws_networking.ps1

ENTRYPOINT ["/entrypoint.bat"]

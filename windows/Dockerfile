# Use the Microsoft-provided .NET Runtime 4.8 image as the base image
# because installing it in the image with Chocolatey requires a reboot.

# There is a bug in the February 11, 2020 update that makes commands fail in
# docker containers (see: https://support.microsoft.com/en-us/help/4542617/you-might-encounter-issues-when-using-windows-server-containers-with-t)
# To avoid that, there are two solutions:
# - both the host and the container must have the February 11, 2020 update, or
# - neither the host and the container must have the February 11, 2020 update.
# Since our 1809 windows-docker host image does not have this update, we use a base
# container image that does not have this update either (thus the 20200114 tag).
# On the contrary, since our 1909 windows-docker host image does have this update,
# we use a base container image that does have this update.
# TODO: Once the 1809 windows-docker host image is updated, update the base container image.
ARG BASE_IMAGE=mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019

FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command"]

ARG WINDOWS_VERSION
ENV WINDOWS_VERSION=${WINDOWS_VERSION:-1809}

ARG DD_TARGET_ARCH
ENV TARGET_ARCH=${DD_TARGET_ARCH:-x64}

# Chocolatey package versions
ENV GIT_VERSION "2.26.2"
ENV SEVENZIP_VERSION "19.0.0" # now needs all 3 digits
ENV VS2017BUILDTOOLS_VERSION "16.8.3.0"
#ENV VS2017BUILDTOOLS_DOWNLOAD_URL "https://download.visualstudio.microsoft.com/download/pr/d0eac510-174b-4241-b73b-93dc7cc1fbf7/9822b4c851e14d9658babd1533f66f518c6169196e985fe5713b2774128832ae/vs_BuildTools.exe"
ENV VS2017BUILDTOOLS_DOWNLOAD_URL "https://download.visualstudio.microsoft.com/download/pr/9b3476ff-6d0a-4ff8-956d-270147f21cd4/ccfb9355f4f753315455542f966025f96de734292d3908c8c3717e9685b709f0/vs_BuildTools.exe"
ENV VCPYTHON27_VERSION "9.0.0.30729"
ENV GO_VERSION "1.16.7"
ENV RUBY_VERSION "2.6.6-1"
ENV PYTHON_VERSION "3.8.2"
ENV WIX_VERSION "3.11.2"
ENV CMAKE_VERSION "3.17.2"
ENV MSYS_VERSION "20210725"
ENV NUGET_VERSION "5.8.0"
ENV EMBEDDED_PYTHON_2_VERSION "2.7.17"
ENV EMBEDDED_PYTHON_3_VERSION "3.8.1"
ENV EMBEDDED_PIP_VERSION "20.3.4"

ENV CACERTS_HASH "ae31ecb3c6e9ff3154cb7a55f017090448f88482f0e94ac927c0c67a1f33b9cf"
ENV CACERTS_VERSION "2021-10-26"

LABEL target_agent="Agent 6/7"
LABEL target_arch=${TARGET_ARCH}
LABEL windows_version=${WINDOWS_VERSION}
LABEL git_version=${GIT_VERSION}
LABEL sevenzip_version=${SEVENZIP_VERSION}
LABEL vs2017buildtools_version=${VS2017BUILDTOOLS_VERSION}
LABEL vcpython27_version=${VCPYTHON27_VERSION}
LABEL go_version=${GO_VERSION}
LABEL ruby_version=${RUBY_VERSION}
LABEL wix_version=${WIX_VERSION}
LABEL cmake_version=${CMAKE_VERSION}
LABEL msys_version=${MSYS_VERSION}
LABEL system_python_version=${PYTHON_VERSION}
LABEL embedded_py2_version=${EMBEDDED_PYTHON_2_VERSION}
LABEL embedded_py3_version=${EMBEDDED_PYTHON_3_VERSION}
LABEL nuget_version=${NUGET_VERSION}
# Add certificates needed for build & check certificates file hash
# We need to trust the DigiCert High Assurance EV Root CA certificate, which signs python.org,
# to be able to download some Python components during the Agent build.
RUN (New-Object System.Net.WebClient).DownloadFile(\"https://curl.haxx.se/ca/cacert-${ENV:CACERTS_VERSION}.pem\", \"cacert.pem\")
RUN if ((Get-FileHash .\cacert.pem).Hash -ne \"$ENV:CACERTS_HASH\") { Write-Host \"Wrong hashsum for cacert.pem: got '$((Get-FileHash .\cacert.pem).Hash)', expected '$ENV:CACERTS_HASH'.\"; exit 1 }
RUN setx SSL_CERT_FILE \"C:\cacert.pem\"

### Preliminary step: we need both the .NET 3.5 runtime and
### the .NET 4.8 runtime. To do this, we get 4.8 from a base image and we
### manually the install .NET Framework 3.5 runtime using the instructions in
### the mcr.microsoft.com/dotnet/framework/runtime:3.5 Dockerfile:
### https://github.com/microsoft/dotnet-framework-docker/blob/26597e42d157cc1e09d1e0dc8f23c32e6c3d1467/3.5/runtime/windowsservercore-ltsc2019/Dockerfile

### The .NET Fx 3.5 is needed for the Visual C++ Compiler for Python 2.7
### (https://www.microsoft.com/en-us/download/details.aspx?id=44266)
### and to work around a bug in the WiX 3.11 installer
### (https://github.com/wixtoolset/issues/issues/5661).

# Install .NET Fx 3.5
COPY ./windows/install_net35.ps1 install_net35.ps1
RUN Powershell -C .\install_net35.ps1

### End of preliminary step

# Install 7-zip
Copy ./windows/install_7zip.ps1 install_7zip.ps1
RUN powershell -Command .\install_7zip.ps1 -Version $ENV:SEVENZIP_VERSION

# Install git
COPY ./windows/install_mingit.ps1 install_mingit.ps1
RUN powershell -Command .\install_mingit.ps1 -Version $ENV:GIT_VERSION

### HACK: we disable symbolic links when cloning repositories
### to work around a symlink-related failure in the agent-binaries omnibus project
### when copying the datadog-agent project twice.
RUN git config --system core.symlinks false

# Install VS2017
COPY ./windows/install_vstudio.ps1 install_vstudio.ps1
RUN powershell -Command .\install_vstudio.ps1 -Version $ENV:VS2017BUILDTOOLS_VERSION $ENV:VS2017BUILDTOOLS_DOWNLOAD_URL

# If x64, install the WDK for driver development
COPY ./windows/install_wdk.ps1 install_wdk.ps1
RUN if ($Env:TARGET_ARCH -eq 'x64') { powershell -Command .\install_wdk.ps1 }

# Install Wix and update PATH to include it
COPY ./windows/install_wix.ps1 install_wix.ps1
RUN powershell -Command .\install_wix.ps1 -Version $ENV:WIX_VERSION

# Install dotnet core
COPY ./windows/install_dotnetcore.ps1 install_dotnetcore.ps1
RUN powershell -Command .\install_dotnetcore.ps1

# install nuget
COPY ./windows/install_nuget.ps1 install_nuget.ps1
RUN powershell -Command .\install_nuget.ps1 $ENV:NUGET_VERSION

# install vcpkg
COPY ./windows/install_vcpkg.ps1 install_vcpkg.ps1
RUN powershell -Command .\install_vcpkg.ps1

# Install VC compiler for Python 2.7
COPY ./windows/install_vcpython.ps1 install_vcpython.ps1
RUN powershell -Command .\install_vcpython.ps1


# Install Cmake and update PATH to include it
COPY ./windows/install_cmake.ps1 install_cmake.ps1
RUN powershell -Command .\install_cmake.ps1 -Version $ENV:CMAKE_VERSION -Arch $ENV:TARGET_ARCH

# Install golang and set GOPATH to the dev path used in builds & tests
# RUN cinst -y --no-progress golang $ENV:CHOCO_ARCH_FLAG --version $ENV:GO_VERSION

# Some go point releases are not available as chocolatey packages, we have to install them directly
COPY ./windows/install_go.ps1 install_go.ps1
RUN powershell -C .\install_go.ps1

RUN setx GOPATH C:\dev\go

# Install system Python 3 (to use invoke).
# We always install the 64 bit version because vcredist140 won't work otherwise
COPY ./windows/install_python.ps1 install_python.ps1
RUN powershell -C .\install_python.ps1 -Version $ENV:PYTHON_VERSION

# Install 64-bit ruby and bundler (for omnibus builds)
COPY ./windows/install_ruby.ps1 install_ruby.ps1
RUN powershell -C .\install_ruby.ps1 -Version $ENV:RUBY_VERSION

# Install msys2 system & install 64-bit C/C++ compilation toolchain
copy ./windows/install_msys.ps1 install_msys.ps1
RUN powershell -C .\install_msys.ps1 -Version $ENV:MSYS_VERSION

RUN ridk install 3

# Downgrade gcc and binutils due to https://github.com/golang/go/issues/46099
RUN (New-Object System.Net.WebClient).DownloadFile(\"https://s3.amazonaws.com/dd-agent-omnibus/mingw-w64-x86_64-gcc-10.2.0-11-any.pkg.tar.zst\", \"C:/mingw-w64-x86_64-gcc-10.2.0-11-any.pkg.tar.zst\")
RUN (New-Object System.Net.WebClient).DownloadFile(\"https://s3.amazonaws.com/dd-agent-omnibus/mingw-w64-x86_64-gcc-libs-10.2.0-11-any.pkg.tar.zst\", \"C:/mingw-w64-x86_64-gcc-libs-10.2.0-11-any.pkg.tar.zst\")
RUN (New-Object System.Net.WebClient).DownloadFile(\"https://s3.amazonaws.com/dd-agent-omnibus/mingw-w64-x86_64-binutils-2.35.1-2-any.pkg.tar.zst\", \"C:/mingw-w64-x86_64-binutils-2.35.1-2-any.pkg.tar.zst\")
RUN C:\tools\msys64\msys2_shell.cmd -defterm -no-start -c \"pacman --noconfirm -U /c/mingw-w64-x86_64-binutils-2.35.1-2-any.pkg.tar.zst /c/mingw-w64-x86_64-gcc-libs-10.2.0-11-any.pkg.tar.zst /c/mingw-w64-x86_64-gcc-10.2.0-11-any.pkg.tar.zst\"

# Install aws cli
COPY ./windows/install_awscli.ps1 install_awscli.ps1
RUN powershell -C .\install_awscli.ps1

# Install docker, manifest-tool and notary
COPY ./windows/install_docker.ps1 install_docker.ps1
RUN powershell -Command .\install_docker.ps1

# Install google cloud SDK
COPY ./windows/install_gcloud_sdk.ps1 install_gcloud_sdk.ps1
RUN powershell -C .\install_gcloud_sdk.ps1

# Install embedded pythons (for unit testing)
COPY ./windows/install_embedded_pythons.ps1 install_embedded_pythons.ps1
RUN powershell -C .\install_embedded_pythons.ps1

# Add signtool to path
RUN [Environment]::SetEnvironmentVariable(\"Path\", [Environment]::GetEnvironmentVariable(\"Path\", [EnvironmentVariableTarget]::Machine) + \";${env:ProgramFiles(x86)}\Windows Kits\8.1\bin\x64\", [System.EnvironmentVariableTarget]::Machine)

# Set 32-bit flag env var
RUN if ($Env:TARGET_ARCH -eq 'x86') { setx WINDOWS_BUILD_32_BIT 1 }

COPY ./windows/set_cpython_compiler.cmd set_cpython_compiler.cmd
RUN .\set_cpython_compiler.cmd

COPY ./windows/entrypoint.bat /entrypoint.bat
COPY ./windows/aws_networking.ps1 /aws_networking.ps1


ENTRYPOINT ["/entrypoint.bat"]

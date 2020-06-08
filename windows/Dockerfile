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
ARG BASE_IMAGE=mcr.microsoft.com/dotnet/framework/runtime:4.8-20200114-windowsservercore-ltsc2019

FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command"]

ARG WINDOWS_VERSION
ENV WINDOWS_VERSION=${WINDOWS_VERSION:-1809}

ARG TARGET_ARCH
ENV TARGET_ARCH=${TARGET_ARCH:-x64}

# Chocolatey package versions
ENV GIT_VERSION "2.26.2"
ENV SEVENZIP_VERSION "19.0"
ENV VS2017BUILDTOOLS_VERSION "15.9.23.0"
ENV VCPYTHON27_VERSION "9.0.0.30729"
ENV GO_VERSION "1.13.8"
ENV RUBY_VERSION "2.4.3.1"
ENV PYTHON_VERSION "2.7.17"
ENV WIX_VERSION "3.11.2"
ENV CMAKE_VERSION "3.17.2"
ENV MSYS_VERSION "20190524.0.0.20191030"

ENV EMBEDDED_PYTHON_2_VERSION "2.7.17"
ENV EMBEDDED_PYTHON_3_VERSION "3.8.1"

ENV CACERTS_HASH "ADF770DFD574A0D6026BFAA270CB6879B063957177A991D453FF1D302C02081F"

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

COPY ./windows/install_net35_1809.bat install_net35_1809.bat
COPY ./windows/install_net35_1909.bat install_net35_1909.bat
COPY ./windows/install_awscli.ps1 install_awscli.ps1
COPY ./windows/install_docker.ps1 install_docker.ps1
COPY ./windows/install_embedded_pythons.ps1 install_embedded_pythons.ps1

COPY ./windows/setup.ps1 setup.ps1
RUN powershell -C .\setup.ps1

COPY ./windows/entrypoint.bat /entrypoint.bat
COPY ./windows/aws_networking.ps1 /aws_networking.ps1

ENTRYPOINT ["/entrypoint.bat"]

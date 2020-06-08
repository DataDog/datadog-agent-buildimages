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
ENV GIT_VERSION="2.26.2" \
    SEVENZIP_VERSION="19.0" \
    VS2017BUILDTOOLS_VERSION="15.9.23.0" \
    VCPYTHON27_VERSION="9.0.0.30729" \
    GO_VERSION="1.13.8" \
    RUBY_VERSION="2.4.3.1" \
    PYTHON_VERSION="2.7.17" \
    WIX_VERSION="3.11.2" \
    CMAKE_VERSION="3.17.2" \
    MSYS_VERSION="20190524.0.0.20191030" \
    EMBEDDED_PYTHON_2_VERSION="2.7.17" \
    EMBEDDED_PYTHON_3_VERSION="3.8.1" \
    CACERTS_HASH="ADF770DFD574A0D6026BFAA270CB6879B063957177A991D453FF1D302C02081F"

LABEL target_agent="Agent 6/7" \
      target_arch=${TARGET_ARCH} \
      windows_version=${WINDOWS_VERSION} \
      git_version=${GIT_VERSION} \
      sevenzip_version=${SEVENZIP_VERSION} \
      vs2017buildtools_version=${VS2017BUILDTOOLS_VERSION} \
      vcpython27_version=${VCPYTHON27_VERSION} \
      go_version=${GO_VERSION} \
      ruby_version=${RUBY_VERSION} \
      wix_version=${WIX_VERSION} \
      cmake_version=${CMAKE_VERSION} \
      msys_version=${MSYS_VERSION} \
      system_python_version=${PYTHON_VERSION} \
      embedded_py2_version=${EMBEDDED_PYTHON_2_VERSION} \
      embedded_py3_version=${EMBEDDED_PYTHON_3_VERSION}

COPY ./windows/scripts scripts

RUN scripts/setup.ps1

RUN scripts/postsetup.ps1

# Install aws cli
RUN scripts/install_awscli.ps1

# Install docker, manifest-tool and notary
RUN scripts/install_docker.ps1

# Install embedded pythons (for unit testing)
RUN scripts/install_embedded_pythons.ps1

ENTRYPOINT ["scripts/entrypoint.bat"]

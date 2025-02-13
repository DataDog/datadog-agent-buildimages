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

ARG DEVA_NO_DYNAMIC_DEPS
ENV DEVA_NO_DYNAMIC_DEPS=$DEVA_NO_DYNAMIC_DEPS

ARG GIT_VERSION
ARG SEVENZIP_VERSION
ARG VS2017BUILDTOOLS_VERSION
ARG GO_VERSION
ARG GO_SHA256_WINDOWS_AMD64
ARG MSGO_PATCH
ARG DEVA_VERSION
ARG RUBY_VERSION
ARG WIX_VERSION
ARG CMAKE_VERSION
ARG MSYS_VERSION
ARG PYTHON_VERSION
ARG EMBEDDED_PYTHON_3_VERSION
ARG NUGET_VERSION
ARG CODEQL_VERSION
ARG VAULT_VERSION

LABEL target_agent="Agent 6/7"
LABEL target_arch=${TARGET_ARCH}
LABEL windows_version=${WINDOWS_VERSION}
LABEL git_version=${GIT_VERSION}
LABEL sevenzip_version=${SEVENZIP_VERSION}
LABEL vs2017buildtools_version=${VS2017BUILDTOOLS_VERSION}
LABEL go_version=${GO_VERSION}-${MSGO_PATCH}
LABEL ruby_version=${RUBY_VERSION}
LABEL wix_version=${WIX_VERSION}
LABEL cmake_version=${CMAKE_VERSION}
LABEL msys_version=${MSYS_VERSION}
LABEL system_python_version=${PYTHON_VERSION}
LABEL embedded_py3_version=${EMBEDDED_PYTHON_3_VERSION}
LABEL nuget_version=${NUGET_VERSION}
LABEL codeql_version=${CODEQL_VERSION}
LABEL vault_version=${VAULT_VERSION}

## WORKDIR should automatically create the directory
WORKDIR c:/scripts
COPY ./windows/*.ps1 ./
COPY ./windows/helpers/*.ps1 c:/scripts/helpers/

COPY go.env c:/
COPY deva.env c:/

COPY python-packages-versions.txt /
COPY ./windows/set_cpython_compiler.cmd set_cpython_compiler.cmd

RUN .\helpers\update_root_certs.ps1

COPY ./windows/helpers/phase1/*.ps1 c:/scripts/helpers/phase1/
RUN .\install-all.ps1 -TargetContainer -Phase 1
COPY ./windows/helpers/phase2/*.ps1 c:/scripts/helpers/phase2/
RUN .\install-all.ps1 -TargetContainer -Phase 2
COPY ./windows/helpers/phase3/*.ps1 c:/scripts/helpers/phase3/
RUN .\install-all.ps1 -TargetContainer -Phase 3
COPY ./windows/helpers/phase4/*.ps1 c:/scripts/helpers/phase4/
RUN .\install-all.ps1 -TargetContainer -Phase 4

COPY ./windows/entrypoint.bat /entrypoint.bat
COPY ./windows/helpers/aws_networking.ps1 /aws_networking.ps1

ENTRYPOINT ["/entrypoint.bat"]

# Use the Microsoft-provided .NET Runtime 4.8 image as the base image
# because installing it in the image with Chocolatey requires a reboot.

ARG BASE_IMAGE=mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2022

FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command"]

# Build arguments and environment variables
ARG WINDOWS_VERSION
ENV WINDOWS_VERSION=${WINDOWS_VERSION:-2022}

ARG DD_TARGET_ARCH
ENV TARGET_ARCH=${DD_TARGET_ARCH:-x64}

ARG DDA_NO_DYNAMIC_DEPS
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS

# Version arguments for labels and installation
ARG GIT_VERSION
ARG SEVENZIP_VERSION
ARG VS2017BUILDTOOLS_VERSION
ARG GO_VERSION
ARG GO_SHA256_WINDOWS_AMD64
ARG MSGO_PATCH
ARG DDA_VERSION
ARG RUBY_VERSION
ARG WIX_VERSION
ARG CMAKE_VERSION
ARG MSYS_VERSION
ARG PYTHON_VERSION
ARG EMBEDDED_PYTHON_3_VERSION
ARG NUGET_VERSION
ARG CODEQL_VERSION
ARG VAULT_VERSION

# Labels for documentation and metadata
LABEL target_agent="Agent 6/7" \
      target_arch=${TARGET_ARCH} \
      windows_version=${WINDOWS_VERSION} \
      git_version=${GIT_VERSION} \
      sevenzip_version=${SEVENZIP_VERSION} \
      vs2017buildtools_version=${VS2017BUILDTOOLS_VERSION} \
      go_version=${GO_VERSION}-${MSGO_PATCH} \
      ruby_version=${RUBY_VERSION} \
      wix_version=${WIX_VERSION} \
      cmake_version=${CMAKE_VERSION} \
      msys_version=${MSYS_VERSION} \
      system_python_version=${PYTHON_VERSION} \
      embedded_py3_version=${EMBEDDED_PYTHON_3_VERSION} \
      nuget_version=${NUGET_VERSION} \
      codeql_version=${CODEQL_VERSION} \
      vault_version=${VAULT_VERSION}

# Set up working directory
WORKDIR c:/scripts

# Copy all installation scripts and configuration files
COPY ./windows/*.ps1 ./
COPY ./windows/helpers/*.ps1 c:/scripts/helpers/
COPY ./windows/helpers/phase1/*.ps1 c:/scripts/helpers/phase1/
COPY ./windows/helpers/phase2/*.ps1 c:/scripts/helpers/phase2/
COPY ./windows/helpers/phase3/*.ps1 c:/scripts/helpers/phase3/
COPY ./windows/helpers/phase4/*.ps1 c:/scripts/helpers/phase4/
COPY go.env c:/
COPY dda.env c:/
COPY python-packages-versions.txt /
COPY ./windows/set_cpython_compiler.cmd set_cpython_compiler.cmd
COPY ./windows/entrypoint.bat /entrypoint.bat
COPY ./windows/helpers/aws_networking.ps1 /aws_networking.ps1

# Update root certificates before installing any software
RUN .\helpers\update_root_certs.ps1

# Run installation in phases to optimize caching
# Phase 1: Install basic tools and dependencies
RUN .\install-all.ps1 -TargetContainer -Phase 1

# Phase 2: Install development tools
RUN .\install-all.ps1 -TargetContainer -Phase 2

# Phase 3: Install programming languages and runtimes
RUN .\install-all.ps1 -TargetContainer -Phase 3

# Phase 4: Install final components and configure environment
RUN .\install-all.ps1 -TargetContainer -Phase 4

ENTRYPOINT ["/entrypoint.bat"]

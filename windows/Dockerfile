# escape=`

# Use the Microsoft-provided .NET Runtime 4.8 image as the base image
# because installing it in the image with Chocolatey requires a reboot.

ARG BASE_IMAGE=mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2022

FROM ${BASE_IMAGE}


ENV WINDOWS_VERSION=2022

ENV TARGET_ARCH=x64
ENV MS_GOTOOLCHAIN_TELEMETRY_ENABLED=0

ARG DDA_NO_DYNAMIC_DEPS
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS

ARG GO_VERSION
ARG GO_SHA256_WINDOWS_AMD64
ARG MSGO_PATCH
ARG DDA_VERSION

## WORKDIR should automatically create the directory
WORKDIR /mnt/windows
SHELL ["powershell", "-Command"]
COPY ./windows/set_cpython_compiler.cmd ./windows/*.ps1 /mnt/windows
COPY ./windows/helpers/*.ps1 /mnt/windows/helpers/
COPY go.env dda.env /mnt
RUN --mount=type=bind,source=/windows/helpers/phase1,dst=/mnt/windows/helpers/phase1 `
    /mnt/windows/install-all.ps1 -TargetContainer -Phase 1
RUN --mount=type=bind,source=/windows/helpers/phase2,dst=/mnt/windows/helpers/phase2 `
    --mount=type=bind,source=/python-packages-versions.txt,dst=/mnt/python-packages-versions.txt `
    /mnt/windows/install-all.ps1 -TargetContainer -Phase 2
RUN --mount=type=bind,source=/windows/helpers/phase3,dst=/mnt/windows/helpers/phase3 `
    --mount=type=bind,source=/ci-identities-gitlab-job-client-windows-amd64.exe,dst=/mnt/ci-identities-gitlab-job-client-windows-amd64.exe `
    /mnt/windows/install-all.ps1 -TargetContainer -Phase 3
RUN --mount=type=bind,source=/windows/helpers/phase4,dst=/mnt/windows/helpers/phase4 `
    /mnt/windows/install-all.ps1 -TargetContainer -Phase 4
COPY ./windows/entrypoint.bat /entrypoint.bat
COPY ./windows/helpers/aws_networking.ps1 /aws_networking.ps1
RUN /mnt/windows/helpers/update_root_certs.ps1
WORKDIR c:/
RUN Remove-Item -Recurse -Verbose c:/mnt
ENTRYPOINT ["/entrypoint.bat"]

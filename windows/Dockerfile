# Use the Microsoft-provided .NET Runtime 4.8 image as the base image
# because installing it in the image with Chocolatey requires a reboot.

ARG BASE_IMAGE=mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2022

FROM ${BASE_IMAGE}


ENV WINDOWS_VERSION=2022

ENV TARGET_ARCH=x64

ARG DDA_NO_DYNAMIC_DEPS
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS

ARG GO_VERSION
ARG GO_SHA256_WINDOWS_AMD64
ARG MSGO_PATCH
ARG DDA_VERSION

## WORKDIR should automatically create the directory
WORKDIR /mnt/windows
RUN --mount=type=bind,dst=/mnt /mnt/windows/set_cpython_compiler.cmd
SHELL ["powershell", "-Command"]
RUN --mount=type=bind,dst=/mnt /mnt/windows/install-all.ps1 -TargetContainer -Phase 1
RUN --mount=type=bind,dst=/mnt /mnt/windows/install-all.ps1 -TargetContainer -Phase 2
RUN --mount=type=bind,dst=/mnt /mnt/windows/install-all.ps1 -TargetContainer -Phase 3
RUN --mount=type=bind,dst=/mnt /mnt/windows/install-all.ps1 -TargetContainer -Phase 4
COPY ./windows/entrypoint.bat /entrypoint.bat
COPY ./windows/helpers/aws_networking.ps1 /aws_networking.ps1
RUN --mount=type=bind,dst=/mnt /mnt/windows/helpers/update_root_certs.ps1
WORKDIR c:/
RUN Remove-Item -Recurse -Verbose c:/mnt
ENTRYPOINT ["/entrypoint.bat"]

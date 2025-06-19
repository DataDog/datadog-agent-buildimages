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
WORKDIR c:/scripts
COPY ./windows/*.ps1 ./
COPY ./windows/helpers/*.ps1 c:/scripts/helpers/

COPY go.env c:/
COPY dda.env c:/

COPY python-packages-versions.txt /
COPY ./windows/set_cpython_compiler.cmd set_cpython_compiler.cmd


COPY ./windows/helpers/phase1/*.ps1 c:/scripts/helpers/phase1/
SHELL ["powershell", "-Command"]
RUN .\install-all.ps1 -TargetContainer -Phase 1
COPY ./windows/helpers/phase2/*.ps1 c:/scripts/helpers/phase2/
RUN .\install-all.ps1 -TargetContainer -Phase 2
COPY ./windows/helpers/phase3/*.ps1 c:/scripts/helpers/phase3/
RUN .\install-all.ps1 -TargetContainer -Phase 3
COPY ./windows/helpers/phase4/*.ps1 c:/scripts/helpers/phase4/
RUN .\install-all.ps1 -TargetContainer -Phase 4

COPY ./windows/entrypoint.bat /entrypoint.bat
COPY ./windows/helpers/aws_networking.ps1 /aws_networking.ps1
RUN .\helpers\update_root_certs.ps1

ENTRYPOINT ["/entrypoint.bat"]

# escape=`

# Use the Microsoft-provided .NET Runtime 4.8 image as the base image
# because installing it in the image with Chocolatey requires a reboot.

ARG BASE_IMAGE_REGISTRY=mcr.microsoft.com
ARG BASE_IMAGE_TAG=4.8-windowsservercore-ltsc2022
ARG BASE_IMAGE=${BASE_IMAGE_REGISTRY}/dotnet/framework/runtime:${BASE_IMAGE_TAG}

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
# TEST ONLY: remove before merging
COPY ./test-binary.exe C:/devtools/test-binary-early.exe
RUN Write-Host '----- state snapshot: early -----'; Write-Host ('Disk used: ' + (Get-PSDrive C).Used); Write-Host ('Process count: ' + (Get-Process).Count)
# TEST ONLY: isolate whether wcifs slowdown is driven purely by accumulated file count/layer
# size, independent of what created those files. Creates 150k tiny files in a single layer
# (no installers, no downloads) then times a COPY right after, same as the installer probes.
RUN $dir = 'C:\devtools\wcifs-test'; New-Item -ItemType Directory -Path $dir -Force | Out-Null; $bytes = [byte[]](1); $sw = [System.Diagnostics.Stopwatch]::StartNew(); for ($i = 0; $i -lt 150000; $i++) { [System.IO.File]::WriteAllBytes($dir + '\f' + $i + '.bin', $bytes) }; $sw.Stop(); Write-Host ('File creation took: ' + $sw.Elapsed)
COPY ./test-binary.exe C:/devtools/test-binary-after-filecreate.exe
RUN Write-Host '----- state snapshot: after filecreate -----'; Write-Host ('Disk used: ' + (Get-PSDrive C).Used); Write-Host ('Process count: ' + (Get-Process).Count)
RUN --mount=type=bind,source=/windows/helpers/phase1,dst=/mnt/windows/helpers/phase1 `
    /mnt/windows/install-all.ps1 -TargetContainer -Phase 1a1
# TEST ONLY: bisection point within Phase 1a, right before Visual Studio Build Tools, to check
# whether the slowdown appears before or only after that install specifically.
COPY ./test-binary.exe C:/devtools/test-binary-after-1a1.exe
RUN Write-Host '----- state snapshot: after phase1a1 -----'; Write-Host ('Disk used: ' + (Get-PSDrive C).Used); Write-Host ('Process count: ' + (Get-Process).Count)
RUN --mount=type=bind,source=/windows/helpers/phase1,dst=/mnt/windows/helpers/phase1 `
    /mnt/windows/install-all.ps1 -TargetContainer -Phase 1a2
# TEST ONLY: bisection point within Phase 1, right after the heaviest single item (Visual
# Studio Build Tools), to check whether it alone accounts for most of the slowdown.
COPY ./test-binary.exe C:/devtools/test-binary-after-1a2.exe
RUN Write-Host '----- state snapshot: after phase1a2 -----'; Write-Host ('Disk used: ' + (Get-PSDrive C).Used); Write-Host ('Process count: ' + (Get-Process).Count)
RUN --mount=type=bind,source=/windows/helpers/phase1,dst=/mnt/windows/helpers/phase1 `
    /mnt/windows/install-all.ps1 -TargetContainer -Phase 1b
# TEST ONLY: bisection point between Phase 1 and Phase 2, to narrow down which phase's
# accumulated state is responsible for the hang. Remove before merging.
COPY ./test-binary.exe C:/devtools/test-binary-mid.exe
RUN Write-Host '----- state snapshot: after phase1 -----'; Write-Host ('Disk used: ' + (Get-PSDrive C).Used); Write-Host ('Process count: ' + (Get-Process).Count)
RUN --mount=type=bind,source=/windows/helpers/phase2,dst=/mnt/windows/helpers/phase2 `
    --mount=type=bind,source=/python-packages-versions.txt,dst=/mnt/python-packages-versions.txt `
    /mnt/windows/install-all.ps1 -TargetContainer -Phase 2
# TEST ONLY: same trivial exe, copied at the same position as windows-code-signer.exe below,
# to check whether build position/accumulated layers matter rather than the file itself.
COPY ./test-binary.exe C:/devtools/test-binary-late.exe
RUN Write-Host '----- state snapshot: after phase2 -----'; Write-Host ('Disk used: ' + (Get-PSDrive C).Used); Write-Host ('Process count: ' + (Get-Process).Count)
COPY ./windows-code-signer.exe C:/devtools/windows-code-signer.exe
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

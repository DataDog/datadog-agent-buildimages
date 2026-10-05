# Building on Windows

This part of the repo contains the Dockerfile of the image used to build Windows
container which will be used to build Datadog Agent for Windows.

## Setting up a local build machine

[install-all.ps1](install-all.ps1) is the script the [Dockerfile](Dockerfile) runs to
build the container.

Run from this directory without `-TargetContainer`, it installs the same tools on the
local machine, along with the `DDDeveloper` PowerShell module whose `Use-BuildEnv`
command enables them in the current shell.

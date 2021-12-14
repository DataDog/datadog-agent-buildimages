$ErrorActionPreference = "Stop"

# Do not use '--depth 1' since vcpkg needs to browse its git history for dependency retrieval
git clone --branch 2021.05.12 https://github.com/microsoft/vcpkg
.\vcpkg\scripts\bootstrap.ps1
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";C:\vcpkg\", [System.EnvironmentVariableTarget]::Machine)
.\vcpkg\vcpkg.exe integrate install

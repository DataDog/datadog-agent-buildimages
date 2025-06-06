# Source: https://github.com/containerd/containerd/blob/main/docs/getting-started.md#installing-containerd-on-windows
# If containerd previously installed run:
Stop-Service containerd

# Download and extract desired containerd Windows binaries
$Version="1.7.13"	# update to your preferred version
$Arch = "amd64"	# arm64 also available
curl.exe -LO https://github.com/containerd/containerd/releases/download/v$Version/containerd-$Version-windows-$Arch.tar.gz
tar.exe xvf .\containerd-$Version-windows-$Arch.tar.gz

# Copy
Copy-Item -Path .\bin -Destination $Env:ProgramFiles\containerd -Recurse -Force

# add the binaries (containerd.exe, ctr.exe) in $env:Path
$Path = [Environment]::GetEnvironmentVariable("PATH", "Machine") + [IO.Path]::PathSeparator + "$Env:ProgramFiles\containerd"
[Environment]::SetEnvironmentVariable( "Path", $Path, "Machine")
# reload path, so you don't have to open a new PS terminal later if needed
$Env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# configure
containerd.exe config default | Out-File $Env:ProgramFiles\containerd\config.toml -Encoding ascii
# Review the configuration. Depending on setup you may want to adjust:
# - the sandbox_image (Kubernetes pause image)
# - cni bin_dir and conf_dir locations
Get-Content $Env:ProgramFiles\containerd\config.toml

# Register and start service
containerd.exe --register-service
Start-Service containerd

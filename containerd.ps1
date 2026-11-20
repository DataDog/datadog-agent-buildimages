# Source: https://github.com/containerd/containerd/blob/main/docs/getting-started.md#installing-containerd-on-windows
. .\windows\helpers.ps1
# If containerd previously installed run:
# A job killed by the GitLab runner (timeout or cancellation) only has its own process tree torn down via
# `TerminateJobObject` - not containers, since those belong to the `containerd` service's process tree
# instead. A container left over from such a job can then leave `containerd` unable to stop, hanging
# `Stop-Service` indefinitely on the next job landing on this same host. Bound the wait and force it down
# if that happens, instead of blocking forever.
$service = Get-Service -Name containerd -ErrorAction SilentlyContinue
if ($service) {
    Get-Process -Name buildkitd, buildctl -ErrorAction SilentlyContinue | Stop-Process -Force
    try {
        $service.Stop()
        $service.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(30))
    } catch [System.ServiceProcess.TimeoutException] {
        Write-Warning "containerd did not stop within 30s - forcing it down"
        Get-Process -Name containerd, containerd-shim-runhcs-v1 -ErrorAction SilentlyContinue | Stop-Process -Force
    }
}

# Download and extract desired containerd Windows binaries
$Version="1.7.13"	# update to your preferred version
$Arch = "amd64"	# arm64 also available
$sha256 = "a576160771eba9b3e0d85a841fa4f6dba60a14c5c4f45e34f2148e2fe138ebb7"
$containerd_url = "https://github.com/containerd/containerd/releases/download/v$Version/containerd-$Version-windows-$Arch.tar.gz"
$out = "$($PSScriptRoot)\containerd-$Version-windows-$Arch.tar.gz"
Get-RemoteFile -RemoteFile $containerd_url -LocalFile $out -VerifyHash $sha256
tar.exe xvf $out

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

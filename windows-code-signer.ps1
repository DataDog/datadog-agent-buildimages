# Extracts windows-code-signer.exe from its container image via containerd directly, instead of a
# Dockerfile `COPY --from=<stage>`. A cross-stage COPY needs buildkitd to instantiate a second Windows
# container just to read one file out of it, which is where https://github.com/moby/buildkit/issues/5682
# and related Windows containerd-worker isolation bugs live - that instruction has been hanging
# indefinitely in windows/Dockerfile. `ctr images mount` only unpacks the image's filesystem read-only;
# it never starts a container, so it never exercises that code path.
. .\windows\helpers.ps1

$image = "registry.ddbuild.io/windows-code-signer/go:v0.8.0@sha256:bb1715e19445abff13e9487ba68c33d1879ca258991d85a84c6ff7b63f26549a"
$mountPath = "$($PSScriptRoot)\.windows-code-signer-mnt"

ctr images pull $image
if ($LASTEXITCODE -ne 0) { throw "ctr images pull failed for $image" }

$null = New-Item $mountPath -ItemType Directory -Force
ctr images mount $image $mountPath
if ($LASTEXITCODE -ne 0) { throw "ctr images mount failed for $image" }

try {
    # Read the raw bytes and write them out as a brand new file, rather than Copy-Item, so the result
    # is an ordinary NTFS file with none of the CimFS-mount-specific attributes/placeholder semantics
    # of the source - the subsequent Dockerfile COPY of this file was hanging indefinitely otherwise.
    $bytes = [IO.File]::ReadAllBytes("$mountPath\windows-code-signer\windows-code-signer.exe")
    [IO.File]::WriteAllBytes("$($PSScriptRoot)\windows-code-signer.exe", $bytes)
} finally {
    ctr images unmount $mountPath
    Remove-Item $mountPath -Force -ErrorAction SilentlyContinue
}

Unblock-File ".\windows-code-signer.exe"

if (-not (Test-Path ".\windows-code-signer.exe")) {
    throw "windows-code-signer.exe extraction produced no file"
}

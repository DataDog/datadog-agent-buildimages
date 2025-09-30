param(
    [Parameter(Mandatory = $true)][string] $BaseImage,
    [Parameter(Mandatory = $true)][string] $Image,
    [Parameter(Mandatory = $true)][string] $Tag,
    [Parameter(Mandatory = $false)][switch] $Buildkit = $false
)

$build_args = @()
$cmd_args = @()
$build_opt = "--build-arg "
$cmd = "docker"
$OUTPUT_IMAGE = "${Image}:${Tag}"
$CACHE_IMAGE = "${Image}:cache"


if ($Buildkit) {
    $cmd = "buildctl"
    # Install containerd, buildkit and CNI plugins, see https://github.com/moby/buildkit/blob/master/docs/windows.md
    .\containerd.ps1
    .\cni.ps1
    .\buildkit.ps1
    # Start buildkitd
    Start-Process -FilePath "buildkitd.exe"
    $build_opt = "--opt build-arg:"
    $cmd_args = -split "--progress=plain --output type=image,name=$OUTPUT_IMAGE,push=true --frontend=dockerfile.v0 --local context=. --local dockerfile=.\windows "
    # Set cache arguments
    if ($env:CI_PIPELINE_SOURCE -eq "schedule") {
        $cmd_args += "--no-cache"
    } else {
        $cmd_args += -split "--import-cache type=registry,ref=$CACHE_IMAGE"
    }
    $cmd_args += -split "--export-cache type=registry,ref=$CACHE_IMAGE"
} else {
    $cmd_args = -split "-m 4096M -t $OUTPUT_IMAGE --file .\windows\Dockerfile ."
}

# Get build arguments from environment variables
$build_args += -split "${build_opt}BASE_IMAGE=${BaseImage}"
foreach ($line in $(Get-Content go.env)) {
    if ( -not ($line -like "*LINUX*") ) {
        $build_args += -split "$build_opt$line"
    }
}
foreach ($line in $(Get-Content dda.env)) {
    $build_args += -split "$build_opt$line"
}
$cmd_args += $build_args

# Build the image
Write-Host "Building the image using $cmd and $cmd_args"
& $cmd build $cmd_args
exit $LASTEXITCODE

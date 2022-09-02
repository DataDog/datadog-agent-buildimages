param(
    [Parameter(Mandatory = $false)][switch] $Container
)
if($Container){
    Write-Host "Container Flag Set"
} else {
    Write-Host "Container flag not set"
}

function global:prompt {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $identity

    $uname = "$($identity.Name)"
    if($principal.IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) { 
        $uname = "[ADMIN]: $($identity.Name)" 
    }
    $title = $uname
    $promptprompt = $uname
    if( $Env:PROMPTTYPE -ne $null) {
        $promptprompt = "{ $($Env:PROMPTTYPE) } $($uname) "
    }

    if($null -ne $Env:GOROOT){
        Write-Host -ForegroundColor Red " GOROOT $Env:GOROOT " -NoNewline
        $title = "$title GOROOT:$Env:GOROOT"
    }
    if($null -ne $Env:GOPATH) {
        Write-Host -ForegroundColor Green " GOPATH $Env:GOPATH " -NoNewline
        $title = "$title GOPATH:$Env:GOPATH"
    }
    $host.ui.RawUI.WindowTitle = $title

    $pathline = $null
    if($null -ne $Env:BUILDENV){
        $pathline = "$Env:BUILDENV - $((Get-Location).Path)"
    } else {
        $pathline = "$((Get-Location).Path)"
    }
    $gb = $null
    $gb = git.exe rev-parse --abbrev-ref HEAD 2> $null
    
    if($?){
        Write-Host -ForegroundColor Cyan "git-branch $gb `n" -NoNewline
    }
    Write-Host -ForegroundColor Yellow "`n$pathline `n" -NoNewline
    Write-Host -ForegroundColor Magenta "$promptprompt >> " -NoNewline
    return " "
}
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Write-Host -ForegroundColor Green "Installing Java $ENV:JAVA_VERSION"

$javazip = "https://download.java.net/java/early_access/jdk21/4/GPL/openjdk-$($ENV:JAVA_VERSION)_windows-x64_bin.zip"

$out = 'java.zip'

Write-Host -ForegroundColor Green "Downloading $javazip to $out"

(New-Object System.Net.WebClient).DownloadFile($javazip, $out)
if ((Get-FileHash -Algorithm SHA256 $out).Hash -ne "$ENV:JAVA_SHA256") { Write-Host \"Wrong hashsum for ${out}: got '$((Get-FileHash -Algorithm SHA256 $out).Hash)', expected '$ENV:GO_SHA256'.\"; exit 1 }

mkdir c:\tmp\java

Write-Host -ForegroundColor Green "Extracting $out to c:\tmp\java"

Start-Process "7z" -ArgumentList 'x -oc:\tmp\java java.zip' -Wait

Write-Host -ForegroundColor Green "Removing temporary file $out"

Remove-Item $out

setx JAVA_HOME c:\openjdk-21
$Env:JAVA_HOME="c:\openjdk-21"

## move expanded file from tmp dir to final resting place
## note must be after env variable set above.

Move-Item -Path c:\tmp\java\* -Destination $Env:JAVA_HOME

setx PATH "$Env:Path;$Env:JAVA_HOME\bin;"
$Env:Path="$Env:Path;$Env:JAVA_HOME\bin;"

Write-Host -ForegroundColor Green "Installed go $ENV:JAVA_VERSION"
Write-Host -ForegroundColor Green 'javac --version'; javac --version
Write-Host -ForegroundColor Green 'java --version'; java --version

## need to have more rigorous download at some point, but
$jsignjarsrc = "https://drive.google.com/file/d/1UEU58AkjJAe1fSnuN1WsAx4xZiWWG7PX/view?usp=sharing"
$jsignjardir = "c:\devtools\jsign"
$jsignout = "$($jsignjardir)\jsign-4.2.jar"
if(-Not (test-path $jsignjardir)){
    mkdir $jsignjardir
}
(New-Object System.Net.WebClient).DownloadFile($jsignjarsrc, $jsignout)
setx JARSIGN_JAR "$($jsignout)"

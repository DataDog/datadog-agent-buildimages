#
# installs HLK studio appropriate for the kernel version
#

$HLKDownloadTable = @{
    1809 = @{
        downloadurl = "https://go.microsoft.com/fwlink/?linkid=2026646"
    }
    1909 = @{
        downloadurl = "https://go.microsoft.com/fwlink/?linkid=2086002"
    }
    2004 = @{
        downloadurl = "https://go.microsoft.com/fwlink/?linkid=2128655"
    }
    2009 = @{
        downloadurl = "https://go.microsoft.com/fwlink/?linkid=2128655"
    }
}

$kernelver = [int](get-itemproperty -path "hklm:software\microsoft\windows nt\currentversion" -name releaseid).releaseid
Write-Host -ForegroundColor Green "Detected kernel version $kernelver"

curl.exe -fSLo hlksetup.exe $HLKDownloadTable[$kernelver]["downloadurl"]
start-process .\hlksetup.exe -ArgumentList "/features OptionId.HardwareLabKitStudio /q" -wait

# set the environment variable 
setx WTTSTDIO "C:\Program Files (x86)\Windows Kits\10\Hardware Lab Kit\Studio\"
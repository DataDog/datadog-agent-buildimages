# TEST ONLY: disables Windows Defender real-time protection on the runner host, to check whether
# an AV scan is what's hanging on windows-code-signer.exe's COPY. Process-isolated Windows containers
# share the host kernel, so this should also cover file operations happening inside the build. Remove
# before merging - this is not something to ship, only to test the hypothesis.
try {
    Set-MpPreference -DisableRealtimeMonitoring $true
    Write-Host "Disabled Windows Defender real-time monitoring"
} catch {
    Write-Warning "Could not disable Windows Defender real-time monitoring: $_"
}

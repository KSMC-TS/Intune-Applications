param(
[Parameter(Mandatory=$true)]
[ValidateSet('Install','Uninstall')]
[String[]]
$Mode
)


## Install block ##
if($Mode -eq "Install") {
    $Path = $env:TEMP
    $Installer = "Microsoft_RADC.msi"
    Invoke-WebRequest "https://go.microsoft.com/fwlink/?linkid=2068602" -OutFile $Path\$Installer
    Start-Process msiexec.exe -ArgumentList "/I $Path\$Installer /qn" -Wait
    Remove-Item $Path\$Installer
    $appfile = "C:\Program Files\Remote Desktop\msrdcw.exe"
    $smshortcut = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Remote Desktop.lnk"
    if (!(Test-Path $smshortcut)) {
        $WScriptShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WScriptShell.CreateShortcut($smshortcut)
        $Shortcut.TargetPath = $appfile
        $Shortcut.Save()
    }
    Start-Process -FilePath "C:\Program Files\Remote Desktop\msrdcw.exe"
    $result = 0
    Return $result
}


## Uninstall block ##
if($Mode -eq "Uninstall") {
    $uninstall_strings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "Remote Desktop" } | Select-Object -Property DisplayName, UninstallString, PSChildName
        foreach ($uninstall_string in $uninstall_strings) {
            $string = $uninstall_string.PSChildName
            $LogPath = "c:\ksmc\uninstalllog_$(get-date -Format yyyyMMddTHHmmss).log"
            Start-Process "$env:Windir\System32\msiexec.exe" -ArgumentList "/x$string /qn /L*V `"$logPath`"" -Wait -PassThru
        }
    $result = 0
    return $result
}

$result = 1618
Return $result


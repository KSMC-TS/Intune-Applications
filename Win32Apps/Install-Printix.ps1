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
    Start-Process msiexec.exe -ArgumentList "/I $Path\$Installer /qn ALLUSERS=1" -Wait
    Remove-Item $Path\$Installer
    $appfile = "C:\Program Files\Remote Desktop\msrdcw.exe"
    #$smshortcut = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Remote Desktop.lnk"
    $startupshortcut = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\Remote Desktop.lnk"
    if (!(Test-Path $smshortcut)) {
        $WScriptShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WScriptShell.CreateShortcut($smshortcut)
        $Shortcut.TargetPath = $appfile
        $Shortcut.Save()
    }
    if (!(Test-Path $startupshortcut)) {
        $WScriptShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WScriptShell.CreateShortcut($startupshortcut)
        $Shortcut.TargetPath = $appfile
        $Shortcut.Save()
    }
    Start-Process -FilePath "C:\Program Files\Remote Desktop\msrdcw.exe"
    Exit 0
}


## Uninstall block ##
if($Mode -eq "Uninstall") {
    $uninstall_strings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "Remote Desktop" } | Select-Object -Property DisplayName, UninstallString, PSChildName
        foreach ($uninstall_string in $uninstall_strings) {
            $string = $uninstall_string.PSChildName
            $LogPath = "c:\ksmc\uninstalllog_$(get-date -Format yyyyMMddTHHmmss).log"
            Start-Process "$env:Windir\System32\msiexec.exe" -ArgumentList "/x$string /qn /L*V `"$logPath`"" -Wait -PassThru
        }
    Exit 0
}

Exit 1618


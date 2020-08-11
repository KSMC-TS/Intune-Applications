param(
[Parameter(Mandatory=$true)]
[ValidateSet('Install','Uninstall')]
[String[]]
$Mode,
$installblob
)


## Install block ##
if($Mode -eq "Install") {
    $Path = $env:TEMP
    $Installer = "worldoxgx4.exe"
    Invoke-WebRequest $installblob -OutFile $Path\$Installer
    Start-Process -FilePath $Path\$Installer -Args "/quiet" -Verb RunAs -Wait
    Remove-Item $Path\$Installer
    Exit 0
    }


## Uninstall block ##
if($Mode -eq "Uninstall") {
    $uninstall_strings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "wdSaaS" } | Select-Object -Property DisplayName, UninstallString, PSChildName
        foreach ($uninstall_string in $uninstall_strings) {
            $string = $uninstall_string.PSChildName
            $LogPath = "c:\ksmc\uninstalllog_$(get-date -Format yyyyMMddTHHmmss).log"
            Start-Process "$env:Windir\System32\msiexec.exe" -ArgumentList "/x$string /qn /L*V `"$logPath`"" -Wait -PassThru
        }
    Exit 0
    }

Exit 1618

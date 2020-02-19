param(
[Parameter(Mandatory=$true)]
[ValidateSet('Install','Uninstall')]
[String[]]
$Mode
)


## Install block ##
if($Mode -eq "Install") {
    $Path = $env:TEMP
    $Installer = "firefox_enterprise.exe"
    Invoke-WebRequest "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US" -OutFile $Path\$Installer
    Start-Process -FilePath $Path\$Installer -Args "/S" -Verb RunAs -Wait
    Remove-Item $Path\$Installer
    Exit 0
    }


## Uninstall block ##
if($Mode -eq "Uninstall") {
    $uninstall_strings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "firefox" } | Select-Object -Property DisplayName, UninstallString, PSChildName
        foreach ($uninstall_string in $uninstall_strings) {
        $string = $uninstall_string.UninstallString
        Start-Process $string -ArgumentList "/S" -Wait -NoNewWindow
        }
    Exit 0
    }

Exit 1618

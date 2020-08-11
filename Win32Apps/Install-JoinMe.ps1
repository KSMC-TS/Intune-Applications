param(
[Parameter(Mandatory=$true)]
[ValidateSet('Install','Uninstall')]
[String[]]
$Mode
)

## Install block ##
if($Mode -eq "Install") {

    try {
    
    $Path = $env:TEMP
    $Installer = "joinme.msi"
    Invoke-WebRequest "https://join.me/Download.aspx?installer=win" -OutFile "$Path\$Installer"
    Start-Process msiexec -ArgumentList "/i $Path\$Installer /qn" -Wait
    Remove-Item "$Path\$Installer"


    } catch {

        Exit 1618

    }

}

## Uninstall block ##
if($Mode -eq "Uninstall") {

    try {

    $uninstall_strings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "join.me" } | Select-Object -Property DisplayName, UninstallString, PSChildName
    foreach ($uninstall_string in $uninstall_strings) {
    $string = $uninstall_string.PSChildName
    Start-Process msiexec -ArgumentList "/X$string /qn" -Wait -NoNewWindow
    }


    } catch {

        Exit 1618

    }

}

Exit 0
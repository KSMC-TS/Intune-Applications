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
    $Installer = "SSCERuntime_x64-ENU.exe"
    Invoke-WebRequest "https://download.microsoft.com/download/0/5/D/05DCCDB5-57E0-4314-A016-874F228A8FAD/SSCERuntime_x64-ENU.exe" -OutFile $Path\$Installer
    Start-Process "$Path\$Installer" -ArgumentList "/i /quiet" -Wait
    Remove-Item "$Path\$Installer"


    } catch {

        Exit 1618

    }

}

## Uninstall block ##
if($Mode -eq "Uninstall") {

    try {

    $uninstall_strings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "SQL Server Compact 4.0 x64 ENU" } | Select-Object -Property DisplayName, UninstallString, PSChildName
    foreach ($uninstall_string in $uninstall_strings) {
    $string = $uninstall_string.PSChildName
    Start-Process msiexec -ArgumentList "/X$string /qn" -Wait -NoNewWindow
    }


    } catch {

        Exit 1618

    }

}

Exit 0
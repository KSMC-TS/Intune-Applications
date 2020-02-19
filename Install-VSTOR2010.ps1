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
    $Installer = "vstor_redist.exe"
    Invoke-WebRequest "https://download.microsoft.com/download/C/A/8/CA86DFA0-81F3-4568-875A-7E7A598D4C1C/vstor_redist.exe" -OutFile "$Path\$Installer"
    Start-Process "$Path\$Installer" -ArgumentList "/q /norestart" -Wait
    Remove-Item "$Path\$Installer"


    } catch {

        Exit 1618

    }

}

## Uninstall block ##
if($Mode -eq "Uninstall") {

    try {

    $uninstall_strings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "Visual Studio 2010 Tools for Office Runtime" } | Select-Object -Property DisplayName, UninstallString, PSChildName
    foreach ($uninstall_string in $uninstall_strings) {
    $string = $uninstall_string.PSChildName
    Start-Process msiexec -ArgumentList "/X$string /qn" -Wait -NoNewWindow
    }


    } catch {

        Exit 1618

    }

}

Exit 0
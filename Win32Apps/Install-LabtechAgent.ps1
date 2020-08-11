<#
.NOTES
    - Use the $installBlob to specify the appropriate install file to install or remove Labtech Agent.
#>

param(
[Parameter(Mandatory=$true)]
[ValidateSet('Install','Uninstall')]
[String[]]
$Mode,
[String]
$installBlob
)

## Install block ##
if($Mode -eq "Install") {

    try {

    $Path = $env:TEMP
    $Installer = "LTInstall.exe"
    Invoke-WebRequest $installBlob -OutFile "$Path\$Installer"
    Start-Process -FilePath "$Path\$Installer" -ArgumentList "/sAll /rs /rps /msi /norestart /quiet EULA_ACCEPT=YES" -Verb RunAs -Wait
    Remove-Item "$Path\$Installer"

    } catch {

        Exit 1618

    }

} 


## Uninstall block ##
if($Mode -eq "Uninstall") {

    try {

    $Path = $env:TEMP
    $Installer = "LTUninstall.exe"
    Invoke-WebRequest $installBlob -OutFile "$Path\$Installer"
    Start-Process -FilePath "$Path\$Installer" -ArgumentList "/sAll /rs /rps /msi /quiet EULA_ACCEPT=YES" -Verb RunAs -Wait

    } catch {

        Exit 1618
        
    }

} 

Exit 0

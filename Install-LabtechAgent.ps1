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
powershell.exe -ExecutionPolicy Bypass -file Deploy-InstallScript.ps1 -mode install -scripturl "https://cpwmintune.blob.core.windows.net/scripts/Install-Msi.ps1" -scriptargs "-downloadurl 'https://cpwmintune.blob.core.windows.net/installers/WFBS-SVC_Agent_Installer.msi?sp=r&st=2020-07-13T21:21:34Z&se=2024-07-14T05:21:34Z&spr=https&sv=2019-10-10&sr=b&sig=NAHf90RqRXogxGjScWw1WXovxwz%2Firq6JzI7vGXp3pA%3D'"

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

param(
[Parameter(Mandatory=$true)]
[ValidateSet('Install','Uninstall')]
[String[]]
$Mode
)


## Install block ##
if($Mode -eq "Install") {
    $Path = $env:TEMP
    $url = "https://download.microsoft.com/download/A/6/A/A6A9217D-8980-45D1-BAF4-E813107989FA/CRM2016-Client-ENU-amd64.exe"
    #$cfgurl = ""
    #$cfg = "Client_Config.xml"
    $Installer = "CRM2016-Client-ENU-amd64.exe"
    $installer2 = "SetupClient.exe"
    $extractpath = "C:\Dynamics"
    Invoke-WebRequest $url -OutFile $Path\$Installer
    Start-Process -FilePath $path\$Installer -Args "/Q /extract:`"$extractpath`"" -Verb RunAs -Wait
    #Invoke-WebRequest $cfgurl -OutFile $extractpath\$cfg
    Start-Process -FilePath $extractpath\$Installer2 -Args "/Q /l $extractpath\crmlog.log /installofflinecapability /targetdir `"c:\Program Files\Microsoft Dynamics CRM Client`"" -Verb RunAs -Wait
    #Start-Process -Filepath "C:\Program Files\Microsoft Dynamics CRM Client\Client\ConfigWizard\Microsoft.Crm.Application.Outlook.ConfigWizard.exe" -ArgumentList "/Q /i 'C:\Program Files\Microsoft Dynamics CRM Client\Default_Client_Config.xml' /xa /l `"$extractpath\crmclientlog.log`"" -Verb RunAs -Wait
    Remove-Item $Path\$Installer
    Exit 0
    }
    

## Uninstall block ##
if($Mode -eq "Uninstall") {
    $uninstall_strings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "Microsoft Dynamics 365 for Microsoft Office Outlook" } | Select-Object -Property DisplayName, UninstallString, PSChildName
        foreach ($uninstall_string in $uninstall_strings) {
            $string = $uninstall_string.PSChildName
            $LogPath = "c:\ksmc\uninstalllog_$(get-date -Format yyyyMMddTHHmmss).log"
            Start-Process "$env:Windir\System32\msiexec.exe" -ArgumentList "/x$string /qn /L*V `"$logPath`"" -Wait -PassThru
        }
    Exit 0
    }

Exit 1618





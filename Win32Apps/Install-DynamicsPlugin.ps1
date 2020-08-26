param(
[Parameter(Mandatory=$true)]
[ValidateSet('Install','Uninstall')]
[String[]]
$Mode
)

#Change These Variables Per App
$appname = "Microsoft Dynamics 365" #needs to match Uninstall DisplayName in Registry
$appurl64 = "https://download.microsoft.com/download/A/6/A/A6A9217D-8980-45D1-BAF4-E813107989FA/CRM2016-Client-ENU-amd64.exe" #url to pull app from (GitHub, Azure Blob, etc.)
$appurl32 = "https://download.microsoft.com/download/A/6/A/A6A9217D-8980-45D1-BAF4-E813107989FA/CRM2016-Client-ENU-i386.exe" #url to pull app from (GitHub, Azure Blob, etc.)
$addtlargs = "" #any additional args needed for install command
$installertype = "exe" # 'msi' or 'exe'

# check for office install
$bitnesskey = "HKLM:\SOFTWARE\Microsoft\Office\16.0\Outlook"
$officebitness = Get-ItemProperty -Path $bitnesskey | Select-Object -ExpandProperty Bitness

$appnamel = $appname.Replace(" ","-")
$Path = $env:TEMP
$logpath = "$env:SystemRoot\Temp\IntuneLogs"
$applog = "$logpath\$appnamel-"+(Get-Date -Format "MMddyyyy")+".log"
if (!(Test-Path $logpath)) { New-Item -ItemType Directory -Path $logpath -Force | Out-Null }

## Install block ##
if($Mode -eq "Install") {
    $date = Get-Date -Format "MM/dd/yyyy-HH:mm:ss"
    $(
        Write-Output "Date: $date" 
        Write-Output "Temp path is set: $path"
        $Installer = "$appnamel.$installertype"

        if ($officebitness -eq "x64") {
            Write-Output "Downloading Installer `"$installer`" from `"$appurl64`""
            Invoke-WebRequest $appurl64 -OutFile $Path\$Installer
        } elseif ($officebitness -eq "x32") {
            Write-Output "Downloading Installer `"$installer`" from `"$appurl32`""
            Invoke-WebRequest $appurl32 -OutFile $Path\$Installer
        } else {
            Write-Output "Office version not detected. Is Office installed?"
            Exit 1618
        }

        ## Custom Install - different from standard template ##
        $installer2 = "SetupClient.exe"
        $extractpath = "C:\Dynamics"
        Write-Output "Extracting Installer to $extractpath"
        Start-Process -FilePath $path\$Installer -Args "/Q /extract:`"$extractpath`"" -Verb RunAs -Wait
        Write-Output "Running Installer $extractpath\$Installer2"
        Start-Process -FilePath $extractpath\$Installer2 -Args "/Q /l $extractpath\crmlog.log /installofflinecapability /targetdir `"c:\Program Files\Microsoft Dynamics CRM Client`"" -Verb RunAs -Wait
        ## end of custom install section

        Write-Output "Cleaning-up Installer"
        Remove-Item $Path\$Installer

        #add any post-install tasks here

        Write-Output "Install Complete!"
        Write-Output "############################################################"
    ) *>&1 >> $applog
    Exit 0
}

## Uninstall block ##
if($Mode -eq "Uninstall") {
    $date = Get-Date -Format "MM/dd/yyyy-HH:mm:ss"
    $(
        Write-Output "Date: $date" 
        Write-Output "Pulling Uninstall Strings"
        $uninstall_strings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "$appname" } | Select-Object -Property DisplayName, UninstallString, PSChildName
        foreach ($uninstall_string in $uninstall_strings) {
            Write-Output "Running uninstall: $uninstall_string"
            if ($uninstall_string.UninstallString -match "MsiExec.exe*") { $installertype = "msi" }
            if ($installertype -eq "exe") {

                ## Custom uninstall - different from standard template ##
                $string = "C:\Program Files\Microsoft Dynamics CRM Client\Client\SetupClient.exe"
                $addtlargs = "/ALLOWRUN /X /Q"
                Write-Output "Running Uninstall $string $addtlargs"
                ## end custom uninstall section 

                
                Start-Process $string -ArgumentList "$addtlargs" -Verb RunAs -Wait 
            } elseif ($installertype -eq "msi") {
                $string = $uninstall_string.PSChildName
                $Logfile = "$logpath\uninstalllog-$appnamel-$(get-date -Format yyyyMMddTHHmmss).log"
                Write-Output "msiexec uninstall log: $logfile"
                Start-Process "$env:Windir\System32\msiexec.exe" -ArgumentList "/x$string /qn /L*V `"$logfile`"" -Verb RunAs -Wait -PassThru
            } else {
                Write-Output "Unrecognized installer type: $installertype"
            }
        }
        
        #add any post-uninstall tasks here
        Remove-Item -Path $extractpath -Force -Recurse   
    
        Write-Output "Uninstall Complete!"
        Write-Output "############################################################"
    ) *>&1 >> $applog
    Exit 0
}
Exit 1618
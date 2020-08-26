param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Install','Uninstall')]
    [String]$Mode
)

#Change These Variables Per App
$appname = "" #needs to match Uninstall DisplayName in Registry
$appurl = "" #url to pull app from (GitHub, Azure Blob, etc.)
$addtlargs = "" #any additional args needed for install command
$installertype = "" # 'msi' or 'exe'

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
        Write-Output "Downloading Installer `"$installer`" from `"$appurl`""
        Invoke-WebRequest $appurl -OutFile $Path\$Installer
        if ($installertype -eq "exe") {
            Write-Output "Running as .exe with additional args: $addtlargs"
            if ($null -match $addtlargs) {
                $InstallCommand = Start-Process -FilePath $Path\$Installer -Verb RunAs -Wait    
            } else {
                $InstallCommand = Start-Process -FilePath $Path\$Installer -Args "$addtlargs" -Verb RunAs -Wait
            }
        } elseif ($installertype -eq "msi") {
            Write-Output "Running as .msi with additional args: $addtlargs"
            $InstallCommand = Start-Process $env:WinDir\System32\msiexec.exe -ArgumentList "/I $Path\$Installer /qn $addtlargs" -Verb RunAs -Wait
        } else {
            Write-Output "Unknown installer type: $installertype"
        }
        Write-Output "Cleaning-up Installer"
        Remove-Item $Path\$Installer

        #add any post-install tasks here

        Write-Output "Install Complete!"
        Write-Output "############################################################"
    ) *>&1 >> $applog
    Exit $InstallCommand.ExitCode
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
                $string = $uninstall_string.UninstallString
                Write-Output "Running Uninstall mode: exe"
                if ($null -match $addtlargs) {
                    $UninstallCommand = Start-Process $string -Verb RunAs -Wait 
                } else {
                    $UninstallCommand = Start-Process $string -ArgumentList "$addtlargs" -Verb RunAs -Wait
                }
            } elseif ($installertype -eq "msi") {
                $string = $uninstall_string.PSChildName
                $Logfile = "$logpath\uninstalllog-$appnamel-$(get-date -Format yyyyMMddTHHmmss).log"
                Write-Output "msiexec uninstall log: $logfile"
                $UninstallCommand = Start-Process "$env:Windir\System32\msiexec.exe" -ArgumentList "/x$string /qn /L*V `"$logfile`"" -Verb RunAs -Wait -PassThru
            } else {
                Write-Output "Unrecognized installer type: $installertype"
            }
        }
        
        #add any post-uninstall tasks here

        Write-Output "Uninstall Complete!"
        Write-Output "############################################################"
    ) *>&1 >> $applog
    Exit $UninstallCommand.ExitCode
}
Exit 1618


## expand logging to capture errors 
param(
[Parameter(Mandatory=$true)]
[ValidateSet('Install','Uninstall')]
[String]$Mode,
$localfile
)

#Change These Variables Per App
$appname = "Labtech" #needs to match Uninstall DisplayName in Registry
$appurl = "" #url to pull app from (GitHub, Azure Blob, etc.)
$addtlargs = "/sAll /rs /rps /msi /norestart EULA_ACCEPT=YES" #any additional args needed for install command
$installertype = "exe" # 'msi' or 'exe'
$localinstaller = "Agent_Install.exe" #file name of installer
$applicationexe = "C:\Windows\LTSvc\LTsvc.exe" #location of exe post-install CURRENTLY UNUSED

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
        
        
        if ($localfile -eq $true) {
            $path = "."
            Write-Output "Temp path is set: $path , Local Installer"
            $Installer = "$localinstaller"
            if (!(Test-Path "$path\$installer")) { Write-Ouput "Local Installer Not Found"}
        } else {
            Write-Output "Temp path is set: $path"
            $Installer = "$appnamel.$installertype"
            Write-Output "Downloading Installer `"$installer`" from `"$appurl`""
            Invoke-WebRequest $appurl -OutFile $Path\$Installer
            if (!(Test-Path $Path\$Installer)) {Write-Output "Download failed"}
        }
        
        if ($installertype -eq "exe") {
            if ($null -match $addtlargs) {
                Write-Output "Running as .exe with no args"
                $InstallCommand = Start-Process -FilePath $Path\$Installer -Verb RunAs -Wait    
            } else {
                Write-Output "Running as .exe with additional args: $addtlargs"
                $InstallCommand = Start-Process -FilePath $Path\$Installer -ArgumentList "$addtlargs" -Verb RunAs -Wait
                Write-Output "Install output: $InstallCommand"
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
        
        ## custom uninstall script - different from standard template ##
        Write-Output "Importing LT Module to Run Uninstall"
        (new-object Net.WebClient).DownloadString('https://bit.ly/LTPoSh') | iex
        Write-Output "Running Uninstall"
        Uninstall-LTService    
        ## end custom section

        #add any post-uninstall tasks here

        Write-Output "Uninstall Complete!"
        Write-Output "############################################################"
    ) *>&1 >> $applog
    Exit 0
}

Exit 1618
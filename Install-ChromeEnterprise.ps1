    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Install','Uninstall')]
        [String]$Mode
    )

    ## Install block ##
    if($Mode -eq "Install") {
        $Path = $env:TEMP
        $Installer = "chrome_enterprise64.msi"
        Invoke-WebRequest "https://dl.google.com/chrome/install/googlechromestandaloneenterprise64.msi" -OutFile $Path\$Installer
        $InstallCommand = Start-Process -FilePath $env:Windir\System32\msiexec.exe -ArgumentList "/i $Path\$Installer /qn" -Verb RunAs -Wait -PassThru
        Remove-Item $Path\$Installer
        Exit $InstallCommand.ExitCode
    }


    ## Uninstall block ##
    if($Mode -eq "Uninstall") {
        $uninstall_strings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "chrome" } | Select-Object -Property DisplayName, UninstallString, PSChildName
            foreach ($uninstall_string in $uninstall_strings) {
            $string = $uninstall_string.PSChildName
            $LogPath = "$env:windir\Temp\ChromeUninstall_$(get-date -Format yyyyMMddTHHmmss).log"
                $Arguments = @(
                    "/x"
                    "$string"
                    "/qn"
                    "/L*"
                    "$LogPath"
                )
            $UninstallCommand = Start-Process msiexec.exe -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
            }
        Exit $UninstallCommand.ExitCode
    }

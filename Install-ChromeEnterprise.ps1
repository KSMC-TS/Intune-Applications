    param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Install','Uninstall')]
    [String[]]
    $Mode
    )


    ## Install block ##
    if($Mode -eq "Install") {
        $Path = $env:TEMP
        $Installer = "chrome_enterprise64.msi"
        Invoke-WebRequest "https://dl.google.com/chrome/install/googlechromestandaloneenterprise64.msi" -OutFile $Path\$Installer
        Start-Process -FilePath $env:Windir\System32\msiexec.exe -ArgumentList "/i $Path\$Installer /qn" -Verb RunAs -Wait
        Remove-Item $Path\$Installer
        Exit 0
        }


    ## Uninstall block ##
    if($Mode -eq "Uninstall") {
        $uninstall_strings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "chrome" } | Select-Object -Property DisplayName, UninstallString, PSChildName
            foreach ($uninstall_string in $uninstall_strings) {
            $string = $uninstall_string.PSChildName
            Start-Process "msiexec.exe" -ArgumentList "/X$string /qn" -Wait -NoNewWindow
            }
        Exit 0
        }

    Exit 1618

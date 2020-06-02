<#
.DESCRIPTION
    Generic MSI downloader and installation script.
.PARAMETER DownloadUrl
    Specify URL that the MSI is available at - Blob with SAS or publicly accessible URL.
.PARAMETER Uninstall
    Specify string used to search for uninstall string - example: uninstalling Google Chrome - .\Install-Msi.ps1 -Uninstall "chrome"
.NOTES
    Version:        0.1
    Last updated:   06/02/2020
    Creation date:  06/02/2020
    Author:         Zachary Choate
    URL:            https://raw.githubusercontent.com/zchoate/Intune-Applications/master/Install-Msi.ps1
#>

param(
        [String]$downloadUrl,
        [String]$uninstall
    )

$argsString = ""
If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        foreach($k in $MyInvocation.BoundParameters.keys)
        {
            switch($MyInvocation.BoundParameters[$k].GetType().Name)
            {
                "SwitchParameter" {if($MyInvocation.BoundParameters[$k].IsPresent) { $argsString += "-$k " } }
                "String"          { $argsString += "-$k `"$($MyInvocation.BoundParameters[$k])`" " }
                "Int32"           { $argsString += "-$k $($MyInvocation.BoundParameters[$k]) " }
                "Boolean"         { $argsString += "-$k `$$($MyInvocation.BoundParameters[$k]) " }
            }
        }
        Start-Process -FilePath "$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -ArgumentList "-File `"$($PSScriptRoot)\$($MyInvocation.MyCommand)`" $($argsString)" -Wait -NoNewWindow
    }
    Catch {
        Throw "Failed to start 64-bit PowerShell"
    }
    Exit
}


    ## Install block ##
    if($downloadUrl) {
        $Path = $env:TEMP
        $baseUrl = (($downloadUrl -split "\?")[0]) -split "\/"
        $Installer = $baseUrl[$baseUrl.Count - 1].Replace("%20","")
        Invoke-RestMethod -Uri $downloadUrl -OutFile $Path\$Installer -UseBasicParsing
        $InstallCommand = Start-Process -FilePath "$env:Windir\System32\msiexec.exe" -ArgumentList "/i $Path\$Installer /qn" -Verb RunAs -Wait -PassThru
        #Remove-Item $Path\$Installer
        Exit $InstallCommand.ExitCode
    }


    ## Uninstall block ##
    if($uninstall) {
        $uninstall_strings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match $uninstall } | Select-Object -Property DisplayName, UninstallString, PSChildName
            foreach ($uninstall_string in $uninstall_strings) {
            $string = $uninstall_string.PSChildName
            $LogPath = "$env:Temp\$($uninstall)_$(get-date -Format yyyyMMddTHHmmss).log"
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

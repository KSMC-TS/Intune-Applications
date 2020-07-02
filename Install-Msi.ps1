<#
.DESCRIPTION
    Generic MSI downloader and installation script.
.PARAMETER DownloadUrl
    Mutually exclusive with following parameters: PackagedInstaller and Uninstall.
    Specify URL that the MSI is available at - Blob with SAS or publicly accessible URL.
.PARAMETER PackagedInstaller
    Mutually exclusive with following parameters: DownloadUrl and Uninstall.
    Specify MSI file name bundled in script root directory for packaged install.
.PARAMETER Uninstall
    Mutually exclusive with following parameters: DownloadUrl and PackagedInstaller.
    Specify string used to search for uninstall string.
.EXAMPLE
    Download and install example:
        .\Install-Msi.ps1 -DownloadUrl "https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7BC5AE0988-4DCB-4E38-2EED-6988F8EDD1F3%7D%26lang%3Den%26browser%3D3%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dtrue%26ap%3Dx64-stable-statsdef_0%26brand%3DGCEA/dl/chrome/install/googlechromestandaloneenterprise64.msi"
    Install using installer bundled with script in PSScriptRoot example:
        .\Install-Msi.ps1 -PackagedInstaller "googlechromestandaloneenterprise64.msi"
    Uninstall example:
        .\Install-Msi.ps1 -Uninstall "chrome"
.NOTES
    Version:        0.3
    Last updated:   06/04/2020
    Creation date:  06/02/2020
    Author:         Zachary Choate
    URL:            https://raw.githubusercontent.com/zchoate/Intune-Applications/main/Install-Msi.ps1
#>

param(
        [parameter(ParameterSetName="mode")]
        [String]$downloadUrl,
        [parameter(ParameterSetName="mode")]
        [String]$packagedInstaller,
        [parameter(ParameterSetName="mode")]
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
    ## web installer block ##

        $Path = $env:TEMP
        if ($downloadUrl -like "*/*.msi*") {
            $Installer = ($downloadUrl | Select-String -Pattern "[\w\%\.]+\.msi").Matches.Value.Replace("%20","").Replace("%","")
        } else {
            Try {
                $baseUrl = ($downloadUrl | Select-String -Pattern "http[s]*:\/\/[\w\.\:]*").Matches.Value
                $urlSuffix = ($downloadUrl.Replace($baseUrl,"") | Select-String -Pattern "[\w\%\.]+").Matches.Value.Replace("%20","").Replace("%","")
            } catch {
                $urlSuffix = $null
            }
            $Installer = "$($urlSuffix)Msi_$(get-date -Format yyyyMMddTHHmmss).msi"
        }
        Invoke-RestMethod -Uri $downloadUrl -OutFile $Path\$Installer -UseBasicParsing
        $InstallCommand = Start-Process -FilePath "$env:Windir\System32\msiexec.exe" -ArgumentList "/i $Path\$Installer /qn" -Wait -PassThru
        Remove-Item $Path\$Installer
        Exit $InstallCommand.ExitCode

    } elseif ($packagedInstaller) {
    ## packaged installer block ##

        $InstallCommand = Start-Process -FilePath "$env:Windir\System32\msiexec.exe" -ArgumentList "/i $PSScriptRoot\$packagedInstaller /qn" -Wait -PassThru
        Exit $InstallCommand.ExitCode

    } elseif ($uninstall) {
    ## Uninstall block ##

        $uninstall_strings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match $uninstall } | Select-Object -Property DisplayName, UninstallString, PSChildName
            foreach ($uninstall_string in $uninstall_strings) {
            $string = $uninstall_string.PSChildName
            $LogPath = "$env:Temp\$($uninstall)_$(get-date -Format yyyyMMddTHHmmss).log"
            $UninstallCommand = Start-Process "$env:Windir\System32\msiexec.exe" -ArgumentList "/x$string /qn /L*V `"$logPath`"" -Wait -PassThru
            }
        Exit $UninstallCommand.ExitCode

    }

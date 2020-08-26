param(
[Parameter(Mandatory=$true)]
[ValidateSet('Install','Uninstall')]
[String[]]
$Mode
)


## Install block ##
if($Mode -eq "Install") {

    $workd = $env:TEMP
    $text = '
    INSTALL_SILENT=Enable
    AUTO_UPDATE=Enable
    SPONSORS=Disable
    REMOVEOUTOFDATEJRES=1
    '
    $text | Set-Content "$workd\jreinstall.cfg"
    $source = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=241536_1f5b5a70bf22433b84d0e960903adac8"
    $destination = "$workd\jreInstall.exe"
    $client = New-Object System.Net.WebClient
    $client.DownloadFile($source, $destination)

    Start-Process -FilePath "$workd\jreInstall.exe" -ArgumentList INSTALLCFG="$workd\jreinstall.cfg"
    Start-Sleep -s 180
    rm -Force $workd\jre* 
    Exit 0
}


## Uninstall block ##
if($Mode -eq "Uninstall") {
    $uninstall_strings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "java" } | Select-Object -Property DisplayName, UninstallString, PSChildName
        foreach ($uninstall_string in $uninstall_strings) {
        $string = $uninstall_string.PSChildName
        Start-Process "msiexec.exe" -ArgumentList "/X$string /qn" -Wait -NoNewWindow
        }
    Exit 0
    }

Exit 1618





param(
[Parameter(Mandatory=$true)]
[ValidateSet('Install','Uninstall')]
[String[]]
$Mode
)

## Install block ##
if($Mode -eq "Install") {

    try {
    
    $Path = $env:TEMP
    $tempInstaller = "lastpass.exe"
    $Installer = "LastPassInstaller.msi"
    Invoke-WebRequest "https://download.cloud.lastpass.com/windows_installer/LastPassInstaller.exe" -OutFile "$Path\$tempInstaller"
    # Launch the installer as a process to grab the MSI that gets dropped in the temp directory, then kill it since we don't need it.
    $process = Start-Process "$Path\$tempInstaller" -NoNewWindow -PassThru
    Start-Sleep -s 5
    if (Test-Path -Path "$Path\$Installer") {
        Copy-Item "$Path\$Installer" -Destination "$Path\1_$Installer"
        Stop-Process $process -Force
        Start-Process msiexec -ArgumentList "/i $Path\1_$Installer /qn ADDLOCAL=ExplorerExtension,ChromeExtension,FirefoxExtension,EdgeExtension,LastpassUwpApp,DesktopShortcut,Updater,BinaryComponent" -Wait
        } else {
            Exit 1618
        }
    Remove-Item "$Path\1_$Installer"
    Remove-Item "$Path\$Installer"
    Remove-Item "$Path\$tempInstaller"

    } catch {

        Exit 1618

    }

}

## Uninstall block ##
if($Mode -eq "Uninstall") {

    try {

    $uninstall_strings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "lastpass" } | Select-Object -Property DisplayName, UninstallString, PSChildName
    foreach ($uninstall_string in $uninstall_strings) {
    $string = $uninstall_string.PSChildName
    Start-Process msiexec -ArgumentList "/X$string /qn" -Wait -NoNewWindow
    }


    } catch {

        Exit 1618

    }

}

Exit 0
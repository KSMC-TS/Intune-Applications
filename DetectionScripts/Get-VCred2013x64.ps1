$appToCheck = "*Microsoft Visual C++ 2013 Redistributable (x64)*"

$uninstallString = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -like $appToCheck } | Select-Object -Property DisplayName
if($uninstallString) {
    Write-Host "Houston, we've detected the application."
}

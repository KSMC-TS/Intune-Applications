## pull logs 
$logpath = "c:\ksmc\logs\intune"
if (!(Test-Path $logpath)) {New-Item -ItemType Directory -Path $logpath -Force | Out-Null}

# Applications and Services Logs > Microsoft > Windows > DeviceManagement-Enterprise-Diagnostic-Provider
$logname = "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin"
$csv = "$logpath\intuneevents-"+(Get-Date -Format "MMddyyyy")+".csv"
if ($logname) {
    Write-Output "Saving copy of Intune event logs"
    $mdmlogs = Get-WinEvent -FilterHashTable @{Logname="$logname"}
    $mdmlogs | Select-Object OpcodeDisplayName,ID,RecordID,TimeCreated,Message | Export-Csv $csv
} else {
    Write-Output "Intune Event Logs are missing.."
}

#intune management extension logs
$intunelog = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"
$logout = "$logpath\MIMELog-"+(Get-Date -Format "MMddyyyy")+".log"
if ($intunelog) {
    Write-Output "Saving copy of Intune management extension log"
    $logcontent = Get-Content $intunelog
    $logcontent | Out-File $logout
} else {
    Write-Output "Intune management extension log is missing.."
}

#app install logs
$applogspath = "$env:SystemRoot\Temp\IntuneLogs"
$applogs = (Get-ChildItem $applogspath\*.log)
Write-Output "Copying Intune Win32App Install Logs.."
Copy-Item $applogs $logpath -Force

Write-Output "Logs saved to: $logpath"

## clear guid of app from every user on : HKLM:\Software\Microsoft\IntuneManagementExtension\Win32Apps\
$registrypath = "HKLM:\Software\Microsoft\IntuneManagementExtension\Win32Apps\"
$intuneguid = Get-ChildItem -path $registrypath | Select-Object * | Where-Object {($_.Name -notmatch "00000000-0000-0000-0000-000000000000") -and ($_.Name -notmatch "Reporting")} | Select-Object -ExpandProperty PSChildName
$appkeys = Get-ChildItem -Path $registrypath\$intuneguid | Select-Object -ExpandProperty PSChildName
Write-Output "Clearing Win32Apps from Registry.."
# delete all apps for full reset
foreach ($appkey in $appkeys) {
    Remove-Item $registrypath\$intuneguid\$appkey -Recurse
}

## Restart Intune management extension agent service
Write-Output "Restarting Service.."
Get-Service -DisplayName "*Intune*" | Restart-Service
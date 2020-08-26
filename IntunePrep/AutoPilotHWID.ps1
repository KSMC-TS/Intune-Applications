
Input Method 
CSV, AD, LT Script (standalone)

Output 
Blob Storage, File Share, Local Folder






function Get-HWID {
    param (
        
    )

}















c:\\HWID
Set-Location c:\\HWID
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted
Install-Script -Name Get-WindowsAutoPilotInfo
Get-WindowsAutoPilotInfo.ps1 -OutputFile AutoPilotHWID.csv





<#

.SYNOPSIS
Enable Wake On LAN settings on NIC in Windows

.DESCRIPTION

IMPORTANT NOTE: I borrowed some from the WMI portions from here: http://justanothertechnicalblog.blogspot.com/2012/06/setting-power-management-options-on.html

This script will set the appropriate Windows-side 
Wake-On LAN settings on the NIC that is currently 
CONNECTED and has a match for the name "Ethernet" 
OR "Local Area Connection"

This script will check/set the following: 

1. "Allow the device to wake the computer" to CHECKED
2. "Only allow a magic packet to wake the computer" to CHECKED
3. "Energy Efficient Ethernet" to OFF
4. Fast Startup to DISABLED (Windows 8-10 only)

===============================================================
If your NIC is named something else, just change the "-match"
references on the "Get-NetAdapter" command below
===============================================================

NOTE: You will still need to make certain Wake On LAN is enabled
in the BIOS.

written by Mike Resnick 05-15-2018

#>

$nic = Get-NetAdapter | ? {($_.MediaConnectionState -eq "Connected") -and (($_.name -match "Ethernet") -or ($_.name -match "local area connection"))}
$nicPowerWake = Get-WmiObject MSPower_DeviceWakeEnable -Namespace root\wmi | where {$_.instancename -match [regex]::escape($nic.PNPDeviceID) }
If ($nicPowerWake.Enable -eq $true)
{
    # All good here
    write-output "MSPower_DeviceWakeEnable is TRUE"
}
Else
{
    write-output "MSPower_DeviceWakeEnable is FALSE. Setting to TRUE..."
    $nicPowerWake.Enable = $True
    $nicPowerWake.psbase.Put()
}

$nicMagicPacket = Get-WmiObject MSNdis_DeviceWakeOnMagicPacketOnly -Namespace root\wmi | where {$_.instancename -match [regex]::escape($nic.PNPDeviceID) }
If ($nicMagicPacket.EnableWakeOnMagicPacketOnly -eq $true)
{
    # All good here
    write-output "EnableWakeOnMagicPacketOnly is TRUE"
}
Else
{
    write-output "EnableWakeOnMagicPacketOnly is FALSE. Setting to TRUE..."
    $nicMagicPacket.EnableWakeOnMagicPacketOnly = $True
    $nicMagicPacket.psbase.Put()
}

# Since different NICs will have different registry keys,
# this recursively scans through the reigstry to find the
# the EEELinkAdvertisement property
$FindEEELinkAd = Get-ChildItem "hklm:\SYSTEM\ControlSet001\Control\Class" -Recurse -ErrorAction SilentlyContinue | % {Get-ItemProperty $_.pspath} -ErrorAction SilentlyContinue | ? {$_.EEELinkAdvertisement} -ErrorAction SilentlyContinue
If ($FindEEELinkAd.EEELinkAdvertisement -eq 1)
{
    Set-ItemProperty -Path $FindEEELinkAd.PSPath -Name EEELinkAdvertisement -Value 0
    # Check again
    $FindEEELinkAd = Get-ChildItem "hklm:\SYSTEM\ControlSet001\Control\Class" -Recurse -ErrorAction SilentlyContinue | % {Get-ItemProperty $_.pspath} | ? {$_.EEELinkAdvertisement}
    If ($FindEEELinkAd.EEELinkAdvertisement -eq 1)
    {
        write-output "$($env:computername) - ERROR - EEELinkAdvertisement set to $($FindEEELinkAd.EEELinkAdvertisement)"
    }
    Else
    {
        write-output "$($env:computername) - SUCCESS - EEELinkAdvertisement set to $($FindEEELinkAd.EEELinkAdvertisement)"
    }
}
Else
{
    write-output "EEELinkAdvertisement is already turned OFF"
}



# Disable Fast Startup in Windows 8-10 (Fast Startup breaks Wake On LAN)
If ((gwmi win32_operatingsystem).caption -match "Windows 8")
{
    write-output "Windows 8.x detected. Disabling Fast Startup, as this breaks Wake On LAN..."
    powercfg -h off
}
ElseIf ((gwmi win32_operatingsystem).caption -match "Windows 10")
{
    write-output "Windows 10 detected. Disabling Fast Startup, as this breaks Wake On LAN..."
    # This checks if HiberbootEnabled is equal to 1
    $FindHiberbootEnabled = Get-ItemProperty "hklm:\SYSTEM\CurrentControlSet\Control\Session?Manager\Power" -ErrorAction SilentlyContinue
    If ($FindHiberbootEnabled.HiberbootEnabled -eq 1)
    {
        write-output "HiberbootEnabled is Enabled. Setting to DISABLED..."
        Set-ItemProperty -Path $FindHiberbootEnabled.PSPath -Name "HiberbootEnabled" -Value 0 -Type DWORD -Force | Out-Null
    }
    Else
    {
        write-output "HiberbootEnabled is already DISABLED"
    }
}


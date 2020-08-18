## deprecated, can now deploy straight from Intune

$BLinfo = Get-Bitlockervolume

if($BLinfo.EncryptionPercentage -ne '100' -and $BLinfo.EncryptionPercentage -ne '0'){
    Resume-BitLocker -MountPoint "C:"
    $BLV = Get-BitLockerVolume -MountPoint "C:" | select *
    BackupToAAD-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $BLV.KeyProtector[1].KeyProtectorId
}
if($BLinfo.VolumeStatus -eq 'FullyEncrypted' -and $BLinfo.ProtectionStatus -eq 'Off'){
    Resume-BitLocker -MountPoint "C:"
    $BLV = Get-BitLockerVolume -MountPoint "C:" | select *
    BackupToAAD-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $BLV.KeyProtector[1].KeyProtectorId
}
if($BLinfo.EncryptionPercentage -eq '0'){
    Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -SkipHardwareTest -RecoveryPasswordProtector
    $BLV = Get-BitLockerVolume -MountPoint "C:" | select *
    BackupToAAD-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $BLV.KeyProtector[1].KeyProtectorId
}
    Param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Install", "Uninstall")]
    [String[]]
    $Mode
    )
     
    If ($Mode -eq "Install") {
            #Online installer
            Enable-WindowsOptionalFeature -Online -FeatureName 'NetFx3' -NoRestart
            Exit 0
            }
     
    If ($Mode -eq "Uninstall") {
        Disable-WindowsOptionalFeature -Online -FeatureName 'NetFx3' -Remove -NoRestart
        Exit 0
        }

    Exit 1618

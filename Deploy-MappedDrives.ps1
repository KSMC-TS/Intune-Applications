$drivemaplist = @("I:\\quad.local\company\IGF",
"N:\\quad.local\company\INS Plans",
"M:\\quad.local\company\ledger",
"P:\\quad.local\company\share",
"T:\\quad.local\company\fair plan images",
"X:\\quad.local\company\claim backup", ##restricted
"R:\\quad.local\company\restricted") ##restricted

foreach ($drive in $drivemaplist) {
    $driveletter = $drive.Split(":")[0]
    $drivepath = $drive.Split(":")[1] 
    New-PSDrive -Name $driveletter -Root "$drivepath" -Persist -PSProvider "FileSystem"
}
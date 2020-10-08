param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Install','Uninstall')]
    [String]$Mode
)

<# Drive Files
Driver files need to be packaged with the IntuneWin
Name folder for mfg (ex- sharp hp)
Name subfolder for Driver Model (ex- Sharp UD3)
Name subfolders for driver type (ex- PCL6 PS)
Name subfolders for architecture type (ex- 32bit 64bit)
#>

#Change These Variables Per App
$drivername = "" #needs to match Driver Name (string in .inf)
$drivermfg = "" #Hardware vendor for printer (ex- sharp)
$drivermodel = "" #model of printer / universal (ex- UD3)
$drivertype = "" # PCL6 / PS
$printername = "" #user friendly name for printer
$printerip = "" # IP/FQDN address of printer

$arch = ((Get-CimInstance CIM_OperatingSystem).OSArchitecture).Replace("-","")
$driverfiles = "$psscriptroot\$drivermfg\$drivermodel"
$printernamel = $printername.Replace(" ","-")
$logpath = "$env:SystemRoot\Temp\IntuneLogs"
$applog = "$logpath\$printernamel-"+(Get-Date -Format "MMddyyyy")+".log"
if (!(Test-Path $logpath)) { New-Item -ItemType Directory -Path $logpath -Force | Out-Null }

## Install block ##
if($Mode -eq "Install") {
    $date = Get-Date -Format "MM/dd/yyyy-HH:mm:ss"
    $(
        Write-Output "Date: $date" 
        Write-Output "Pulling .inf(s) from: $driverfiles\$drivertype\$arch"
        $infs = Get-ChildItem -Path $driverfiles\$drivertype\$arch\*.inf 
        foreach ($inf in $infs) {
            Write-Output "Installing .inf: $inf"
            $installcommand = C:\Windows\SysNative\pnputil.exe /add-driver $inf /install
            $driverresults = ($InstallCommand -split '\r?\n')[3]
            if ($driverresults -notmatch "Driver package added successfully.") {
                Write-Output "Driver Install Failed: $drivername"
                Write-Output "Driver Type: $drivertype Arch: $arch"
                Write-Output "ExitCode: $code for .inf: $inf"
                Write-Output "PNPUtil Output: $installcommand"
                Write-Output "Install Failed"
                Write-Output "############################################################"
                Exit 1618
            } else {
                Write-Output "$driverresults"
            }
        }
        if (!(Get-PrinterDriver -name $drivername)) { 
            Write-Output "Adding Printer driver $drivername" 
            Add-PrinterDriver -Name $drivername 
        } else { 
            Write-Output "Printer driver $drivername already exists, skipping" 
        }
        if (!(Get-PrinterPort -Name $printernamel)) {
            Write-Output "Creating Printer port $printernamel with IP $printerip" 
            Add-PrinterPort -Name $printernamel -PrinterHostAddress $printerip 
        } else { 
            Write-Output "Printer port $printernamel already exists, checking IP"
            $portip = Get-PrinterPort -Name $printernamel | Select-Object -ExpandProperty PrinterHostAddress 
            if (!($portip -match $printerip)) {
                Write-Output "$portip doesn't match $printerip - updating"
                Remove-PrinterPort -Name $printernamel
                Add-PrinterPort -Name $printernamel -PrinterHostAddress $printerip 
            } else {
                Write-Output "Port IP is correct, skipping"
            }
        }
        if (!(Get-Printer -Name $printername)) { 
            Write-Output "Creating Printer $printername" 
            Add-Printer $printername -DriverName $drivername -PortName $printernamel 
        } else { 
            Write-Output "Printer $printername already exists, skipping"
        }

        

        #add any post-install tasks here

        Write-Output "Install Complete!"
        Write-Output "############################################################"
    ) *>&1 >> $applog
    Exit 0
}

## Uninstall block ##
if($Mode -eq "Uninstall") {
    $date = Get-Date -Format "MM/dd/yyyy-HH:mm:ss"
    $(
        Write-Output "Date: $date" 
        Write-Output "Uninstalling Printer: $Printername"
        Remove-Printer $printername
        Write-Output "Uninstalling Printer Port: $printernamel"
        Remove-PrinterPort $printernamel     
        Write-Output "Uninstalling Printer Driver: $drivername"   
        Remove-PrinterDriver $drivername
        Write-Output "Note: Printer Uninstall does not fully uninstall the driver from Windows"
                
        #add any post-uninstall tasks here

        Write-Output "Uninstall Complete!"
        Write-Output "############################################################"
    ) *>&1 >> $applog
    Exit 0
}
Exit 1618
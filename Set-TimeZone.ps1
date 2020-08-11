<# # Author: KSMC

Description: Pulls GPS coordinates and then queries Azure Map Service.
             Changes the time zone given the user's location.

Version: 1

Note: script currently non-functional. 

Intune can set Time Zone using Device Configuration Profile

Type: Custom
OMA-URI: ./Device/Vendor/MSFT/Policy/Config/TimeLanguageSettings/ConfigureTimeZone
Value: Time Zone String (can check with 'tzutil /g') Ex: "US Eastern Standard Time"

#>


$registryPath = "HKLM:\Software\Policies\Microsoft\Internet Explorer\Main"
$name = "DisableFirstRunCustomize"
$value = "1"

if(!(Test-Path $registryPath)){
    New-Item -Path $registryPath -Force | Out-Null
    New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
}
else{
    New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
}

Add-Type -AssemblyName System.Device #Required to access System.Device.Location namespace
$GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher #Create the required object
$GeoWatcher.Start() #Begin resolving current locaton

while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
    Start-Sleep -Milliseconds 100 #Wait for discovery.
}  

if ($GeoWatcher.Permission -eq 'Denied'){
    Write-Error 'Access Denied for Location Information'
} else {
    $subkey = ""
    $URL = "https://atlas.microsoft.com/timezone/byCoordinates/json?subscription-key=$subkey&api-version=1.0&query=" + $GeoWatcher.Position.Location.Latitude + "," + $GeoWatcher.Position.Location.Longitude
    $result = Invoke-WebRequest -Uri $URL -Method 'GET'
}

$timezone = $result.Content
$position1 = $timezone.IndexOf('"Standard"')
$timezone = $timezone.substring($position1+12)
$position2 = $timezone.IndexOf('"')
$timezone = $timezone.Substring(0,$position2)
Set-TimeZone $timezone
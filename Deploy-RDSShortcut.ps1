$source = "https://pmaintune.blob.core.windows.net/installers/PMA-RDS.rdp?sp=r&st=2020-02-18T02:59:07Z&se=2022-02-01T10:59:07Z&spr=https&sv=2019-02-02&sr=b&sig=Iz%2FEo1UDSuQmvaAOvoKLRyGL1Tg078tTyd9WN15tQYA%3D"
$Installdir = "c:\temp\install"
New-Item -Path $Installdir -ItemType directory
$destination = "$Installdir\PMA-RDS.rdp"
Invoke-WebRequest $source -OutFile $destination
$path = "C:\users\public\desktop"
Copy-Item   $destination $path
Remove-Item $destination
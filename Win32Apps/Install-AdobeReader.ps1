param(
[Parameter(Mandatory=$true)]
[ValidateSet('Install','Uninstall')]
[String[]]
$Mode
)

## Install block ##
if($Mode -eq "Install") {
    
    #set headers required for getting current Adobe Reader version and download URL
    $headers = @{
        "Host"="get.adobe.com"
        "User-Agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:71.0) Gecko/20100101 Firefox/71.0"
        "Accept"="*/*"
        "Accept-Language"="en-US,en;q=0.5"
        "Accept-Encoding"="gzip, deflate, br"
        "X-Requested-With"="XMLHttpRequest"
        "Referer"="https://get.adobe.com/reader/enterprise/"
        }

    #invoke web request with headers and parse json to pull download url
    $jsonRequest = Invoke-WebRequest "https://get.adobe.com/reader/webservices/json/standalone/?platform_type=Windows&platform_dist=Windows%2010&platform_arch=&language=English&eventname=readerotherversions" -Headers $headers -UseBasicParsing | ConvertFrom-Json
    $downloadUrl = $jsonRequest.download_url

    #set download location, installer name, pull down installer and begin silent install
    $Path = $env:TEMP
    $Installer = "adobe_reader.exe"
    Invoke-WebRequest $downloadUrl -OutFile $Path\$Installer
    Start-Process -FilePath $Path\$Installer -Args "/sAll EULA_ACCEPT=YES" -Verb RunAs -Wait
    Remove-Item $Path\$Installer
    Exit 0
    }


## Uninstall block ##
if($Mode -eq "Uninstall") {
    $uninstall_strings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "acrobat reader" } | Select-Object -Property DisplayName, UninstallString, PSChildName
        foreach ($uninstall_string in $uninstall_strings) {
        $string = $uninstall_string.PSChildName
        Start-Process "msiexec.exe" -ArgumentList "/X$string /qn" -Wait -NoNewWindow
        }
    Exit 0
    }
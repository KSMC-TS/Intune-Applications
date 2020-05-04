<#
.SYNOPSIS
    .
.DESCRIPTION
    Use this script to deploy and install fonts.
    Designed for use packaged as a Win32 app deployed via Intune.
    This script will deploy OpenType and TrueType fonts with no additional preparation but for Type1 fonts (pfm), a registry import is required. For
        simplicity sake, these are just the export of HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Type 1 Installer\Type 1 Fonts. I do have a note
        to try to dynamically build by grabbing the title of the fonts but I'm unable to determine how to grab that from the file contents.
    Adding additional fonts just requires an update to the files included and any relevent reg exports. This can be all in the root or in subfolders.
.PARAMETER packaged
    Switch to indicate font files are in the same directory as the script - $PSScriptRoot\Fonts
.PARAMETER storageURL
    URL to Azure Blob Storage Acct containter that has the font files.
.PARAMETER sasToken
    Access token required for access to Blob Storage Acct.
.PARAMETER installedString
    Used to check for existing deployment.
    Key created at HKLM:\SOFTWARE\WOW6432Node\fontDeploy
.PARAMETER logFile
    Specify location of log file. Otherwise log file will be created in $env:Temp.
.EXAMPLE
    Add-Font.ps1 -packaged -installedString "05-04-2020"
        This will run the script looking for fonts packaged with script in $PSScriptRoot\Fonts and update registry upon completion with string 05-04-2020.
    Add-Font.ps1 -storageURL "https://blobsfordays.blob.core.windows.net/container" -sasToken "sp=r&st=2020-05-04T..." -installedString "05-04-2020"
        This will run the script pulling down the fonts from the specified URL and update registry upon completion with string 05-04-2020.
.NOTES
    Version:            0.1
    Last updated:       05/04/2020
    Creation Date:      05/04/2020
    Author:             Zachary Choate
    URL:                
#>

param(
    [switch]$packaged,
    [string]$storageURL,
    [string]$sasToken,
    [string]$installedString,
    [string]$logFile
)

$argsString = ""
If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        foreach($k in $MyInvocation.BoundParameters.keys)
        {
            switch($MyInvocation.BoundParameters[$k].GetType().Name)
            {
                "SwitchParameter" {if($MyInvocation.BoundParameters[$k].IsPresent) { $argsString += "-$k " } }
                "String"          { $argsString += "-$k `"$($MyInvocation.BoundParameters[$k])`" " }
                "Int32"           { $argsString += "-$k $($MyInvocation.BoundParameters[$k]) " }
                "Boolean"         { $argsString += "-$k `$$($MyInvocation.BoundParameters[$k]) " }
            }
        }
        Start-Process -FilePath "$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -ArgumentList "-File `"$($PSScriptRoot)\$($MyInvocation.MyCommand)`" $($argsString)" -Wait -NoNewWindow
    }
    Catch {
        Throw "Failed to start 64-bit PowerShell"
    }
    Exit
}

# Let's define some functions
function Get-TimeStamp {
    return Get-Date -Format o | ForEach-Object { $_ -replace ":", ""}
}

function Add-Font {
    param(
      [string]$Path
    )

    #$objShell = New-Object -ComObject Shell.Application
    #$objFolder = $objShell.namespace($Path)

    try {

        # Copy standard fonts and register them.
        $fonts = Get-ChildItem -Path $Path -Recurse -File -Include @("*.fon", "*.fnt", "*.ttf","*.ttc", "*.otf", "*.mmm")
        ForEach($font in $fonts) {

            $fontName = $font.Name
            Write-Output "$(Get-TimeStamp) INFO: Processing $fontName."
            If(!(Test-Path -Path "$env:windir\Fonts\$($font.name)") -and !(Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts\$fontName")) {

                Copy-Item -Path $font.FullName -Destination "$env:windir\Fonts" -Force
                Write-Output "$(Get-TimeStamp) INFO: Copied $fontName successfully."
                New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name $fontName -PropertyType String -Value $font.Name -Force
                Write-Output "$(Get-TimeStamp) INFO: Registered $fontName successfully."

            } else {

                Write-Output "$(Get-TimeStamp) INFO: $fontName already exists. Moving on."

            }

        }

        # Copy Type1 fonts.
        $type1 = Get-ChildItem -Path $Path -Recurse -File -Include @("*.pfb", "*.pfm")
        ForEach($type1font in $type1) {

            $type1fontName = $type1font.Name.Replace("_","")
            Write-Output "$(Get-TimeStamp) INFO: Processing Type1 $($type1fontName)."
            If(!(Test-Path -Path "$env:windir\Fonts\$($type1fontName)")) {

                Copy-Item -Path $type1font.FullName -Destination "$env:windir\Fonts\$type1fontName" -Force
                Write-Output "$(Get-TimeStamp) INFO: Copied $($type1fontName) successfully. Registry changes will still need to be applied to complete font installation."

          } else {

                Write-Output "$(Get-TimeStamp) INFO: $($type1fontName) already exists. Moving on."

          }

        }

        # Import registry files for Type1 fonts.
        # Ideally we'll be able to craft the registry keys dynamically in the future and remove this requirement.
        $type1reg = Get-ChildItem -Path $Path -Recurse -File -Include @("*.reg")
        ForEach($reg in $type1reg) {

            Write-Output "$(Get-TimeStamp) INFO: Processing Type1 Registry Edits - $($reg.FullName)."
            $regOutputFile = "$env:Temp\FontReg-$(Get-TimeStamp)-$($reg.Name).log"
            Start-Process "reg.exe" -ArgumentList "import `"$($reg.FullName)`"" -Wait -NoNewWindow -RedirectStandardError $regOutputFile
            Write-Output "$(Get-TimeStamp) INFO: $(Get-Content -Path $regOutputFile)"
            Remove-Item -Path $regOutputFile

        }

    } catch {

      Write-Output "$(Get-TimeStamp) ERROR: Looks like there was an error processing fonts. Try again."
      $fontInstallError = $true
      Return $fontInstallError

    }

  }

  function Invoke-BlobItems {  
    param (
        [Parameter(Mandatory)]
        [string]$URL,
        [string]$Path
    )

    $uri = $URL.split('?')[0]
    $sas = $URL.split('?')[1]

    $newurl = $uri + "?restype=container&comp=list&" + $sas 

    #Invoke REST API
    $body = Invoke-RestMethod -uri $newurl

    #cleanup answer and convert body to XML
    $xml = [xml]$body.Substring($body.IndexOf('<'))

    #use only the relative Path from the returned objects
    $files = $xml.ChildNodes.Blobs.Blob.Name

    #create folder structure and download files
    $files | ForEach-Object { $_; New-Item (Join-Path $Path (Split-Path $_)) -ItemType Directory -ea SilentlyContinue | Out-Null
        (New-Object System.Net.WebClient).DownloadFile($uri + "/" + $_ + "?" + $sas, (Join-Path $Path $_))
     }
}

# Check to see if log file was set and if not, set to a default.
if( [string]::IsNullOrEmpty($logFile) -or !(Test-Path -Path $logFile -ErrorAction SilentlyContinue) ) {

    $logFile = "$env:TEMP\$(Get-TimeStamp)_install-font.log"
    Write-Output "$(Get-TimeStamp) INFO: No log file specified or log file path does not exist. Setting to default." | Out-File $logFile -Append

}

# Verify installedString doesn't already exist, exit if it exists.
if( (Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\WOW6432Node\fontDeploy" -Name "installString" -ErrorAction SilentlyContinue) -eq $installedString) {

    Write-Output "$(Get-TimeStamp) INFO: Fonts already installed, exiting." | Out-File $logFile -Append
    Remove-Item -Path $PSCommandPath -Force
    Exit 0

}

# Check to see if we're pulling from blob storage.
if( [string]::IsNullOrEmpty($packaged) ) {

    if( [string]::IsNullOrEmpty($storageURL) -or [string]::IsNullOrEmpty($sasToken) ) {

            Write-Output "$(Get-TimeStamp) ERROR: No location specified for pulling down fonts. Please specifiy location for fonts or include in package." | Out-File $logFile -Append
            Exit 1308

    }

    try {

        # Create directory to drop files
        $installRoot = "$env:TEMP\$(Get-TimeStamp)_install-font"
        New-Item -Type Directory -Path $installRoot -Force
        if( !(Test-Path -Path $installRoot) ) {

            Write-Output "$(Get-TimeStamp) ERROR: Temporary directory failed to create. Try again." | Out-File $logFile -Append
            Exit 1618

        }

        Invoke-BlobItems -URL "$storageURL$sas" -Path $installRoot | Out-Null

    } catch {

        Write-Output "$(Get-TimeStamp) ERROR: Download failed or was interrupted. Try again." | Out-File $logFile -Append
        Exit 1618

    }

}

# Set directory if packaged flag is specified
if($packaged) {

    $installRoot = "$PSScriptRoot\Fonts"

}

# Begin font install
try{
    
    Add-Font -Path $installRoot | Out-File $logFile -Append 

} catch {

    Write-Output "$(Get-TimeStamp) ERROR: Fonts failed to install. Try again." | Out-File $logFile -Append
    Exit 1618
    
}

# Set installString registry values.
if(($installedString) -and !($fontInstallError)) {

    New-Item -Path "HKLM:\SOFTWARE\WOW6432Node" -Name "fontDeploy" -Force | New-ItemProperty -Name "installString" -Value $installedString -Force

}

# Verify install string got applied and clean up.
if( (Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\WOW6432Node\fontDeploy" -Name "installString") -eq $installedString) {

    Write-Output "$(Get-TimeStamp) INFO: Install string successfully applied. Cleaning up install." | Out-File $logFile -Append
    Remove-Item -Recurse -Path $installRoot -Force
    Remove-Item -Path $PSCommandPath -Force
    Exit 0

}

# If we ended up here, the registry key didn't get updated or something else failed.
Write-Output "$(Get-TimeStamp) ERROR: Reached end of install but installation may have failed. Try again." | Out-File $logFile -Append
Exit 1618

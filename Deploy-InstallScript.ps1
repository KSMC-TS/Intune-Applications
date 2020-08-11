param(
[Parameter(Mandatory=$true)]
[ValidateSet('Install','Uninstall')]
[String[]]
$Mode,
[Parameter(Mandatory=$true)]
$scripturl,
[string]
$scriptargs
)

## Install block ##
if($Mode -eq "Install") {
    $path = $env:TEMP
    $script = "deployscript.ps1"
    Invoke-WebRequest $scripturl -OutFile $path\$script
    $command = "powershell.exe -command '& $path\$script -mode install $scriptargs'"
    $exitcode = Invoke-Command -scriptblock ([scriptblock]::Create($command))
    Remove-Item $path\$script
    if ($exitcode -eq 0) {
        Exit 0
    } else {
        Exit 1618
    }
    
}

## Uninstall block ##
if($Mode -eq "Uninstall") {
    $path = $env:TEMP
    $script = "deployscript.ps1"
    Invoke-WebRequest $scripturl -OutFile $path\$script
    $command = "powershell.exe -command '& $path\$script -mode uninstall $scriptargs'"
    $exitcode = Invoke-Command -scriptblock ([scriptblock]::Create($command))
    Remove-Item $path\$script
    if ($exitcode -eq 0) {
        Exit 0
    } else {
        Exit 1618
    }
}

Exit 1618

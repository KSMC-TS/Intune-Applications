param (
    $basedir = "C:\Users\fgottman\KSM Consulting\Praxis Consulting - MDM InTune",
    $exe = "C:\github\derfnamttog\Intune-Applications\IntunePrep\IntuneWinAppUtil.exe"
)

$intunedir = "$basedir\intune"
$installersdir = "$intunedir\installers"
$scriptsdir = "$intunedir\scripts"
$win32app = "$intunedir\w32apps"
$wd = "$intunedir\wd"
$outdir = "$intunedir\intunewins"

#create dirs
$dirs = @("$intunedir","$installersdir","$scriptsdir","$win32app","$wd","$outdir")
foreach ($dir in $dirs) {
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force }
}

#create intunewins
$files = Get-ChildItem $win32app -File


foreach ($file in $files) {
    Copy-Item -Path $file -Destination $wd
    $wdfile = Get-ChildItem $wd -File
    Start-Process $exe -ArgumentList "-c `"$wd`" -s `"$wdfile`" -o `"$outdir`" -q" -Wait
    Remove-Item $wdfile -Force
}



## fix for printer intunewin scripts
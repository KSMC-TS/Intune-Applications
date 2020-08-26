Import-Module Az
Connect-AzAccount
$localpath = "C:\"
$location = "northcentralus"
$rg = "cpwmintune"
$storageName = "cpwmintune"
$sku = "Standard_LRS"
#creeate resource group
New-AzResourceGroup -Name $rg -Location $location

#create storage account
$storageAccount = New-AzStorageAccount -ResourceGroupName $rg -Name $storageName -SkuName $sku -Location $location
$ctx = $storageAccount.Context

#create containers
$containerNames = @("installers","scripts","intunewins")
foreach ($containername in $containernames) {
    New-AzStorageContainer -Name $containerName -Context $ctx -Permission Blob
    if ($containername -eq "installers") {
        $localfolder = "$localpath\installers"
        $localfiles = Get-ChildItem -Path $localfolder -File -Recurse
        $localfiles | Set-AzStorageBlobContent -Container $containerName
    }
    if ($containername -eq "scripts") {
        $localfolder = "$localpath\scripts"
        $localfiles = Get-ChildItem -Path $localfolder -File -Recurse
        $localfiles | Set-AzStorageBlobContent -Container $containerName
    }
    if ($containername -eq "intunewins") {
        $localfolder = "$localpath\intunewins"
        $localfiles = Get-ChildItem -Path $localfolder -File -Recurse
        $localfiles | Set-AzStorageBlobContent -Container $containerName
    }
}






<# overwrite blob
Get-AzureStorageBlob -Container $containerName  -Blob $blobname | Set-AzureStorageBlobContent -File $blobfile
#>



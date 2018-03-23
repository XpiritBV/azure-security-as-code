#Import Helpers
. .\SecurityAsCode-Helpers.ps1

function Get-Asac-Keyvault {
    param
    (
        [string] $name,
        [string] $outputPath
    )
    $keyvaultname = $name
    $outputPath = _Get-Asac-OutputPath -outputPath $outputPath

    $keyvault = Invoke-Asac-AzCommandLine -azCommandLine "az keyvault show -n $($keyvaultname) --output json"

    # $properties = [ordered]@{
    #     enableSoftDelete = $keyvault.properties.enableSoftDelete
    #     enabledForDeployment = $keyvault.properties.enabledForDeployment
    #     enabledForDiskEncryption = $keyvault.properties.enabledForDiskEncryption
    #     enabledForTemplateDeployment = $keyvault.properties.enabledForTemplateDeployment
    # }

    $accessPolicies = @()
    foreach($accessPolicy in $keyvault.properties.accessPolicies){

        $certificatePermissions = @()
        foreach($certificatePermission in $accessPolicy.permissions.certificates){
            $certificatePermissions += $certificatePermission
        }

        $keyPermissions = @()
        foreach($keyPermission in $accessPolicy.permissions.keys){
            $keyPermissions += $keyPermission
        }

        $secretPermissions = @()
        foreach($secretPermission in $accessPolicy.permissions.secrets){
            $secretPermissions += $secretPermission
        }

        $policy = [ordered]@{
            applicationId = $accessPolicy.applicationId
            objectId = $accessPolicy.objectId
            permissions = [ordered]@{
                certificates = $certificatePermissions
                keys = $keyPermissions
                secrets = $secretPermissions
            }
        }
        $accessPolicies += $policy
    }
    
    $kvDict = [ordered]@{  keyvaultname = $keyvaultname
                            # properties = $properties
                            accessPolicies = $accessPolicies
    }
    
    $path = Join-Path $outputPath -ChildPath "kv"
    New-Item $path -Force -ItemType Directory
    $filePath = Join-Path $path -ChildPath "kv.$($keyvaultname).yml"
    ConvertTo-YAML $kvDict > $filePath
}


function Get-Asac-AllKeyvaults { 
    param
    (
        [string] $outputPath
    )

    if ($outputPath -eq "" -or $outputPath -eq $null) {
        $outputPath = $PSScriptRoot
    }

    $keyvaults = Invoke-Asac-AzCommandLine -azCommandLine "az keyvault list --output json"


    foreach ($keyvault in $keyvaults) {
        Get-Asac-Keyvault -name $keyvault.name -outputPath $outputPath
    }
}
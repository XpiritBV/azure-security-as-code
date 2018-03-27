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
 
    $accessPoliciesArray = @()
    foreach($accessPolicy in $keyvault.properties.accessPolicies){
        $accessPolicy.PSObject.Properties.Remove('tenantId')
        $accessPolicy.PSObject.Properties.Remove('applicationId')
        $accessPolicy.permissions.PSObject.Properties.Remove('storage')
        $accessPoliciesArray += $accessPolicy
    }
    
    $kvDict = [ordered]@{}
    $kvDict.Add('keyvaultname',$keyvaultname)
    $kvDict.Add('accessPolicies',$accessPoliciesArray)
 
    $path = Join-Path $outputPath -ChildPath "kv"
    New-Item $path -Force -ItemType Directory | Out-Null
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

function Process-Asac-Keyvault {
    param
    (
        [string] $name,
        [string] $path
    )

    $path = _Get-Asac-OutputPath -outputPath $path

    $path = Join-Path $path -ChildPath "kv"
    $file = Join-Path $path -ChildPath "kv.$($name).yml"
    $yamlContent = Get-Content -Path $file -Raw
    $kvConfigured = ConvertFrom-Yaml $yamlContent

    $keyvault = Invoke-Asac-AzCommandLine -azCommandLine "az keyvault show -n $($name) --output json"

    foreach($accessPolicy in $kvConfigured.accessPolicies){
        $existingPolicy = $keyvault.properties.accessPolicies | Where-Object {($_.objectId -eq $accessPolicy.objectId)}

        if($existingPolicy -ne $null){

            $keys= Compare-Object -ReferenceObject $accessPolicy.permissions.keys -DifferenceObject $existingPolicy.permissions.keys -PassThru
            $certificates= Compare-Object -ReferenceObject $accessPolicy.permissions.certificates -DifferenceObject $existingPolicy.permissions.certificates -PassThru
            $secrets = Compare-Object -ReferenceObject $accessPolicy.permissions.secrets -DifferenceObject $existingPolicy.permissions.secrets -PassThru
            if(($keys -eq $null) -and
                ($certificates -eq $null) -and
                ($secrets -eq $null)){
                #all the same do nothing
                Write-Host "Access Policy: [$($accessPolicy.objectId)] found and is exactly the same" -ForegroundColor Green
            }
            else{
                #access policy is not the same. update it
                Write-Host "Access Policy permissions: [$($accessPolicy.objectId)] found but different" -ForegroundColor Yellow
                $azCommand = "az keyvault set-policy -n $name --object-id $($accessPolicy.objectId) "
                $azCommand += "--certificate-permissions $($accessPolicy.permissions.certificates) "
                $azCommand += "--key-permissions $($accessPolicy.permissions.keys) "
                $azCommand += "--secret-permissions $($accessPolicy.permissions.secrets)"

                $result = Invoke-Asac-AzCommandLine -azCommandLine $azCommand
            }                
        }
        else{
            #Add policy because it does not exist
            Write-Host "Access Policy: [$($accessPolicy.objectId)] not found" -ForegroundColor Yellow
            $azCommand = "az keyvault set-policy -n $name --object-id $($accessPolicy.objectId) "
            $azCommand += "--certificate-permissions $($accessPolicy.permissions.certificates) "
            $azCommand += "--key-permissions $($accessPolicy.permissions.keys) "
            $azCommand += "--secret-permissions $($accessPolicy.permissions.secrets)"

            $result = Invoke-Asac-AzCommandLine -azCommandLine $azCommand
        }
    }

    #delete all object id's not in the kv yaml file
    foreach($accessPolicy in $keyvault.properties.accessPolicies){
        $yamlPolicy = $kvConfigured.accessPolicies | Where-Object {($_.objectId -eq $accessPolicy.objectId)}
        if($yamlPolicy -eq $null){
            Write-Host "Access Policy: [$($accessPolicy.objectId)] not found in yaml. Delete it" -ForegroundColor Yellow
            $result = Invoke-Asac-AzCommandLine -azCommandLine "az keyvault delete-policy -n $name --object-id $($accessPolicy.objectId) "
        }
    }
}


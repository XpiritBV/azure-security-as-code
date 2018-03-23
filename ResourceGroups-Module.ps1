#Import Helpers
. .\SecurityAsCode-Helpers.ps1

function Get-Asac-ResourceGroup
{
    param
    (
        [string] $resourcegroup,
        [string] $outputPath
    )

    $outputPath = _Get-Asac-OutputPath -outputPath $outputPath


    $rg = Invoke-Asac-AzCommandLine -azCommandLine "az group show --name $($resourcegroup) --output json"

    $roleassignment = "$(az role assignment list -g "$($resourcegroup)")" 
    $roleassignment = ConvertFrom-Json $roleassignment
    $roleassignment | Sort-Object -Property $_.properties.roleDefinitionName

    $rbacArray = @()
    foreach($role in $roleassignment)
    {
        $rbacDict = [ordered]@{userPrincipal = $role.properties.principalName
                               principalId = $role.properties.principalId
                               role = $role.properties.roleDefinitionName}
        $rbacArray += $rbacDict

    }
    
    $rgDict = [ordered]@{}
    $rgDict.Add('resourcegroup',$rg.name)
    $rgDict.Add('rbac',$rbacArray)

    $path = Join-Path $outputPath -ChildPath "rg"
    New-Item $path -Force -ItemType Directory
    $filePath = Join-Path $path -ChildPath "$($resourcegroup).yml"
    Write-Host $filePath
    ConvertTo-YAML $rgDict > $filePath
}


function Get-Asac-AllResourceGroups
{ 
    param
    (
        [string] $outputPath
    )
    $outputPath = _Get-Asac-OutputPath -outputPath $outputPath


    $rgs = Invoke-Asac-AzCommandLine -azCommandLine "az group list --output json"


    foreach ($rg in $rgs) {
        Get-Asac-ResourceGroup -resourcegroup $rg.name -outputPath $outputPath
    }
}

function Process-Asac-ResourceGroup
{
    param
    (
        [string] $resourcegroup,
        [string] $basePath
        
    )

    $basePath = _Get-Asac-OutputPath -outputPath $basePath

    $path = Join-Path $basePath -ChildPath "rg"
    $file = Join-Path $path -ChildPath "$($resourcegroup).yml"
    $yamlContent = Get-Content -Path $file -Raw
    $rgConfigured = ConvertFrom-Yaml $yamlContent

    #First get all the UPN that are currently assigned to the resource group
    $rgRoles = Invoke-Asac-AzCommandLine -azCommandLine "az role assignment list --resource-group $($resourcegroup) --output json"

    foreach($upn in $rgConfigured.rbac){
        
        #try and find the upn in the current resource group 
        #if this is found, check if the role is still the same
        #add / remove or update UPN
        
        #check if there is an object id in the file.. If not. Get the Object ID first
        $principalID = ""

        if ($upn.principalId -ne $null -and $upn.principalId -ne "")
        {       
            $principalID = $upn.principalId
        }
        else 
        {
            $user = Invoke-Asac-AzCommandLine -azCommandLine "az ad user show --upn-or-object-id $($upn.principalName) --output json"
            $principalID = $user.objectid
        }

        $foundUser = $rgRoles | Where-Object {$_.properties.principalId -eq $principalID -and $_.properties.roleDefinitionName -eq $($upn.role)}
        
        if ($foundUser -eq $null)
        {
            #member found with name and same role
            #nothing to do
            Write-Host "[$($upn.userPrincipal)] not found in role [$($upn.role)]. Add user" -ForegroundColor Yellow
            Invoke-Asac-AzCommandLine -azCommandLine "az role assignment create --role $($upn.role) --assignee $($principalID) --resource-group $($resourcegroup)"
        }
        else 
        {
            #member found with name and same role
            #nothing to do
            Write-Host "Found [$($upn.userPrincipal)] in role [$($upn.role)] as configured. No action" -ForegroundColor Green
            Add-Member -InputObject $foundUser -type NoteProperty -Name 'Processed' -Value $true
        }
    }

            #No Delete all users that have not been processed by file

            $nonProcessed = $rgRoles | Where-Object {$_.Processed -eq $null -or $_.Processed -eq $false}
            foreach ($as in $nonProcessed)
            {
                Write-Host "Deleting [$($as.properties.principalName)] from role [$($as.properties.roleDefinitionName)]. Not configured in file" -ForegroundColor DarkMagenta
                Invoke-Asac-AzCommandLine -azCommandLine "az role assignment delete --role $($as.properties.roleDefinitionName) --assignee $($as.properties.principalId) --resource-group $($resourcegroup)"
            }
    }


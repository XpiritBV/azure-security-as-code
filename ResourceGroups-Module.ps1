function Download-ResourceGroupYaml
{
    param
    (
        [string] $resourcegroup,
        [string] $outputPath
    )

    if ($outputPath -eq "" -or $outputPath -eq $null)  
    {
        $outputPath = $PSScriptRoot
    }

    $rg = "$(az group show --name $($resourcegroup) --output json)"
    $rg = ConvertFrom-Json $rg

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


function Download-AllResourceGroups
{ 
    param
    (
        [string] $outputPath
    )

    if ($outputPath -eq "" -or $outputPath -eq $null)  
    {
        $outputPath = $PSScriptRoot
    }

    $rgs = "$(az group list --output json)"
    $rgs = ConvertFrom-Json $rgs


    foreach ($rg in $rgs) {
        Download-ResourceGroupYaml -resourcegroup $rg.name -outputPath $outputPath
    }
}

function Process-ResourceGroup
{
    param
    (
        [string] $resourcegroup,
        [string] $basePath
        
    )

    if ($basePath -eq "" -or $basePath -eq $null)  
    {
        $basePath = $PSScriptRoot
    }

    $path = Join-Path $basePath -ChildPath "rg"
    $file = Join-Path $path -ChildPath "$($resourcegroup).yml"
    $yamlContent = Get-Content -Path $file -Raw
    $rgConfigured = ConvertFrom-Yaml $yamlContent

    #First get all the UPN that are currently assigned to the resource group
    $rgRolesJson = "$(az role assignment list --resource-group $($resourcegroup) --output json)"
    $rgRoles = ConvertFrom-Json $rgRolesJson


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
            $userJson = "$(az ad user show --upn-or-object-id $($upn.principalName) --output json)"
            $user = ConvertFrom-Json $userJson
            $principalID = $user.objectid
        }

        $foundUser = $rgRoles | Where-Object {$_.properties.principalId -eq $principalID -and $_.properties.roleDefinitionName -eq $($upn.role)}
        
        if ($foundUser -eq $null)
        {
            #member found with name and same role
            #nothing to do
            Write-Host "[$($upn.userPrincipal)] not found in role [$($upn.role)]. Add user" -ForegroundColor Yellow
            $result  = "$(az role assignment create --role $($upn.role) --assignee $($principalID) --resource-group $($resourcegroup))"
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
                $result  = "$(az role assignment delete --role $($as.properties.roleDefinitionName) --assignee $($as.properties.principalId) --resource-group $($resourcegroup))"
            }
    

}

Process-ResourceGroup rgpgeert .\rvoazure
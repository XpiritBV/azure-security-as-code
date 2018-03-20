function Download-ResourceGroupYaml
{
    param
    (
        [string] $resourcegroup
    )

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

    $path = Join-Path $PSScriptRoot -ChildPath "rg"
    New-Item $path -Force -ItemType Directory
    $filePath = Join-Path $path -ChildPath "$($resourcegroup).yml"
    Write-Host $filePath
    ConvertTo-YAML $rgDict -OutFile $filePath -Force
}

function Download-AllResourceGroups
{
    $rgs = "$(az group list --output json)"
    $rgs = ConvertFrom-Json $rgs


    foreach ($rg in $rgs) {
        Download-ResourceGroupYaml -resourcegroup $rg.name
    }
}

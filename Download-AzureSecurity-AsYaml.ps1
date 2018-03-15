$rgs = "$(az group list --output json)"
$rgs = ConvertFrom-Json $rgs

$rolesjson = "$(az role definition list --output json)" 
$roles = ConvertFrom-Json $rolesjson

$rgArray = @()

foreach ($rg in $rgs) {
    $rgRoles = ConvertFrom-Json "$(az role assignment list --resource-group $rg.name --output json)"

    $userArray = @()

    foreach($role in $rgroles)
    {
        $userDict = [ordered]@{userPrincipal = $role.properties.principalName
                               role = $role.properties.roleDefinitionName
                               principalId = $role.properties.principalId}
        $userArray += $userDict
    }
    
    $rgDict = [ordered]@{}
    $rgDict.Add('resourcegroup',$rg.name)
    if($userArray -ne $null)
    {
        $rgDict.Add('rbacsecurity',$userArray)
    }


    $rgArray += $rgDict
}

$subscriptionDict = [ordered]@{}
$subscriptionDict.Add('resourcegroups',$rgArray)

ConvertTo-YAML $subscriptionDict

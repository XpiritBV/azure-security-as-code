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
        $userDict = @{}
        $userDict.Add('user',$role.properties.principalName)
        $userDict.Add('role',$role.properties.roleDefinitionName)
        $userArray += $userDict
        # Write-Host $role.Name $role.role
    }
    
    $rgDict = @{}
    $rgDict.Add('resourcegroup',$rg.name)
    if($userArray -ne $null)
    {
        $rgDict.Add('rbacsecurity',$userArray)
    }

    $rgArray += $rgDict
}

$subscriptionDict = @{}
$subscriptionDict.Add('resourcegroups',$rgArray)

ConvertTo-YAML $subscriptionDict

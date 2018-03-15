#read YAML file and set all properties IsChecked to false
$securityFile = [IO.File]::ReadAllText("/app/rbacsecurity.yml")
$secYaml = ConvertFrom-YAML $securityFile

foreach($rg in $secYaml.resourcegroups){
    Add-Member -InputObject $rg -type NoteProperty -Name 'IsChecked' -Value $False

    foreach($user in $rg.rbacsecurity){
        Add-Member -InputObject $user -type NoteProperty -Name 'IsChecked' -Value $False
    }
}

$rgs = "$(az group list --output json)"
$rgs = ConvertFrom-Json $rgs

Write-Host "CHECKING ALL RESOURCE GROUPS"
foreach ($rg in $rgs) {
    Write-Host "checking $($rg.name)"

    if($secYaml.resourcegroups.Where({$_.resourcegroup -eq $rg.name})){
        Write-Host "matched - resource group: $($rg.name)" -ForegroundColor Green
        $foundRg = $secYaml.resourcegroups | Where({$_.resourcegroup -eq $rg.name})
        $foundRg.IsChecked = $True

        $rgRoles = ConvertFrom-Json "$(az role assignment list --resource-group $rg.name --output json)"
        foreach($role in $rgRoles){
            if($foundRg.rbacsecurity.Where({($_.userPrincipal -eq $role.properties.principalName) -and ($_.role -eq $role.properties.roleDefinitionName)})){
                Write-Host "matched - user: $($role.properties.principalName)" -ForegroundColor Green
                $user = $foundRg.rbacsecurity | Where({($_.userPrincipal -eq $role.properties.principalName) -and ($_.role -eq $role.properties.roleDefinitionName)})
                $user.IsChecked = $True
            }
            else{
                Write-Host "not found - user: $($role.properties.principalName)" -ForegroundColor Red
                # User not found. delete it in Azure
                az role assignment delete --ids $role
            }
        }
    }
    else {
        Write-Host "not found - resource group: $($rg.name)" -ForegroundColor Red
        #TODO delete all roles in this RG because it is not listed
    }
}


#check yaml file again and see which aren't IsChecked
foreach($rg in $secYaml.resourcegroups){
    if($rg.IsChecked){
        Write-Host "rg $($rg.resourcegroup) is correct!" -ForegroundColor green
        foreach($user in $rg.rbacsecurity){        
            if($user.IsChecked){
                #user in yaml file did exist in subscription
                Write-Host "user $($user.userPrincipal) is correct!" -ForegroundColor green
            }
            else{
                #user in yaml file did not exist in subscription. Add it.
                $user.userPrincipal
                $user.role
                az role assignment create --role $user.role --assignee $user.principalId --resource-group $rg.resourcegroup
                Write-Host "user $($user.userPrincipal) should be added!" -ForegroundColor red
            }
        }
    }
    else{
        #resource group does not exist anymore??
        Write-Host "rg $($rg.resourcegroup) does not exist!" -ForegroundColor Red
    }
}


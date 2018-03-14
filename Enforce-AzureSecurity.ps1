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
    $rgRoles = ConvertFrom-Json "$(az role assignment list --resource-group $rg.name --output json)"
    Write-Host "checking $($rg.name)"

    if($secYaml.resourcegroups.Where({$_.resourcegroup -eq $rg.name})){
        Write-Host "matched - $($rg.name)" -ForegroundColor Green
        $foundRg = $secYaml.resourcegroups | Where({$_.resourcegroup -eq $rg.name})
        $foundRg.IsChecked = $True;

        #TODO run through all roles in $rgRoles and check them
    }
    else {
        Write-Host "not found - $($rg.name)" -ForegroundColor Red

        #TODO delete all roles in this RG because it is not listed
    }
}


#check yaml file again and see which aren't IsChecked
foreach($rg in $secYaml.resourcegroups){
    Write-Host "rg $($rg.resourcegroup) -  $($rg.IsChecked)"
}


$rgs = "$(az group list --output json)"
$rgs = ConvertFrom-Json $rgs

#read YAML file and set all properties checked to false
$securityFile = [IO.File]::ReadAllText("/app/rbacsecurity.yml")
$secYaml = ConvertFrom-YAML $securityFile

foreach($rg in $secYaml.resourcegroups){
    Add-Member -InputObject $rg -type NoteProperty -Name 'Checked' -Value $False
    Write-Host "rg $($rg.name)"

    foreach($user in $rg.rbacsecurity){
        Add-Member -InputObject $user -type NoteProperty -Name 'Checked' -Value $False
        Write-Host "user $($user)"
        Write-Host "user $($user.Checked)"
    }
}

foreach ($rg in $rgs) {
    $rgRoles = ConvertFrom-Json "$(az role assignment list --resource-group $rg.name --output json)"
    Write-Host "CHECKING $($rg.name) - $($rgRoles.properties.principalName)"

    if($secYaml.resourcegroups.Where({$_.name -eq $rg.name})){
        Write-Host "MATCHED $($rg.name)" -ForegroundColor Green
        $foundRg = $secYaml.resourcegroups | Where({$_.name -eq $rg.name})
        $foundRg.Checked = $True;
    }
    else {
        Write-Host "NOT FOUND $($rg.name)" -ForegroundColor Red
    }
}


#check yaml file again and see which aren't checked
foreach($rg in $secYaml.resourcegroups){
    Write-Host "rg $($rg.name) -  $($rg.Checked)"
}


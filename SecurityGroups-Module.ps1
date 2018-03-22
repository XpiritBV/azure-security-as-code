function Download-SecurityGroupYaml
{
    param
    (
        [string] $securityGroup,
        [string] $outputPath
        
    )

    if ($outputPath -eq "" -or $outputPath -eq $null)  
    {
        $outputPath = $PSScriptRoot
    }
    
    $users = "$(az ad group member list --group "$($securityGroup)")"
    $users = ConvertFrom-Json $users

    
    $userArray = @()

    foreach($u in $users)
    {
        $userDict = [ordered]@{userPrincipalName = $u.userPrincipalName
                                objectId = $u.objectId
                                displayName = $u.displayName}
        $userArray += $userDict
    }
    
    $rgDict = [ordered]@{}
    $rgDict.Add('SecurityGroup',$securityGroup)
    if($userArray -ne $null)
    {
        $rgDict.Add('members',$userArray)
    }


    $path = Join-Path $outputPath -ChildPath "ad-groups"
    New-Item -ItemType Directory -Path $path -Force
    $file = Join-Path $path -ChildPath "$($securityGroup).yml"
    ConvertTo-YAML $rgDict > $file
}


function Update-SecurityGroup
{
    param
    (
        [string] $securityGroup,
        [string] $basePath
    )

    if ($basePath -eq "" -or $basePath -eq $null)  
    {
        $basePath = $PSScriptRoot
    }
    
    $path = Join-Path $basePath -ChildPath "ad-groups"
    $file = Join-Path $path -ChildPath "$($securityGroup).yml"
    $yamlContent = Get-Content -Path $file -Raw
    $secgroupmembers = ConvertFrom-Yaml $yamlContent

    $secGroup = "$(az ad group show --group "$($securityGroup)")"
    $secGroup = ConvertFrom-Json $secGroup

    foreach($m in $secgroupmembers["members"])
    {
        if($m.objectId -ne $null) {
            $user = "$(az ad user show --upn-or-object-id $m.objectId)"

        }
        else {
            $user = "$(az ad user show --upn-or-object-id $m.userPrincipalName)"

        }
        $user = ConvertFrom-Json $user
        $result = "$(az ad group member check --group "$($secGroup.ObjectID)" --member-id "$($user.ObjectID)")"
        $result = ConvertFrom-Json $result
        
        if ($($result.value) -eq $false) {
            Write-Host "Adding $($user.displayName) ($($m.userPrincipalName)) to Security Group $($securityGroup)"
            $added = "$(az ad group member add --group "$($secGroup.ObjectID)" --member-id "$($user.ObjectID)")"
        }
        else {
            Write-Host "User $($user.displayName) ($($m.userPrincipalName)) already exists in Security Group $($securityGroup)"
            
        }
    }
}

function Download-AllSecurityGroups
{
    param
    (
        [string] $outputPath
    )
    

    if ($outputPath -eq "" -or $outputPath -eq $null)  
    {
        $outputPath = $PSScriptRoot
    }

    $secGroups = "$(az ad group list --output json)"
    $secGroups = ConvertFrom-Json $secGroups


    foreach ($sg in $secGroups) {
        Download-SecurityGroupYaml -securityGroup $sg.displayName -outputPath $outputPath
    }
}

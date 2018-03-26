#Import Helpers
. .\SecurityAsCode-Helpers.ps1

function _GetSQLServerDictionary {
    param
    (
        [string] $sqlservername,
        [string] $sqladminlogin
    )

    $sqlDict = [ordered]@{  sqlservername = $sqlservername
        sqladminlogin = $sqladminlogin
    }

    return $sqlDict
}

function _GetSQLServerPasswordDictionary {
    param
    (
        [string] $secretkey,
        [string] $keyvaultname,
        [string] $keyvaultresourcegroup
    )

    $sqlpasswordDict = [ordered]@{ secretkey = $secretkey
        keyvaultname = $keyvaultname
        keyvaultresourcegroup = $keyvaultresourcegroup
    }


    return $sqlpasswordDict
}

function _GetSQLServerFirewallDict {
    param
    (
        [string] $rulename,
        [string] $startip,
        [string] $endip
    )
    $firewallDict = [ordered]@{rulename = $rulename
        startip = $startip
        endip = $endip
    }

    return $firewallDict
}
function _GetSQLServerADAdminDict {
    param
    (
        [string] $userPrincipal,
        [string] $principalId
    )

    $adadminDict = [ordered]@{userPrincipal = $userPrincipal
        principalId = $principalId
    }

    return $adadminDict
}

function _GetSQLDBDictionary {
    param
    (
        [string] $databaseName
    )

    $sqlDict = [ordered]@{  databaseName = $databaseName
        
    }

    return $sqlDict
}

function _GetSQLDBUsersAndRolesDict {
    param
    (
        [string] $sqlusername,
        [string] $rolename
    )

    $sqluserDict = [ordered]@{sqluser = $sqlusername
        rolename = $rolename
    }

    return $sqluserDict
}


function _QuerySQLUsersRoles {
    param
    (
        [string] $servername,
        [string] $dbname,
        [string] $username,
        [string] $password,
        [bool] $isIntegrated
    )
    $sqlgetusers = @'
select su.name as username, roletab.name as rolename from sys.database_role_members rm inner join sys.sysusers su ON su.uid= rm.member_principal_id
inner join sys.sysusers roletab ON roletab.uid = rm.role_principal_id
WHERE su.islogin=1 
AND su.name <> 'dbo' 
AND su.name <> 'guest'
AND su.sid  is not null
'@

    $ds = _Execute-Query -sql $sqlgetusers -servername $servername -dbname $dbname -username $username -password $password -isIntegrated $false

    $userArray = @()    

    foreach ($Row in $ds.Tables[0].Rows) { 
    
        _GetSQLDBUsersAndRolesDict -sqlusername $($Row.username) -rolename $($Row.rolename)
        $userArray += $userArray
    }

}

function _Get-Asac-AllSQLDatabasesArray {
    param
    (
        [string] $sqlservername,
        [string] $username,
        [string] $password,
        [string] $resourcegroupname
    )

    _Open_SQLFirewall -resourceGroupName $resourcegroupname -servername $sqlservername | Out-Null
    $databases = Invoke-Asac-AzCommandLine -azCommandLine "az sql db list --server $($sqlservername) --resource-group $($resourcegroupname) --output json"
    $dbArray = @()
    foreach ($db in $databases) {
        if ($db.name -eq "master") {
            continue
        }
        $dbDict = _GetSQLDBDictionary -databaseName $db.name

        #Now get all the users in the database...
        
        $usersAndRoles = _QuerySQLUsersRoles -servername $sqlservername -dbname $db.name -username $username -password $password -isIntegrated $false 
        $dbDict.Add('users', $usersAndRoles)
        $dbArray += $dbDict
    }
    _Close_SQLFirewall -resourceGroupName $resourcegroupname -servername $sqlservername | Out-Null

    return $dbArray
}

function _Open_SQLFirewall {
    param
    (
        [string] $resourceGroupName,
        [string] $servername
    )
    #documentation
    #https://docs.microsoft.com/en-us/azure/sql-database/sql-database-firewall-configure
    #https://gallery.technet.microsoft.com/scriptcenter/Get-ExternalPublic-IP-c1b601bb
    $rulename = "PSrunner"
    $ip = Invoke-RestMethod http://ipinfo.io/json | Select -exp ip
    $fw = Get-AzureRmSqlServerFirewallRule -FirewallRuleName  $ruleName -ResourceGroupName $resourceGroupName -ServerName $servername -ErrorAction SilentlyContinue
    if ($fw) {
        Set-AzureRmSqlServerFirewallRule -ResourceGroupName "$resourceGroupName" -ServerName $servername -FirewallRuleName $ruleName -StartIpAddress $ip -EndIpAddress $ip
    }
    else {
        New-AzureRmSqlServerFirewallRule -ResourceGroupName "$resourceGroupName" -ServerName $servername -FirewallRuleName $ruleName -StartIpAddress $ip -EndIpAddress $ip
    }
}

function _Open_SQLFirewall {
    param
    (
        [string] $resourceGroupName,
        [string] $servername
    )
    $rulename = "PSrunner"
    $ip = Invoke-RestMethod http://ipinfo.io/json | Select -exp ip
    $azcmd = "az sql server firewall-rule create -g $resourceGroupName --server $servername --name $rulename --start-ip-address $ip --end-ip-address $ip"
    Invoke-Asac-AzCommandLine -azCommandLine $azcmd
}

function _Close_SQLFirewall {
    param
    (
        [string] $resourceGroupName,
        [string] $servername
    )
    $rulename = "PSrunner"
    $ip = Invoke-RestMethod http://ipinfo.io/json | Select -exp ip
    $azcmd = "az sql server firewall-rule delete -g $resourceGroupName --server $servername --name $rulename"
    Invoke-Asac-AzCommandLine -azCommandLine $azcmd
}
function New-Asac-SQLServer {
    param
    (
        [string] $sqlservername,
        [string] $outputPath
    )

    $outputPath = _Get-Asac-OutputPath -outputPath $outputPath

    $sqlDict = _GetSQLServerDictionary -sqlservername  "sqlserv123 #SQL Server Name" -sqladminlogin "[generated] #username of SA when creating SQL Server"
    #$sqlpasswordDict = _GetSQLServerPasswordDictionary -secretkey "sql-bigboss #Keyname in keyvault" -keyvaultname"kvPlatform123 #Name of the keyvault where password resides" -keyvaultresourcegroup "rgTest123 #Name of the resource group where the keyvault resides"

    $adadminArray = @()
    for ($i = 0; $i -lt 2; $i++) {

        $adadminDict = _GetSQLServerADAdminDict -userPrincipal "John@domain.com #User or GroupName" -principalId "7a2eddfe-341e-4c3b-8917-58a678249a81 #Object ID of User or GroupName. If empty name will be used"
        $adadminArray += $adadminDict
    }

    $firewallArray = @()
    for ($i = 0; $i -lt 2; $i++) {

        $firewallDict = _GetSQLServerFirewallDict -rulename "Name of Rule" -startip "10.1.1.1" -endip "10.1.1.2"
        $firewallArray += $firewallDict
    }

    #$sqlDict.Add('sqladminpassword', $sqlpasswordDict)
    $sqlDict.Add('adadmins', $adadminArray)
    $sqlDict.Add('firewallports', $firewallArray)
    
    $path = Join-Path $outputPath -ChildPath "sql"
    New-Item $path -Force -ItemType Directory
    $filePath = Join-Path $path -ChildPath "sql.$($sqlservername).yml"
    Write-Host $filePath
    ConvertTo-YAML $sqlDict > $filePath                               
}

function Get-Asac-SQLServer {
    param
    (
        [string] $sqlservername,
        [string] $resourcegroupname,
        [string] $centralkeyvault,
        [string] $outputPath
        
    )

    $outputPath = _Get-Asac-OutputPath -outputPath $outputPath

    $sql = Invoke-Asac-AzCommandLine -azCommandLine "az sql server show --name $($sqlservername) --resource-group $($resourcegroupname) --output json"
    
    $sqlDict = _GetSQLServerDictionary -sqlservername  $($sql.name) -sqladminlogin "$($sql.administratorLogin)"

    #$sqlpasswordDict = _GetSQLServerPasswordDictionary -secretkey "<fill in keyname or empty when using AAD>" `
    #    -keyvaultname "<fill in keyvaultname or empty when using AAD>" `
    #   -keyvaultresourcegroup "<fill in resourcegroupname or empty when using AAD>"


    $adadminArray = @()
    $admins = Invoke-Asac-AzCommandLine -azCommandLine "az sql server ad-admin list --server-name $($sqlservername) --resource-group $($resourcegroupname) --output json"
    
    foreach ($a in $admins) {
        $adadminDict = _GetSQLServerADAdminDict -userPrincipal $($a.login) -principalId $($a.sid)
        $adadminArray += $adadminDict
    }

    $firewallArray = @()
    $fwRules = Invoke-Asac-AzCommandLine -azCommandLine "az sql server firewall-rule list --server $($sqlservername) --resource-group $($resourcegroupname) --output json"

    foreach ($fw in $fwRules) {

        $firewallDict = _GetSQLServerFirewallDict -rulename $($fw.name) -startip $($fw.startIpAddress) -endip $($fw.endIpAddress)
        $firewallArray += $firewallDict
    }

    $pw = _Get-KeyVaultSecret -keyvaultname $centralkeyvault -secretname "$($sqlservername)-adminpw"
    
    $dbArray = _Get-Asac-AllSQLDatabasesArray -sqlservername $sqlservername -username $sql.administratorLogin -resourcegroupname $resourcegroupname -password $pw
    #$sqlDict.Add('sqladminpassword', $sqlpasswordDict)
    $sqlDict.Add('adadmins', $adadminArray)
    $sqlDict.Add('firewallports', $firewallArray)
    $sqlDict.Add('databases', $dbArray)
    
    $path = Join-Path $outputPath -ChildPath "sql"
    New-Item $path -Force -ItemType Directory
    $filePath = Join-Path $path -ChildPath "sql.$($sqlservername).yml"
    Write-Host $filePath
    ConvertTo-YAML $sqlDict > $filePath
}


function Get-Asac-AllSQLServers { 
    param
    (
        [string] $centralkeyvault,
        [string] $outputPath
    )

    if ($outputPath -eq "" -or $outputPath -eq $null) {
        $outputPath = $PSScriptRoot
    }

    $sqlservs = Invoke-Asac-AzCommandLine -azCommandLine "az sql server list --output json"


    foreach ($sqls in $sqlservs) {
        Get-Asac-SQLServer -sqlservername $sqls.name  -resourcegroupname $sqls.resourceGroup -outputPath $outputPath -centralkeyvault $centralkeyvault -secretname $secretname
    }
}

function Process-Asac-SQLServer {
    param
    (
        [string] $sqlservername,
        [string] $resourcegroupname,
        [string] $basePath
    )

    if ($basePath -eq "" -or $basePath -eq $null) {
        $basePath = $PSScriptRoot
    }

    $path = Join-Path $basePath -ChildPath "sql"
    $file = Join-Path $path -ChildPath "sql.$($sqlservername).yml"
    $yamlContent = Get-Content -Path $file -Raw
    $sqlConfigured = ConvertFrom-Yaml $yamlContent


    #first update the AD-ADMIN
    $result = Invoke-Asac-AzCommandLine -azCommandLine "az sql server ad-admin create --display-name ""$($sqlConfigured.'adadmins'[0].userPrincipal)"" --object-id $($sqlConfigured.'adadmins'.principalId) --server-name $($sqlConfigured.sqlservername) -g $resourcegroupname"
    
}



function Rotate-Asac-SQLServerPassword {
    param
    (
        [string] $sqlservername,
        [string] $resourcegroupname,
        [string] $basePath
    )

    #since we know the keyvault and the sql, we can rotate password and update keyvault..
}

Get-Asac-AllSQLServers -sqlservername rvosqlasac1 -resourcegroupname rgpgeert -outputPath .\rvoazure -centralkeyvault asackeyvault 
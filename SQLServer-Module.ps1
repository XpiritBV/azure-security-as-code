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
function New-Asac-SQLServer {
    param
    (
        [string] $sqlservername,
        [string] $outputPath
    )

    $outputPath = _Get-Asac-OutputPath -outputPath $outputPath

    $sqlDict = _GetSQLServerDictionary -sqlservername  "sqlserv123 #SQL Server Name" -sqladminlogin "[generated] #username of SA when creating SQL Server"
    $sqlpasswordDict = _GetSQLServerPasswordDictionary -secretkey "sql-bigboss #Keyname in keyvault" -keyvaultname"kvPlatform123 #Name of the keyvault where password resides" -keyvaultresourcegroup "rgTest123 #Name of the resource group where the keyvault resides"

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

    $sqlDict.Add('sqladminpassword', $sqlpasswordDict)
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
        [string] $outputPath
    )

    $outputPath = _Get-Asac-OutputPath -outputPath $outputPath

    $sql = Invoke-Asac-AzCommandLine -azCommandLine "az sql server show --name $($sqlservername) --resource-group $($resourcegroupname) --output json"
    
    $sqlDict = _GetSQLServerDictionary -sqlservername  $($sql.name) -sqladminlogin "$($sql.administratorLogin)"

    $sqlpasswordDict = _GetSQLServerPasswordDictionary -secretkey "<fill in keyname or empty when using AAD>" `
        -keyvaultname "<fill in keyvaultname or empty when using AAD>" `
        -keyvaultresourcegroup "<fill in resourcegroupname or empty when using AAD>"


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

    $sqlDict.Add('sqladminpassword', $sqlpasswordDict)
    $sqlDict.Add('adadmins', $adadminArray)
    $sqlDict.Add('firewallports', $firewallArray)
    
    $path = Join-Path $outputPath -ChildPath "sql"
    New-Item $path -Force -ItemType Directory
    $filePath = Join-Path $path -ChildPath "sql.$($sqlservername).yml"
    Write-Host $filePath
    ConvertTo-YAML $sqlDict > $filePath
}


function Get-Asac-AllSQLServers { 
    param
    (
        [string] $outputPath
    )

    if ($outputPath -eq "" -or $outputPath -eq $null) {
        $outputPath = $PSScriptRoot
    }

    $sqlservs = Invoke-Asac-AzCommandLine -azCommandLine "az sql server list --output json"


    foreach ($sqls in $sqlservs) {
        Get-Asac-SQLServer -sqlservername $sqls.name  -resourcegroupname $sqls.resourceGroup -outputPath $outputPath
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
    $result = Invoke-Asac-AzCommandLine -azCommandLine "az sql server ad-admin create --display-name $($sqlConfigured.'adadmins'[0].userPrincipal) --object-id $($sqlConfigured.'adadmins'.principalId) --server-name rvosqlasac1 -g rgpgeert"
    
}

function Rotate-Asac-SQLServerPassword
{
    param
    (
        [string] $sqlservername,
        [string] $resourcegroupname,
        [string] $basePath
    )

#since we know the keyvault and the sql, we can rotate password and update keyvault..
}
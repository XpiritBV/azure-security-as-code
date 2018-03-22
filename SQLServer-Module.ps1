#Import Helpers
. .\SecurityAsCode-Helpers.ps1

function New-Asac-SQLServer
{
    param
    (
        [string] $sqlservername,
        [string] $outputPath
    )

    $outputPath = _Get-Asac-OutputPath -outputPath $outputPath

    $sqlDict = [ordered]@{sqlservername = "sqlserv123 #SQL Server Name"
                          sqladminlogin = "[generated] #username of SA when creating SQL Server"}

    $sqlpasswordDict = [ordered]@{ secretkey = "sql-bigboss #Keyname in keyvault"
                                 keyvaultname = "kvPlatform123 #Name of the keyvault where password resides"
                                 keyvaultresourcegroup = "rgTest123 #Name of the resource group where the keyvault resides"}

    $adadminArray = @()
    for ($i = 0; $i -lt 2;$i++) {

    $adadminDict = [ordered]@{userPrincipal = "John@domain.com #User or GroupName"
                              principalId = "7a2eddfe-341e-4c3b-8917-58a678249a81 #Object ID of User or GroupName. If empty name will be used"}
    $adadminArray +=$adadminDict
    }

    $firewallArray = @()
    for ($i = 0; $i -lt 2;$i++) {

        $firewallDict = [ordered]@{rulename = "Name of Rule"
                                  startip = "10.1.1.1"
                                  endip = "10.1.1.2"}
        $firewallArray += $firewallDict
        }

    $sqlDict.Add('sqladminpassword',$sqlpasswordDict)
    $sqlDict.Add('ad-admins',$adadminArray)
    $sqlDict.Add('firewallports',$firewallArray)
    
    $path = Join-Path $outputPath -ChildPath "sql"
    New-Item $path -Force -ItemType Directory
    $filePath = Join-Path $path -ChildPath "sql.$($sqlservername).yml"
    Write-Host $filePath
    ConvertTo-YAML $sqlDict > $filePath                               


}

function Get-Asac-SQLServer
{
    param
    (
        [string] $sqlservername,
        [string] $outputPath
    )

    $outputPath = _Get-Asac-OutputPath -outputPath $outputPath

    $sql = Invoke-AzCommandLine -azCommandLine "az sql server show --name $($sqlservername) --output json"
    
    $sqlDict = [ordered]@{     sqlservername = $sql.name
                               sqladminlogin = $sql.administratorLogin
                               sqladminpassword = $role.properties.roleDefinitionName}
    
    
    $rgDict = [ordered]@{}
    $rgDict.Add('resourcegroup',$rg.name)
    $rgDict.Add('rbac',$rbacArray)

    $path = Join-Path $outputPath -ChildPath "rg"
    New-Item $path -Force -ItemType Directory
    $filePath = Join-Path $path -ChildPath "$($resourcegroup).yml"
    Write-Host $filePath
    ConvertTo-YAML $rgDict > $filePath
}


function Get-Asac-AllSQLServers
{ 
    param
    (
        [string] $outputPath
    )

    if ($outputPath -eq "" -or $outputPath -eq $null)  
    {
        $outputPath = $PSScriptRoot
    }

    $sqlservs = Invoke-AzCommandLine -azCommandLine "az sql server list --output json)"


    foreach ($sqls in $sqlservs) {
        Get-Asac-SQLServer -sqlservername $sqls.name -outputPath $outputPath
    }
}

function Process-Asac-SQLServer
{
    param
    (
        [string] $sqlservername,
        [string] $basePath
        
    )

    if ($basePath -eq "" -or $basePath -eq $null)  
    {
        $basePath = $PSScriptRoot
    }

    $path = Join-Path $basePath -ChildPath "sql"
    $file = Join-Path $path -ChildPath "$($resourcegroup).yml"
    $yamlContent = Get-Content -Path $file -Raw
    $rgConfigured = ConvertFrom-Yaml $yamlContent

}

New-Asac-SQLServer -sqlservername aapnoot -outputPath .\rvoazure
#executes AZ command and returns an PSObject
function Invoke-Asac-AzCommandLine
{
    param
    (
        [string] $azCommandLine,
        [string] $RegEx,
        [string] $ReplaceValue,
        [switch] $verbose
    )

    #2>&1 redirects error output into oblivion.
    # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_redirection?view=powershell-6&viewFallbackFrom=powershell-Microsoft.PowerShell.Core
    if ($verbose.IsPresent -ne $true) {
        $resultJson  = "$(Invoke-Expression $azCommandLine 2>&1)"
    }
    else {
        $resultJson  = "$(Invoke-Expression $azCommandLine)"
    }

    if ($RegEx -ne "" -or $RegEx -ne $null) {
        $resultJson = $resultJson -replace $RegEx, $ReplaceValue
    }
    $result = ConvertFrom-Json $resultJson
    
    return $result
}

function _Get-Asac-OutputPath
{
    param 
    (
        [string] $outputPath
    )
    
    if ($outputPath -eq "" -or $outputPath -eq $null)  
    {
        $outputPath = $PSScriptRoot
    }
    return $outputPath
}

function _IsLoggedIn{
    
    $account = Invoke-Asac-AzCommandLine -azCommandLine "az account show --output json" 2>$null
    if($account -ne $null){
        return $true
    }
    else{
        return $false
    }
}

function _LogIn{
    param 
    (
        [hashtable] $config
    )
    Invoke-Asac-AzCommandLine -azCommandLine "az logout" 2>$null
    $account = Invoke-Asac-AzCommandLine -azCommandLine "az login --service-principal -u $($config.principalId) -p $($config.password) --tenant $($config.tenantId) --output json"
    $account = Invoke-Asac-AzCommandLine -azCommandLine "az account set -s $($config.subscription)"

    if(_IsLoggedIn){
        return $true
    }
    else{
        return $false
    }
}


#source code from https://powershellstation.com/2009/09/15/executing-sql-the-right-way-in-powershell/
function _Execute-NonQuery
{
    param
    (
        [string] $sql,
        $parameters=@{},
        [string]$servername,
        [string]$dbname,
        [string]$username,
        [string]$password,
        [bool]$isIntegrated,
        $timeout=30
    )        
    

    if ($isIntegrated)  {
        $conn=new-object data.sqlclient.sqlconnection "Server=$($servername).database.windows.net;database=$($dbname);Integrated Security=True"
    }
    else {
        $conn = new-object data.sqlclient.sqlconnection "server=$($servername).database.windows.net;database=$($dbname);Integrated Security=false;User ID=$($username);Password=$($password);";
    }

    $cmd=New-Object System.Data.SqlClient.SqlCommand($sql,$conn)
    $cmd.CommandTimeout=$timeout
    
    foreach($p in $parameters.Keys){
        [Void] $cmd.Parameters.AddWithValue("@$p",$parameters[$p])
    }
    
    try {

        $cmd.Connection.Open();
        $cmd.ExecuteNonQuery();
    }
    catch
    {
        Write-Error "Error executing SQL Statement. $ErrorMessage"
    }
    finally
    {
        $cmd.Connection.Close()
    }
   #$conn=new-object data.sqlclient.sqlconnection "Server=servername;Integrated Security=True"
    #$conn.open()
    #exec-query 'select * from sys.databases' -conn $conn
    #exec-query 'select FirstName,LastName from AdventureWorks2008.Person.Person wh   
    #-parameter @{fname='Mike'}
}
    

function _Execute-Query
{
    param
    (
        [string] $sql,
        $parameters=@{},
        [string]$servername,
        [string]$dbname,
        [string]$username,
        [string]$password,
        [bool]$isIntegrated,
        $timeout=30
    )        
    

    if ($isIntegrated)  {
        $conn=new-object data.sqlclient.sqlconnection "Server=$($servername).database.windows.net;database=$($dbname);Integrated Security=True"
    }
    else {
        $conn = new-object data.sqlclient.sqlconnection "server=$($servername).database.windows.net;database=$($dbname);Integrated Security=false;User ID=$($username);Password=$($password);";
    }

    $cmd=New-Object System.Data.SqlClient.SqlCommand($sql,$conn)
    $cmd.CommandTimeout=$timeout
    
    foreach($p in $parameters.Keys){
        [Void] $cmd.Parameters.AddWithValue("@$p",$parameters[$p])
    }
    
    try {

        $cmd.Connection.Open();
        $ds=New-Object system.Data.DataSet
        $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
        $da.fill($ds) | Out-Null
    }
    catch
    {
        $ErrorMessage = $_.Exception.Message
        Write-Error "Error executing SQL Statement. $ErrorMessage"
    }
    finally
    {
        $cmd.Connection.Close()
    }

    return $ds
}
    
function _Get-KeyVaultSecret
{
    param
    (
        [string] $keyvaultname,
        [string] $secretname
    )

    $cmdLine = "az keyvault secret show --vault-name $keyvaultname --name $secretname"
    $secret = Invoke-Asac-AzCommandLine -azCommandLine $cmdLine
    return $secret.value
}
function _Set-KeyVaultSecret
{
    param
    (
        [string] $keyvaultname,
        [string] $secretname,
        [string] $password
    )

    $cmdLine = "az keyvault secret set --vault-name $keyvaultname --name $secretname --value ""$password"""
    $secret = Invoke-Asac-AzCommandLine -azCommandLine $cmdLine
    
}
Function New-RandomComplexPassword ($length=8)
{
    $Assembly = Add-Type -AssemblyName System.Web
    $password = [System.Web.Security.Membership]::GeneratePassword($length,2)
    return $password
}

Function _Get-AADNameFromObjectId
{
    param
    (
        [string] $ObjectId
    )

    #This function retrieves the name of the group, spn or user for display

    #most used is group.. Try this first
    $group = Invoke-Asac-AzCommandLine -azCommandLine "az ad group show --group ""$($ObjectId)""" 

    if ($group -ne $null) 
    {
        return $($group.displayName)
    }

    #now users
    $user = Invoke-Asac-AzCommandLine -azCommandLine "az ad user show --upn-or-object-id ""$($ObjectId)"""

    if ($user -ne $null) 
    {
        return $($user.userPrincipalName)
    }

    #now spn
    $spn = Invoke-Asac-AzCommandLine -azCommandLine "az ad sp show --id ""$($ObjectId)"""
    if ($spn -ne $null)
    {
        return $($spn.displayName)
    }

    return ""
}

Function _Get-AADObjectIdFromName
{
    param
    (
        [string] $name
    )

    #This function retrieves the name of the group, spn or user for display

    #most used is group.. Try this first
    $group = Invoke-Asac-AzCommandLine -azCommandLine "az ad group show --group ""$($name)""" 

    if ($group -ne $null) 
    {
        return $($group.objectId)
    }
    else 
    {
        Write-Host "No Group found with name $($name)"
    }

    #now users
    $user = Invoke-Asac-AzCommandLine -azCommandLine "az ad user show --upn-or-object-id ""$($name)"""

    if ($user -ne $null) 
    {
        return $($user.objectId)
    }
    else 
    {
        Write-Host "No user found with name $($name). Use full principal name like test@domain.com"
    }

    #now spn
    ##SPN need to be in format of https://domain.com/65f49925-2217-4e6f-86b5-733072e41bcedd"
    $spn = Invoke-Asac-AzCommandLine -azCommandLine "az ad sp show --id ""$($name)"""
    if ($spn -ne $null)
    {
        return $($spn.objectId)
    }
    else 
    {
        Write-Host "No SPN found with name $($name). Format should be https://domain.com/65f49925-2217-4e6f-86b5-733072e41bcedd/"
    }

    return ""
}
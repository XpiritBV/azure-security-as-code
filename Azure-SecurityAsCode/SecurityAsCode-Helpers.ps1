#executes AZ command and returns an PSObject
function Invoke-Asac-AzCommandLine
{
    param
    (
        [string] $azCommandLine,
        [string] $RegEx,
        [string] $ReplaceValue
    )

    $resultJson  = "$(Invoke-Expression $azCommandLine)"
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
    $group = Invoke-Asac-AzCommandLine -azCommandLine "az ad group show --group $objectid"

    if ($group -ne $null) 
    {
        return $($group.displayName)
    }

    #now users
    $user = Invoke-Asac-AzCommandLine -azCommandLine "az ad user show --upn-or-object-id $objectid"

    if ($user -ne $null) 
    {
        return $($user.userPrincipalName)
    }

    #now spn
    $spn = Invoke-Asac-AzCommandLine -azCommandLine "az ad sp show --id $objectid"
    if ($spn -ne $null) 
    {
        return $($spn.displayName)
    }

    return ""
}
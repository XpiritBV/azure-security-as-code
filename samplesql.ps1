## - Prepare connection string and execute query:

# $Global:getSvr = "sqlazureDB.database.windows.net,1433";
# $Global:conmaster = "server=$Global:getSvr;database=master;Integrated Security=false;User ID=sa;" + 'Password=password';
# $Global:condb = "server=$Global:getSvr;database=advWorks;Integrated Security=false;User ID=sa;" + 'Password=password';

# $sqlogin = "CREATE LOGIN [username1] WITH password='VeryComplicatedPassword1234!'"
# $sqluser = "CREATE USER [username1] FOR LOGIN [username1]"
# $sqlrole = "EXEC sp_addrolemember N'db_owner', [username1]"

# $sdmaster = New-Object System.Data.SqlClient.SqlCommand($($sqlogin), $Global:conmaster)
# $sdmaster.Connection.Open();
# $sdmaster.ExecuteNonQuery();
# $sdmaster.Connection.Close();

# $sduser = New-Object System.Data.SqlClient.SqlCommand($($sqluser), $Global:condb)
# $sduser.Connection.Open();
# $sduser.ExecuteNonQuery();
# $sduser.Connection.Close();

# $sduser = New-Object System.Data.SqlClient.SqlCommand($($sqlrole), $Global:condb)
# $sduser.Connection.Open();
# $sduser.ExecuteNonQuery();
# $sduser.Connection.Close();

. .\SecurityAsCode-Helpers.ps1


$sqlgetusers = @'
select su.name as username, roletab.name as rolename from sys.database_role_members rm inner join sys.sysusers su ON su.uid= rm.member_principal_id
inner join sys.sysusers roletab ON roletab.uid = rm.role_principal_id
WHERE su.islogin=1 
AND su.name <> 'dbo' 
AND su.name <> 'guest'
AND su.sid  is not null
'@

$ds = _Execute-Query -sql $sqlgetusers -servername rvosqlasac1 -dbname advworks -username bigboss123 -password Welkom123 -isIntegrated $false


foreach ($Row in $ds.Tables[0].Rows) { 
	#write-Output "$($Row)"
	write-Output "$($Row.username)"
	write-Output "$($Row.rolename)"
}
    #$conn.open()
    #exec-query 'select * from sys.databases' -conn $conn
    #exec-query 'select FirstName,LastName from AdventureWorks2008.Person.Person wh   

    ## GET SQL USERS
    #SELECT * 
    #FROM sys.sysusers 
    #WHERE islogin=1 
    #AND name <> 'dbo' 
    #AND name <> 'guest'
    #AND sid  is not null 



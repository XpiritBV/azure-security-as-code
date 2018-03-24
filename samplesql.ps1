## - Prepare connection string and execute query:
$Global:getSvr = "sqlazureDB.database.windows.net,1433";
$Global:conmaster = "server=$Global:getSvr;database=master;Integrated Security=false;User ID=sa;" + 'Password=password';
$Global:condb = "server=$Global:getSvr;database=advWorks;Integrated Security=false;User ID=sa;" + 'Password=password';

$sqlogin = "CREATE LOGIN [username1] WITH password='VeryComplicatedPassword1234!'"
$sqluser = "CREATE USER [username1] FOR LOGIN [username1]"
$sqlrole = "EXEC sp_addrolemember N'db_owner', [username1]"

$sdmaster = New-Object System.Data.SqlClient.SqlCommand($($sqlogin), $Global:conmaster)
$sdmaster.Connection.Open();
$sdmaster.ExecuteNonQuery();
$sdmaster.Connection.Close();

$sduser = New-Object System.Data.SqlClient.SqlCommand($($sqluser), $Global:condb)
$sduser.Connection.Open();
$sduser.ExecuteNonQuery();
$sduser.Connection.Close();

$sduser = New-Object System.Data.SqlClient.SqlCommand($($sqlrole), $Global:condb)
$sduser.Connection.Open();
$sduser.ExecuteNonQuery();
$sduser.Connection.Close();


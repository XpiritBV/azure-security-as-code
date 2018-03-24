if not exists(select * from [sys].[sysusers] where name = '$(SQLUsername)')

begin
	create user [$(SQLUsername)]
	for login [$(SQLUsername)]
	with default_schema = dbo
end

-- Add user to the database owner role
EXEC sp_addrolemember N'db_owner', [$(SQLUsername)]
GO

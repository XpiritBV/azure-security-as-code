if not exists(select * from [sys].[sysusers] where name = '@sqlusername')

begin
	create user [@sqlusername]
	for login [@sqlusername]
	with default_schema = dbo
end

-- Add user to the database owner role
EXEC sp_addrolemember N'@sqlrole', [@sqlusername]


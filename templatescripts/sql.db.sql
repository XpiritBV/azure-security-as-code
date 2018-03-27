if not exists(select * from [sys].[sysusers] where name = '@sqlusername')

begin
	create user [@sqlusername]
	for login [@sqlusername]
	with default_schema = dbo
end


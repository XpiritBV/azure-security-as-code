declare @u varchar(255)
declare @r varchar(255)
declare cur CURSOR LOCAL for

select su.name as username, roletab.name as rolename from sys.database_role_members rm inner join sys.sysusers su ON su.uid= rm.member_principal_id
inner join sys.sysusers roletab ON roletab.uid = rm.role_principal_id
WHERE su.islogin=1 
AND su.name <> 'dbo' 
AND su.name <> 'guest'
AND su.sid  is not null
ORDER BY su.uid

open cur
fetch next from cur into @u, @r

while @@FETCH_STATUS = 0 BEGIN
    exec sp_droprolemember @r, @sqlusername
    fetch next from cur into @u, @r
END

close cur
deallocate cur
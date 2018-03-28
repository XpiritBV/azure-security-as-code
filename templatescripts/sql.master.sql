BEGIN TRY  
    CREATE LOGIN  [@sqlusername] WITH PASSWORD=N'@sqlpassword'
END TRY  
BEGIN CATCH  
	PRINT 'User already exists'
END CATCH  



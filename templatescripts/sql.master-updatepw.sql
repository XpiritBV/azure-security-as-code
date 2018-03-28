BEGIN TRY  
    ALTER LOGIN  [@sqlusername] WITH PASSWORD=N'@sqlpassword'
END TRY  
BEGIN CATCH  
	PRINT 'Error changing password'
END CATCH  






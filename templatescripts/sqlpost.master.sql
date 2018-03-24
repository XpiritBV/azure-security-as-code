BEGIN TRY  
    CREATE LOGIN  [$(SQLUsername)] WITH PASSWORD=N'$(SQLPassword)'
END TRY  
BEGIN CATCH  
	PRINT 'User already exists'
END CATCH  
GO






Remove-Module Azure-SecurityAsCode -Force

Import-Module $pwd\Azure-SecurityAsCode

#call function here
Process-Asac-DataLakeStore -datalakeStoreAccount rvodls1 -basePath .\rvoazure

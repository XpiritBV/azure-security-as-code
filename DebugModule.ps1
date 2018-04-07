Remove-Module Azure-SecurityAsCode -Force

Import-Module $pwd\Azure-SecurityAsCode

#call function here
Get-Asac-DataLakeStore -datalakeStoreAccount rvodls1 -outputPath .\rvoazure

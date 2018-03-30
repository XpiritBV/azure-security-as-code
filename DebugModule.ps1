Remove-Module Azure-SecurityAsCode -Force

Import-Module $pwd\Azure-SecurityAsCode

Get-Asac-Keyvault -name asackeyvault -outputPath .\rvoazure
docker image build -t powershell-azurecli .

docker run -it -v /Users/geertvdc/src/github/geertvdc/azure-security-as-code:/app powershell-azurecli

#steps:
#log in to azure (TODO: do this while starting container)
az login

#download permissions
./Download-AzureSecurity-AsYaml.ps1 > rbacsecurity.yml

#check permissions
./Enforce-Azuresecurity.ps1

#run docker container directly
docker run -it -v `pwd`:/asac asac pwsh -c Get-Asac-AllResourceGroups


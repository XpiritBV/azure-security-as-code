docker image build -t powershell-azurecli -f .\DockerBase\Dockerfile .

docker run -it -v /Users/rvano/src/github/azure-security-as-code:/app powershell-azurecli

#steps:
#log in to azure (TODO: do this while starting container)
az login

#download permissions
./Download-AzureSecurity-AsYaml.ps1 > rbacsecurity.yml

#check permissions
./Enforce-Azuresecurity.ps1
# azure-security-as-code
Scripts to define your azure security governance as code and avoid manual settings of permissions and avoiding configuration drift

## Usage ##
* Login with az login
* import powershell script

```
. .\resourcegroups-module.ps1
```

* Run 1 resource group or all

```powershell
Download-AllResourceGroups

#or

Download-ResourceGroupYaml -resourcegroup "resourcegroupName"
```
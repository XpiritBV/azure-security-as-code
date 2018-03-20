# azure-security-as-code
Scripts to define your azure security governance as code and avoid manual settings of permissions and avoiding configuration drift

## Usage in general ##

* Login with az login
* import powershell script

```
. .\resourcegroups-module.ps1
```

## Usage Resource Group Download ##

* Run 1 resource group or all

```powershell
Download-AllResourceGroups

#or

Download-ResourceGroupYaml -resourcegroup "resourcegroupName"
```

## Usage Security Group Download ##

* Run 1 security group or all
* creates and looks for files in directory ad-group

```powershell
Download-AllSecurityGroups

#or

Download-SecurityGroupYaml -securitygroup "securitygroupName"
```

* Update yaml file with new users

```powershell
Update-SecurityGroup -securitygroup "securitygroupName"
```

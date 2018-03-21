# azure-security-as-code
Scripts to define your azure security governance as code and avoid manual settings of permissions and avoiding configuration drift

This library is created in a modular fashion where each module will deliver the functionality for security governance of a specific Azure resource type

### Current Azure resource types supported
* Resource Groups
* Security Groups

### Future Azure resource types on backlog
* Azure SQL
* Keyvault
* Azure Datalake
* Others

If you have preferences on other resource types let us known in the issues.

# Usage

## Usage in general ##


### Prerequisites
* install yaml module needed to generate yaml outputs
```powershell
Install-Module PSYaml -f
```

* Login with Azure CLI and select your subscription

```powershell
az login
```
* import powershell script

```powershell
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

![](https://xpirit.visualstudio.com/_apis/public/build/definitions/b0d59b52-bc4d-4af7-a6a2-768ae3158e76/101/badge)
![](https://img.shields.io/powershellgallery/v/azure-securityascode.svg)
![](https://img.shields.io/powershellgallery/dt/azure-securityascode.svg)

![Azure Security as Code](./img/logo.png "Azure Security as Code")
Azure Security as Code is a set of scripts to define your azure security governance as code and avoid manual settings of permissions and avoiding configuration drift.

This library is created in a modular fashion where each module will deliver the functionality for security governance of a specific Azure resource type

### Current Azure resource types supported
* Resource Groups
* Security Groups
* Azure SQL
* Keyvault

### Future Azure resource types on backlog
* Azure Datalake
* Others

If you have preferences on other resource types let us known in the issues.

# Usage

## Usage in general ##


### Prerequisites
* install yaml module needed to generate yaml outputs
```powershell
Install-Module Azure-SecurityAsCode
```

* Login with Azure CLI and select your subscription

```powershell
az login
```

* Check available cmdlets
```powershell
Get-Command -Module Azure-SecurityAsCode
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

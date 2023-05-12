# Find Open Azure resources

Collection of Powershell scripts to find publicly exposed Azure resources. 


## Prerequisite

- Azure Powershell ([instructions](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps))
- A security principal with read access to all the subscriptions in the environment


## Usage

### Enable AzureRM compatibility aliases ([more info](https://docs.microsoft.com/en-us/powershell/azure/migrate-from-azurerm-to-az?view=azps-4.7.0#enable-azurerm-compatibility-aliases)) 

The scripts make use of the old AzureRM module which is not maintained by Microsoft anymore. Fortunately, you can use the built-in aliases in the new Az module for retro compatibility.

```shell
Enable-AzureRmAlias -Scope CurrentUser
```


### Connect to the Azure control plane

```shell
Connect-AzureRmAccount
```

```shell
Get-AzureRmSubscription
```


### Find open Azure resources

```shell
.\Find-OpenApps.ps1
```

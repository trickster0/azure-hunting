# Find Dangling DNS resources

Tool to find dangling DNS records from multiple subscriptions in a tenant.


# Prerequisites

- Azure Powershell 7.* ([instructions](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps))

- Read access on the subscription(s) in scope

- AzDanglingDomain PowerShell module


# Usage

### Install and Import the AzDanglingDomain PowerShell module 

```shell
Install-Module -Name AzDanglingDomain
```

```shell
Import-Module  -Name AzDanglingDomain
```

### Connect to the Azure control plane

```shell
Connect-AzureRmAccount
```

### Fetch DNS records from all subscriptions

```shell
Get-DanglingDnsRecords -FetchDnsRecordsFromAzureSubscription
```


# Prevention

https://docs.microsoft.com/en-us/azure/security/fundamentals/subdomain-takeover


# Credits

https://github.com/Azure/Azure-Network-Security/tree/master/Cross%20Product/DNS%20-%20Find%20Dangling%20DNS%20Records

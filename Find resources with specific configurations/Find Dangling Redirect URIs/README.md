# Find Dangling Redirect URIs

Tool to find dangling redirect URIs in an Azure tenant.


# Prerequisites

- Azure Powershell 5.0 ([instructions](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps))

- Azure AD Module ([instructions](https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-adv2?view=azureadps-2.0))

- Read access on the tenant's App Registrations


# Usage

### Run the scripts directly (a login prompt will appear for authentication)

```shell
.\Find-DanglingRedirectURIs.ps1
```

## Credits

https://securecloud.blog/2021/05/28/using-powershell-to-find-dangling-redirect-uris-in-azure-ad-tenant/

# ROADTools queries

Collection of SQL queries for ROADTools to investigate an Azure tenant more efficiently and in depth.


# Quick wins

#### List all users reported as 'compromised' by AAD Identity Protection

```shell
SELECT objectId, displayName, isCompromised FROM Users
WHERE isCompromised IS NOT NULL
```

#### List all app registrations with a plain-text secret (should never be possible!)

```shell
SELECT appId, displayName, passwordCredentials FROM Applications
WHERE passwordCredentials NOT LIKE '%"value": null%'
AND passwordCredentials != "[]"
```


# User investigation

#### List all users that are not assigned any group
```shell
SELECT objectId, displayName FROM Users 
WHERE objectId NOT IN (SELECT User FROM lnk_group_member_user)
```


# Azure AD roles investigation

#### List all custom Azure AD roles (i.e. not built in) 

```shell
SELECT * FROM RoleDefinitions
WHERE isBuiltIn == "0"
```

#### List all dynamic groups with their membership rules, excluding those with the extensionAttributes property (on-prem attribute, so not vulnerable to common dynamic-rule issues)

```shell
SELECT description, displayName, membershipRule  FROM Groups
WHERE groupTypes LIKE '%DynamicMembership%'
AND membershipRule NOT LIKE '%extensionAttribute%'
```


# App registration investigation (i.e. apps registered in this tenant)

#### Get all reply URLs for all app registrations (see if some refer to interesting URLs - grep for azurewebsites.net, remove everything after the last "/" and run through Aquatone ; go through the remaining URLs manually)

```shell
SELECT DISTINCT replyUrls FROM Applications
WHERE replyUrls != "[]"
AND replyUrls != '["http://localhost"]'
AND replyUrls != '["https://localhost"]'
AND replyUrls != '["https://VisualStudio/SPN"]'
```

#### List all app registrations with an associated Managed Identity

```shell
SELECT appId, displayName, encryptedMsiApplicationSecret FROM Applications
WHERE encryptedMsiApplicationSecret != ""
```

#### List all app registrations that are multitenant (i.e. users from other directories still need to be brought to the tenant as B2B guest users to be authorized to access the app)

```shell
SELECT appId, displayName, availableToOtherTenants, replyUrls FROM Applications
WHERE availableToOtherTenants == "1"
```

#### List all app registrations that have their token configured with optional claims (see if insecured ones are used - e.g. url to change the user's password, unecesasary informatin disclosure, etc.)

```shell
SELECT appId, displayName, optionalClaims FROM Applications
WHERE optionalClaims != ""
```

#### List all application owners (see who they are)

```shell
SELECT DISTINCT objectId, displayName, signInNames FROM Users
INNER JOIN lnk_application_owner_user ON lnk_application_owner_user.User = Users.objectId
```

#### List all app registrations with static application permissions (i.e. App roles meant for applications - can be useful during redteaming if looking for an app with a lot of consented permissions)
```shell
SELECT appId, displayName, requiredResourceAccess FROM Applications
WHERE requiredResourceAccess != "[]"
```

#### See what applications users can request access to (who provides access?, does the admin need to add me in the list of AppRoles for a certain AppRole in the app's service principal?)
```shell
https://myapplications.microsoft.com/
```


# Service principal investigation (i.e. apps registered in another tenant, but used here)

#### List all Managed Identities

```shell
SELECT appId, displayName, replyUrls, servicePrincipalType FROM ServicePrincipals
WHERE servicePrincipalType == "ManagedIdentity"
```

#### List all service principals that have their application object registered in a different tenant, but have a client secret assigned to them (potential backdoors)

Investigate it in ROADRecon directly

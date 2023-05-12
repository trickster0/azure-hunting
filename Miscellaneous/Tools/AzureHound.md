# AzureHound

Collection of AzureHound notes for installation and data-collection, as well as custom queries.

# Requirements

**Note**: performs best on Windows

- [neo4j](https://neo4j.com/download-center/#community)
- [AzureHound](https://github.com/bloodhoundad/azurehound/releases)
- [BloodHound](https://github.com/BloodHoundAD/BloodHound/releases)


# Instructions

## 1. Start neo4j

Start neo4j as a console application:

```shell
<neo4j_folder>\bin\neo4j console
```


## 2. Gather Azure AD data

### 2.1 Get a Graph token

**Note**: if grabbing manually, make sure the audience is `https://graph.microsoft.com/` and NOT `https://graph.windows.net`

```shell
$body = @{
    "client_id" = "1950a258-227b-4e31-a9cf-717495945fc2"
    "resource" = "https://graph.microsoft.com"
}
$UserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"
$Headers=@{}
$Headers["User-Agent"] = $UserAgent
$authResponse = Invoke-RestMethod `
    -UseBasicParsing `
    -Method Post `
    -Uri "https://login.microsoftonline.com/common/oauth2/devicecode?api-version=1.0" `
    -Headers $Headers `
    -Body $body
$authResponse
```

```shell
$body=@{
    "client_id" = "1950a258-227b-4e31-a9cf-717495945fc2"
    "grant_type" = "urn:ietf:params:oauth:grant-type:device_code"
    "code" = $authResponse.device_code
}
$Tokens = Invoke-RestMethod `
    -UseBasicParsing `
    -Method Post `
    -Uri "https://login.microsoftonline.com/Common/oauth2/token?api-version=1.0" `
    -Headers $Headers `
    -Body $body
$Tokens.access_token
```

### 2.2 Gather all Azure AD objects

```shell
./azurehound -j <access_token> list az-ad -o aad.json -v 2
```


## 3. Gather Azure data

### 3.1 Get an ARM token

**Note**: if grabbing manually, make sure the audience is `https://management.azure.com` and NOT `https://management.core.windows.net`

```shell
$body = @{
    "client_id" =     "1950a258-227b-4e31-a9cf-717495945fc2"
    "resource" =      "https://management.azure.com"
}
$UserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"
$Headers=@{}
$Headers["User-Agent"] = $UserAgent
$authResponse = Invoke-RestMethod `
    -UseBasicParsing `
    -Method Post `
    -Uri "https://login.microsoftonline.com/common/oauth2/devicecode?api-version=1.0" `
    -Headers $Headers `
    -Body $body
$authResponse
```

```shell
$body=@{
    "client_id" =  "1950a258-227b-4e31-a9cf-717495945fc2"
    "grant_type" = "urn:ietf:params:oauth:grant-type:device_code"
    "code" =       $authResponse.device_code
}
$Tokens = Invoke-RestMethod `
    -UseBasicParsing `
    -Method Post `
    -Uri "https://login.microsoftonline.com/Common/oauth2/token?api-version=1.0" `
    -Headers $Headers `
    -Body $body
$Tokens.access_token
```

### 3.2 Gather all Azure objects
```shell
./azurehound -j <access_token> list az-rm -o azure.json -v 2
```

# Custom queries

Coming ...

# Credits

https://bloodhound.readthedocs.io/en/latest/data-collection/azurehound-all-flags.html

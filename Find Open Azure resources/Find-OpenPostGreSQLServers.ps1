#### Description ####################################################
#
# Indexes all the static and flexible PostgreSQL Servers in an Azure environment and shows the following information:
# • Whether SSL is enforced
# • Whether a minimum TLS version is required
# • Whether the server is accessible from the Azure backbone
# • Whether the server is accessible from selected public networks
# • Whether the server is accessible from as a service endpoint (i.e. on a public endpoint accessible only to VNets)
#
# Note 1: by default, public IPs allowed to connect to a SQL server need to be specified explicitly, even though "Deny Public Network Access" is set to "No"
# More info: https://techcommunity.microsoft.com/t5/azure-database-support-blog/lesson-learned-126-deny-public-network-access-allow-azure/ba-p/1244037
#
# Note 2: flexible PostgreSQL servers enforce SSL and the use of TLS 1.2 by default
#
# Note 3: flexible PostgreSQL servers cannot combine VNet integration (private/service endpoints) with public access (i.e. only one or the other at a time)
# 
# Note 4: this script requires Powershell 7 and the Az.PostgreSql module (Install-Module -Name Az.PostgreSql)
#
####

$path = "C:\Users\$env:UserName\Downloads\"
$file = "_open-PostgreSQLServers.txt" 
$date = (Get-Date -UFormat "%Y-%m-%d")
$resultFile = "${path}${date}${file}"
$finalOutputText = [System.Text.StringBuilder]::new()
$finalOutputUrls = [System.Text.StringBuilder]::new()

if (!(test-path $path )) { New-Item -ItemType Directory -Force -Path $path }

$subscriptions = (Get-AzSubscription).Id | sort | Get-Unique

foreach ($subscription in $subscriptions) {
	Set-AzContext -Subscription $subscription

	$tenant = (Get-AzSubscription -SubscriptionId $subscription).TenantId
	$singlePostGreSqlServers = Get-AzResource -ResourceType "Microsoft.DBforPostgreSQL/servers"
	$flexiblePostGreSqlServers = Get-AzResource -ResourceType "Microsoft.DBforPostgreSQL/flexibleServers"

	# Single PostGreSQL servers
	foreach ($singlePostGreSqlServer in $singlePostGreSqlServers) {
		$rg = $singlePostGreSqlServer.ResourceGroupName
		$name = $singlePostGreSqlServer.Name

		$singlePostGreSqlServer = (Get-AzResource -ResourceType "Microsoft.DBforPostgreSQL/servers" -ResourceGroupName $rg -Name $name)

		$hasSslEnforced = if ($singlePostGreSqlServer.Properties.sslEnforcement -eq "Enabled") {$true} else {$false}
		$isMinimumTlsVersionSet = if ($singlePostGreSqlServer.Properties.minimalTlsVersion -eq "TLSEnforcementDisabled") {$false} else {$true}

		$hasPublicNetworkAccess = if ($singlePostGreSqlServer.Properties.publicNetworkAccess -eq "Enabled") {$true} elseif ($singlePostGreSqlServer.Properties.publicNetworkAccess -eq "Disabled") {$false} else {"Undetermined"}
		$privateEndpoints = $singlePostGreSqlServer.Properties.privateEndpointConnections
		$firewallRules = (Get-AzPostgreSqlFirewallRule -SubscriptionId $subscription -ResourceGroupName $rg -ServerName $name)
		$vnetRules = (Get-AzPostgreSqlVirtualNetworkRule -ResourceGroupName $rg -ServerName $name)

		$outputText = [System.Text.StringBuilder]::new()
		[void]$outputText.Append("$name - Server type: single; Enforce SSL connection: $hasSslEnforced; Enforce minimum TLS version: $isMinimumTlsVersionSet")

		if ($hasPublicNetworkAccess) {
			# Note: Allowing Public Network Access without specifying a list of explicitly-allowed IP addresses denies all external connections by default
			$allowsExternalAccess = $false
			$allowsAzureBackboneAccess = $false
			$hasServiceEndpoint = $false
			
			if ($firewallRules) {			
				# Public Network Access is allowed from either a set of public IP addresses and/or the Azure backbone
				foreach ($firewallRule in $firewallRules) {
					$ruleName = $firewallRule.FirewallRuleName

					if ($ruleName -eq "AllowAllWindowsAzureIps") {
						$allowsAzureBackboneAccess = $true
					} else {
						$allowsExternalAccess = $true
					}
				}
			} 

			[void]$outputText.Append("; Accessible from the Azure backbone: $allowsAzureBackboneAccess")
			[void]$outputText.Append("; Accessible from selected networks: $allowsExternalAccess")

			if ($vnetRules) {
				[void]$outputText.Append("; Accessible as service endpoint*: True")
			} else {
				[void]$outputText.Append("; Accessible as service endpoint: False")
			}


		} else {
			[void]$outputText.Append("; Deny public network access: True")
		}

		$outputUrl = "https://portal.azure.com/#@${tenant}/resource${id}/overview"
		
		[void]$finalOutputText.AppendLine($outputText)
		[void]$finalOutputUrls.AppendLine($outputUrl)

		Write-Output $outputText.toString()
	}

	# Flexible PostGreSQL servers
	foreach ($flexiblePostGreSqlServer in $flexiblePostGreSqlServers) {
		$rg = $flexiblePostGreSqlServer.ResourceGroupName
		$name = $flexiblePostGreSqlServer.Name

		$flexiblePostGreSqlServer = (Get-AzResource -ResourceType "Microsoft.DBforPostgreSQL/flexibleServers" -ResourceGroupName $rg -Name $name)

		$hasPublicNetworkAccess = if ($flexiblePostGreSqlServer.Properties.network.publicNetworkAccess -eq "Enabled") {$true} else {$false}
		$firewallRules = (Get-AzPostgreSqlFlexibleServerFirewallRule -SubscriptionId $subscription -ResourceGroupName $rg -ServerName $name)

		$outputText = [System.Text.StringBuilder]::new()
		[void]$outputText.Append("$name - Server type: flexible; Enforce SSL connection**: True; Enforce minimum TLS version**: True")

		if ($hasPublicNetworkAccess) {
			# Note: Allowing Public Network Access without specifying a list of explicitly-allowed IP addresses denies all external connections by default
			$allowsExternalAccess = $false
			$allowsAzureBackboneAccess = $false
			
			if ($firewallRules) {			
				# Public Network Access is allowed from either a set of public IP addresses and/or the Azure backbone
				foreach ($firewallRule in $firewallRules) {
					$ruleName = $firewallRule.FirewallRuleName

					if ($ruleName -eq "AllowAllWindowsAzureIps") {
						$allowsAzureBackboneAccess = $true
					} else {
						$allowsExternalAccess = $true
					}
				}
			} 

			[void]$outputText.Append("; Accessible from the Azure backbone: $allowsAzureBackboneAccess")
			[void]$outputText.Append("; Accessible from selected networks: $allowsExternalAccess; Accessible as service endpoint***: Unsupported (using public access)")
		} else {
			[void]$outputText.Append("; Deny public network access: True; Private access (VNet Integration): True")
		}

		$outputUrl = "https://portal.azure.com/#@${tenant}/resource${id}/overview"
		
		[void]$finalOutputText.AppendLine($outputText)
		[void]$finalOutputUrls.AppendLine($outputUrl)

		Write-Output $outputText.toString()
	}
	Write-Output ""
	Write-Output ""
}

Set-Content -Path $resultFile -Value $finalOutputText.toString()
Add-Content -Path $resultFile -Value "`r`n`r`n"
Add-Content -Path $resultFile -Value $finalOutputUrls.toString()
Add-Content -Path $resultFile -Value "`r`n`r`n"
Add-Content -Path $resultFile -Value "*Accessible as service endpoint means available on a public endpoint reachable from specific VNets only"
Add-Content -Path $resultFile -Value "**Flexible PostgreSQL servers always enforce SSL and a minimum TLS version of 1.2"
Add-Content -Path $resultFile -Value "***flexible PostgreSQL servers cannot combine VNet integration (private/service endpoints) with public access (i.e. only one or the other at a time)"

Write-Output "Results successfully exported to: $resultFile"

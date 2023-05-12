#### Description ####################################################
#
# Indexes all the SQL Servers in an Azure environment and shows the following information:
# • Whether the server is publicly accessible and from what IP addresses
# • Whether the server is accessible from the Azure backbone
# • Whether the server is available in a VNet as a Service endpoint
#
# Note: by default, public IPs allowed to connect to a SQL server need to be specified explicitly, even though "Deny Public Network Access" is set to "No"
# More info: https://techcommunity.microsoft.com/t5/azure-database-support-blog/lesson-learned-126-deny-public-network-access-allow-azure/ba-p/1244037
#
# Note: due to its recent addition to SQL servers, retrieving the minimum required TLS version via Powershell is currently not possible
# More info: https://azure.microsoft.com/en-us/updates/sqldb-minimal-tls-version/#:~:text=We%20recommend%20setting%20the%20minimal,supported%20in%20Azure%20SQL%20Database.
#
####

$path = "C:\Users\$env:UserName\Downloads\"
$file = "_open-SQLServers.txt" 
$date = (Get-Date -UFormat "%Y-%m-%d")
$resultFile = "${path}${date}${file}"
$finalOutputText = [System.Text.StringBuilder]::new()
$finalOutputUrls = [System.Text.StringBuilder]::new()

if (!(test-path $path )) { New-Item -ItemType Directory -Force -Path $path }

$subscriptions = (Get-AzureRmSubscription).Id | sort | Get-Unique

foreach ($subscription in $subscriptions) {
	Select-AzureRmSubscription -Subscription $subscription

	$tenant = (Get-AzureRmSubscription -SubscriptionId $subscription).TenantId
	$servers = Get-AzureRmResource -ResourceType "Microsoft.Sql/servers" 

	foreach ($server in $servers) {
		$rg = $server.ResourceGroupName
		$name = $server.Name
		$id = $server.ResourceId

		$fqdn = (Get-AzureRmSqlServer -ResourceGroupName $rg -Name $name).FullyQualifiedDomainName
		$server = (Get-AzureRmResource -ResourceType "Microsoft.Sql/servers" -ResourceGroupName $rg -Name $name)
		$hasPublicNetworkAccess = if ($server.Properties.publicNetworkAccess -eq "Enabled") {$true} elseif ($server.Properties.publicNetworkAccess -eq "Disabled") {$false} else {"Undetermined"}

		$privateEndpoints = $server.Properties.privateEndpointConnections
		$firewallRules = (Get-AzureRmSqlServerFirewallRule -ResourceGroupName $rg -ServerName $name)
		$vnetRules = (Get-AzureRmSqlServerVirtualNetworkRule -ResourceGroupName $rg -ServerName $name)

		$outputText = [System.Text.StringBuilder]::new()
		[void]$outputText.AppendLine($fqdn)		

		$allowsExternalAccess = $false
		$allowsAzureBackboneAccess = $false
		$hasServiceEndpoint = $false

		# Note: Allowing Public Network Access without specifying a list of explicity allowed IP addresses denies all external/Azure backbone connections 
		if ($firewallRules) {			
			foreach ($firewallRule in $firewallRules) {
				$ruleName = $firewallRule.FirewallRuleName
				$ruleStartIp = $firewallRule.StartIpAddress
				$ruleEndIp = $firewallRule.EndIpAddress

				if ($ruleName -eq "AllowAllWindowsAzureIps") {
					# Allow Azure services, but deny Public Network Access disallows external connections and those from the Azure backbone (i.e. only Private Links are allowed)
					$allowsAzureBackboneAccess = $true
				} else {
					$allowsExternalAccess = $true
					[void]$outputText.AppendLine("Accessible externally from: $ruleStartIp - $ruleEndIp (rule name: $ruleName)")
				}
			}

			[void]$outputText.AppendLine("Public Network Access: $hasPublicNetworkAccess")

			if ($allowsAzureBackboneAccess) {
				[void]$outputText.AppendLine("Accessible from the Azure backbone: True")
			} else {
				[void]$outputText.AppendLine("Accessible from the Azure backbone: False")
			}	
		} 

		if (-not $allowsExternalAccess) {
			# There are no explicit Firewall rules for non-Azure backbone access
			[void]$outputText.AppendLine("Accessible externally: False (no external IP explicitly allowed)")
		}

		if ($vnetRules) {
			$hasServiceEndpoint = $true
			$vnets = @()

			foreach ($vnetRule in $vnetRules) {
				$vnetName = $vnetRule.VirtualNetworkSubnetId.split("/")[-3]
				$vnets += $vnetName	
			}
		}

		if ($hasServiceEndpoint) {
			[void]$outputText.AppendLine("Available as Service endpoint in VNets: " + ($vnets | Get-Unique))
		} else {
			[void]$outputText.AppendLine("Available as Service endpoint: False")
		}

		$outputUrl = "https://portal.azure.com/#@${tenant}/resource${id}/overview"
		
		[void]$finalOutputText.AppendLine($outputText)
		[void]$finalOutputText.AppendLine("")
		[void]$finalOutputUrls.AppendLine($outputUrl)

		Write-Output $outputText.toString()
	}
	Write-Output ""
	Write-Output ""
}

Set-Content -Path $resultFile -Value $finalOutputText.toString()
Add-Content -Path $resultFile -Value "`r`n`r`n"
Add-Content -Path $resultFile -Value $finalOutputUrls.toString()

Write-Output "Results successfully exported to: $resultFile"

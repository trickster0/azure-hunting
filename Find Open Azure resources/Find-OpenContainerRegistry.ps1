#### Description ####################################################
#
# Indexes all the Container Registries in an Azure environment and shows the following information:
# • Whether an Admin user is enabled
# • Whether the Registry's Content Trust policy is enabled
# • Whether the Registry's Retention policy is enabled and for how many days
# • Whether network access to the Registry is restricted 
#
####

$path = "C:\Users\$env:UserName\Downloads\"
$file = "_open-ContainerRegistries.txt" 
$date = (Get-Date -UFormat "%Y-%m-%d")
$resultFile = "${path}${date}${file}"
$finalOutputText = [System.Text.StringBuilder]::new()
$finalOutputUrls = [System.Text.StringBuilder]::new()

if (!(test-path $path )) { New-Item -ItemType Directory -Force -Path $path }

$subscriptions = (Get-AzureRmSubscription).Id | sort | Get-Unique

foreach ($subscription in $subscriptions) {
	Select-AzureRmSubscription -Subscription $subscription

	$tenant = (Get-AzureRmSubscription -SubscriptionId $subscription).TenantId
	$registries = Get-AzureRmResource -ResourceType "Microsoft.ContainerRegistry/registries" 

	foreach ($registry in $registries) {
		$rg = $registry.ResourceGroupName
		$name = $registry.Name
		$id = $registry.ResourceId

		$registry = (Get-AzureRmResource -ResourceType "Microsoft.ContainerRegistry/registries" -ResourceGroupName $rg -Name $name)

		$loginServer = $registry.Properties.loginServer
		$hasAdminUser = $registry.Properties.adminUserEnabled
		$hasTrustPolicy = if ($registry.Properties.policies.trustPolicy.status -eq "disabled") {$false} else {$true}
		$hasRetentionPolicy = if ($registry.Properties.policies.retentionPolicy.status -eq "disabled") {$false} else {$true}

		$defaultAction = $registry.Properties.networkRuleSet.defaultAction
		$virtualNetworkRules = $registry.Properties.networkRuleSet.virtualNetworkRules
	
		$outputText = [System.Text.StringBuilder]::new()
		[void]$outputText.Append("$loginServer - Admin user: $hasAdminUser; Trust Policy: $hasTrustPolicy")

		if ($hasRetentionPolicy) {
			$retentionPeriod = $registry.Properties.policies.retentionPolicy.days
			[void]$outputText.Append("; Retention Policy: True; Retention period: $retentionPeriod days")
		} else {
			[void]$outputText.Append("; Retention Policy: False")
		}

		if ($defaultAction -eq "Allow") {
			[void]$outputText.Append("; Public network access: All networks (unrestricted)")
		} else {
			# Deny
			[void]$outputText.Append("; Public network access: Selected networks")

			if ($virtualNetworkRules) {
				[void]$outputText.Append("; Accessible on private endpoint: True")
			} else {
				[void]$outputText.Append("; Accessible on private endpoint: False")
			}
		}
		
		$outputUrl = "https://portal.azure.com/#@${tenant}/resource${id}/overview"
		
		[void]$finalOutputText.AppendLine($outputText)
		[void]$finalOutputUrls.AppendLine($outputUrl)

		Write-Output "$outputText"
	}
	Write-Output ""
	Write-Output ""
}

Set-Content -Path $resultFile -Value $finalOutputText.toString()
Add-Content -Path $resultFile -Value "`r`n`r`n"
Add-Content -Path $resultFile -Value $finalOutputUrls.toString()

Write-Output "Results successfully exported to: $resultFile"

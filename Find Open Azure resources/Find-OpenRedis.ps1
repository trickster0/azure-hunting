#### Description ####################################################
#
# Indexes all the Redis Databases in an Azure environment and shows the following information:
# • Whether the database allows non-SSL connections on port 6379 instead of 6380
# • The minimum TLS version required
# • Whether the database is located in a Vnet
# • Whether the database has a firewall
#
# Note: a database that is neither in a Vnet, nor protected by a firewall can be accessed from the public Internet
# 
####

$path = "C:\Users\$env:UserName\Downloads\"
$file = "_open-Redis.txt" 
$date = (Get-Date -UFormat "%Y-%m-%d")
$resultFile = "${path}${date}${file}"
$finalOutputText = [System.Text.StringBuilder]::new()
$finalOutputUrls = [System.Text.StringBuilder]::new()

if (!(test-path $path )) { New-Item -ItemType Directory -Force -Path $path }

$subscriptions = (Get-AzureRmSubscription).Id | sort | Get-Unique

foreach ($subscription in $subscriptions) {
	Select-AzureRmSubscription -Subscription $subscription

	$tenant = (Get-AzureRmSubscription -SubscriptionId $subscription).TenantId
	$dbs = Get-AzureRmResource -ResourceType "Microsoft.Cache/Redis" 

	foreach ($db in $dbs) {
		$rg = $db.ResourceGroupName
		$name = $db.Name
		$id = $db.Id

		$db = (Get-AzureRmRedisCache -ResourceGroupName $rg -Name $name)
		$hostname = $db.Hostname
		$allowsNonSsl = $db.EnableNonSslPort
		$minimumTlsVersion = $db.MinimumTlsVersion
		$subnet = $db.SubnetId
		$firewallRule = (Get-AzureRmRedisCacheFirewallRule -ResourceGroupName $rg -Name $name)

		$outputText = "$hostname - Allows non SSL: $allowsNonSsl ; Minimum TLS version: $minimumTlsVersion"

		if ($subnet) {
			$outputText += " ; Is in Vnet: False"
		} else {
			$outputText += " ; Is in Vnet: True"
		}

		if (-not $firewallRule) {
			$outputText += " ; Has firewall: False"
		} else {
			$outputText += " ; Has firewall: True"
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

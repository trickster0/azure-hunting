#### Description ####################################################
#
# Indexes all the Cosmos Databases in an Azure environment and shows the following information:
# • Whether the database is located in a Vnet
# • Whether the database has a firewall
#
# Note: a database that is neither in a Vnet, nor protected by a firewall can be accessed from the public Internet
# 
####

$path = "C:\Users\$env:UserName\Downloads\"
$file = "_open-Cosmos.txt" 
$date = (Get-Date -UFormat "%Y-%m-%d")
$resultFile = "${path}${date}${file}"
$finalOutputText = [System.Text.StringBuilder]::new()
$finalOutputUrls = [System.Text.StringBuilder]::new()

if (!(test-path $path )) { New-Item -ItemType Directory -Force -Path $path }

$subscriptions = (Get-AzureRmSubscription).Id | sort | Get-Unique

foreach ($subscription in $subscriptions) {
	Select-AzureRmSubscription -Subscription $subscription

	$tenant = (Get-AzureRmSubscription -SubscriptionId $subscription).TenantId
	$dbs = Get-AzureRmResource -ResourceType "Microsoft.DocumentDB/databaseAccounts" 

	foreach ($db in $dbs) {
		$rg = $db.ResourceGroupName
		$name = $db.Name
		$id = $db.ResourceId

		$db = (Get-AzureRmResource -ResourceType "Microsoft.DocumentDB/databaseAccounts" -ResourceGroupName $rg -Name $name)
		$endpoint = $db.Properties.documentEndpoint
		$vnetRules = $db.virtualNetworkRules
		$ipRules = $db.ipRules

		$outputText = "$endpoint - "

		if ($vnetRules.count -eq 0) {
			$outputText += "Is in Vnet: False"
		} else {
			$outputText += "Is in Vnet: True"
		}

		if ($ipRules.count -eq 0) {
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

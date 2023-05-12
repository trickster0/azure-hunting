#### Description ####################################################
#
# Indexes all the SQL Managed instances with a public endpoint in an Azure environment.
#
# Note: due to the sensitivity of the data usually stored on a managed instance, an open public endpoint is most likely restricted to a list of whitelisted IP addresses in the instance's attached NSG
# 
####

$path = "C:\Users\$env:UserName\Downloads\"
$file = "_open-SQLManagedInstances.txt" 
$date = (Get-Date -UFormat "%Y-%m-%d")
$resultFile = "${path}${date}${file}"
$finalOutputText = [System.Text.StringBuilder]::new()
$finalOutputUrls = [System.Text.StringBuilder]::new()

if (!(test-path $path )) { New-Item -ItemType Directory -Force -Path $path }

$subscriptions = (Get-AzureRmSubscription).Id | sort | Get-Unique

foreach ($subscription in $subscriptions) {
	Select-AzureRmSubscription -Subscription $subscription

	$tenant = (Get-AzureRmSubscription -SubscriptionId $subscription).TenantId
	$instances = Get-AzureRmResource -ResourceType "Microsoft.Sql/managedInstances" 

	foreach ($instance in $instances) {
		$rg = $instance.ResourceGroupName
		$name = $instance.Name
		$id = $instance.ResourceId

		$instance = (Get-AzureRmSqlInstance -ResourceGroupName $rg -Name $name)
		$fqdn = $instance.FullyQualifiedDomainName
		$hasPublicEndpoint = $instance.PublicDataEndpointEnabled

		if ($hasPublicEndpoint) {
			$outputText = "$fqdn is publicly reachable (most likely only from a whitelisted list of IP addresses - check its attached NSG!)"
			$outputUrl = "https://portal.azure.com/#@${tenant}/resource${id}/overview"

			[void]$finalOutputText.AppendLine($outputText)
			[void]$finalOutputUrls.AppendLine($outputUrl)

			Write-Output "$outputText"			
		}
	}
	Write-Output ""
	Write-Output ""
}

Set-Content -Path $resultFile -Value $finalOutputText.toString()
Add-Content -Path $resultFile -Value "`r`n`r`n"
Add-Content -Path $resultFile -Value $finalOutputUrls.toString()

Write-Output "Results successfully exported to: $resultFile"

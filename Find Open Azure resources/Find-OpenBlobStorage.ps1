#### Description ####################################################
#
# Indexes all the Storage Accounts in an Azure environment and shows the following information:
# • Whether secure transfer (HTTPS) is required for the Storage Account
# • The minimum TLS version required
# • Whether network access to the Storage Account is restricted
# • Whether the Storage Account uses Blob service, showing containers and/or blobs with anonymous access if any
# • Whether the Storage Account is used for Cloud Shell or likely to
# 
####

$path = "C:\Users\$env:UserName\Downloads\"
$file = "_open-Blobs.txt" 
$date = (Get-Date -UFormat "%Y-%m-%d")
$resultFile = "${path}${date}${file}"
$finalOutputText = [System.Text.StringBuilder]::new()
$finalOutputUrls = [System.Text.StringBuilder]::new()

if (!(test-path $path )) { New-Item -ItemType Directory -Force -Path $path }

$csDefaultNameRegex = '^cs-[{]?[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}[}]?$'
$csShellInNameRegex = '.*(cs|shell).*'
$subscriptions = (Get-AzureRmSubscription).Id | sort | Get-Unique

foreach ($subscription in $subscriptions) {
	Select-AzureRmSubscription -SubscriptionName $subscription

	$tenant = (Get-AzureRmSubscription -SubscriptionId $subscription).TenantId
	$storage_accounts = Get-AzureRmResource -ResourceType "Microsoft.Storage/storageAccounts" 

	foreach ($storage_account in $storage_accounts) {
		$rg = $storage_account.ResourceGroupName
		$name = $storage_account.Name
		$id = $storage_account.ResourceId

		$storage_account = (Get-AzureRmResource -ResourceType "Microsoft.Storage/storageAccounts" -ResourceGroupName $rg -Name $name)
		$containers = (Get-AzureRmStorageContainer -ResourceGroupName $rg -StorageAccountName $name)
		$fileShares = (Get-AzRmStorageShare -ResourceGroupName $rg -StorageAccountName $name)

		$minimumTlsVersion = $storage_account.Properties.minimumTlsVersion
		$httpsOnly = $storage_account.Properties.supportsHttpsTrafficOnly

		$networkRuleSet = (Get-AzureRmStorageAccountNetworkRuleSet -ResourceGroupName $rg -Name $name)
		$defaultAction = $networkRuleSet.DefaultAction

		$outputText = [System.Text.StringBuilder]::new()
		[void]$outputText.Append("$name - Secure transfer required: $httpsOnly; Minimum TLS version: $minimumTlsVersion")

		if ($defaultAction -eq "Allow") {
			[void]$outputText.Append("; Allows access from: All networks (unrestricted)")
		} else {
			# Deny
			[void]$outputText.Append("; Allows access from: Selected networks")
		}

		if ($containers) {
			[void]$outputText.Append("; Uses Blob Service: True")

			foreach ($container in $containers) {
				if ($container.PublicAccess -ne "None") {
					# Anonymous public read access is allowed (either at the container or blob level)
					$isContainerPublic = $true
					$containerName = $container.Name
					$publicAccess = $container.PublicAccess
					[void]$outputText.Append("; Container name: $containerName, Public access level: $publicAccess")
				}
			}
		} else {
			[void]$outputText.Append("; Uses Blob Service: False")
		}

		if ($name -match $csDefaultNameRegex) {
			[void]$outputText.Append("; Used for Cloud Shell: True (certain)")
		} elseif ($fileShares -and $name -match $csShellInNameRegex) {
			[void]$outputText.Append("; Used for Cloud Shell: True (uncertain)")
		} else {
			[void]$outputText.Append("; Used for Cloud Shell: False")
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

#### Description ####################################################
#
# Indexes all the Key Vaults in an Azure environment and shows the following information:
# • Whether RBAC authorization to the data plane is enabled (Vault access policies are ignored in that case)
# • Whether network access to the Key Vault is restricted
# • Whether the Key Vault is available as a Service endpoint (reachable from certain Azure services on a PUBLIC endpoint)
#
# Note: Key Vaults accessible as Service endpoints might be accessible from Azure VMs (needs to be verified!)
# More info: https://docs.microsoft.com/en-us/azure/key-vault/general/overview-vnet-service-endpoints#trusted-services
#
# Note: from January 2021, disabling Soft delete on Key Vaults will not be possible and enforced by Microsoft (no need to check for that anymore)
# More info: https://docs.microsoft.com/en-us/azure/key-vault/general/soft-delete-change
#
####

$path = "C:\Users\$env:UserName\Downloads\"
$file = "_open-Vaults.txt" 
$date = (Get-Date -UFormat "%Y-%m-%d")
$resultFile = "${path}${date}${file}"
$finalOutputText = [System.Text.StringBuilder]::new()
$finalOutputUrls = [System.Text.StringBuilder]::new()

if (!(test-path $path )) { New-Item -ItemType Directory -Force -Path $path }

$subscriptions = (Get-AzureRmSubscription).Id | sort | Get-Unique

foreach ($subscription in $subscriptions) {
	Select-AzureRmSubscription -Subscription $subscription

	$tenant = (Get-AzureRmSubscription -SubscriptionId $subscription).TenantId
	$vaults = Get-AzureRmResource -ResourceType "Microsoft.KeyVault/vaults" 

	foreach ($vault in $vaults) {
		$rg = $vault.ResourceGroupName
		$name = $vault.Name
		$id = $vault.ResourceId

		$vault = (Get-AzureRmKeyVault -ResourceGroupName $rg -Name $name)
		$networkRuleSet = $vault.NetworkAcls
		$defaultAction = $networkRuleSet.DefaultAction
		$bypass = $networkRuleSet.Bypass

		$vault = (Get-AzureRmResource -ResourceType "Microsoft.KeyVault/vaults" -ResourceGroupName $rg -Name $name)
		$hasRbacAuth = $vault.Properties.enableRbacAuthorization
		$url = $vault.Properties.vaultUri

		$outputText = [System.Text.StringBuilder]::new()

		if ($hasRbacAuth) {
			[void]$outputText.Append("$url - Data plane authorization: Azure RBAC")
		} else {
			[void]$outputText.Append("$url - Data plane authorization: Vault access policies")
		}

		if ($defaultAction -eq "Allow") {
			[void]$outputText.Append("; Allows access from: All networks (unrestricted)")
		} else {
			# Deny
			[void]$outputText.Append("; Allows access from: Selected networks")

			if ($bypass -eq "AzureServices") {
				[void]$outputText.Append("; Accessible as service endpoint: True")
			} else {
				[void]$outputText.Append("; Accessible as service endpoint: False")
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

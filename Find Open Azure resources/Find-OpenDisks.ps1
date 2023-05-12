#### Description ####################################################
#
# Indexes all the Disks in an Azure environment and shows the following information:
# • The Disk's encryption method at rest (single encryption with a built-in platform key, single encryption with a customer key, double encryption with platform and customer key)
# • The Disk's state (attached, reserved, unattached)
# • Whether the Disk allows public network access for imports/exports
# • The Disk network access policy
#
####

$path = "C:\Users\$env:UserName\Downloads\"
$file = "_open-Disks.txt" 
$date = (Get-Date -UFormat "%Y-%m-%d")
$resultFile = "${path}${date}${file}"
$finalOutputText = [System.Text.StringBuilder]::new()
$finalOutputUrls = [System.Text.StringBuilder]::new()

if (!(test-path $path )) { New-Item -ItemType Directory -Force -Path $path }

$subscriptions = (Get-AzureRmSubscription).Id | sort | Get-Unique

foreach ($subscription in $subscriptions) {
	Select-AzureRmSubscription -Subscription $subscription

	$tenant = (Get-AzureRmSubscription -SubscriptionId $subscription).TenantId
	$disks = Get-AzureRmResource -ResourceType "Microsoft.Compute/disks" 

	foreach ($disk in $disks) {
		$rg = $disk.ResourceGroupName
		$name = $disk.Name
		$id = $disk.ResourceId

		$disk = (Get-AzureRmResource -ResourceType "Microsoft.Compute/disks" -ResourceGroupName $rg -Name $name)
		$encryption = if ($disk.Properties.encryption.type -eq "EncryptionAtRestWithPlatformKey") {"single (platform key)"} elseif ($disk.Properties.encryption.type -eq "EncryptionAtRestWithCustomerKey") {"single (customer key)"} else {"double (platform and customer"}	
		$diskState = $disk.Properties.diskState
		$publicNetworkAccess = $disk.Properties.publicNetworkAccess
		$networkAccessPolicy = $disk.Properties.networkAccessPolicy
		
		$outputText = [System.Text.StringBuilder]::new()
		[void]$outputText.Append("$name - Encryption type: $encryption; State: $diskState; Public network access: $publicNetworkAccess; Network access policy: $networkAccessPolicy")
	
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

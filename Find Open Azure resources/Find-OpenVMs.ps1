#### Description ####################################################
#
# Indexes all the VMs with a public IP in an Azure environment.
# 
####

$path = "C:\Users\$env:UserName\Downloads\"
$file = "_public-VMs.txt" 
$date = (Get-Date -UFormat "%Y-%m-%d")
$resultFile = "${path}${date}${file}"
$finalOutputText = [System.Text.StringBuilder]::new()
$finalOutputUrls = [System.Text.StringBuilder]::new()

if (!(test-path $path )) { New-Item -ItemType Directory -Force -Path $path }

$subscriptions = (Get-AzureRmSubscription).Id | sort | Get-Unique

foreach ($subscription in $subscriptions) {
	Select-AzureRmSubscription -Subscription $subscription

	$tenant = (Get-AzureRmSubscription -SubscriptionId $subscription).TenantId
	$vms = Get-AzureRmResource -ResourceType "Microsoft.Compute/virtualMachines" 

	foreach ($vm in $vms) {
		$rg = $vm.ResourceGroupName
		$name = $vm.Name

		$interfaces = (Get-AzureRmVM -ResourceGroupName $rg -Name $name).NetworkProfile.NetworkInterfaces
	
		foreach ($interface in $interfaces) {
			$publicIp = (Get-AzureRmNetworkInterface | where {$_.Id -eq $interface.Id}).IpConfigurations.PublicIpAddress.Id

			if ($publicIp) {
				$publicIpAddress = (Get-AzureRmPublicIpAddress -Name $publicIp.split("/")[-1]).IpAddress
				$nicId = $interface.Id
				$nicName = $nicId.split('/')[-1]

				$outputText = "$name is publicly reachabled at $publicIpAddress (nic: $nicName)"
				$outputUrl = "https://portal.azure.com/#@${tenant}/resource${nicId}/overview"

				[void]$finalOutputText.AppendLine($outputText)
				[void]$finalOutputUrls.AppendLine($outputUrl)

				Write-Output "$outputText"
			}
		}		
	}
	Write-Output ""
	Write-Output ""
}

Set-Content -Path $resultFile -Value $finalOutputText.toString()
Add-Content -Path $resultFile -Value "`r`n`r`n"
Add-Content -Path $resultFile -Value $finalOutputUrls.toString()

Write-Output "Results successfully exported to: $resultFile"

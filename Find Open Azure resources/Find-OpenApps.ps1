#### Description #################################################################################
#
# Indexes the URLs of all the App Services in an Azure environment (including Function Apps) and shows whether they are:
# • Public with default content
# • Public with custom content
# • Private
# • Unreachable
#  
####

$path = "C:\Users\$env:UserName\Downloads\"
$file = "_open-Apps.txt" 
$date = (Get-Date -UFormat "%Y-%m-%d")
$resultFile = "${path}${date}${file}"
$finalOutputText = [System.Text.StringBuilder]::new()
$finalOutputUrls = [System.Text.StringBuilder]::new()

if (!(test-path $path )) { New-Item -ItemType Directory -Force -Path $path }

$subscriptions = (Get-AzureRmSubscription).Id | sort | Get-Unique

foreach ($subscription in $subscriptions) {
    Select-AzureRmSubscription -Subscription $subscription
    
    $tenant = (Get-AzureRmSubscription -SubscriptionId $subscription).TenantId
	$webApps = (Get-AzureRmResource -ResourceType "Microsoft.Web/sites")

	foreach ($webApp in $webApps) {
		$rg = $webApp.ResourceGroupName
		$name = $webApp.Name
        $id = $webApp.ResourceId
        $request = ""
        
        $url = (Get-AzureRmWebApp -ResourceGroupName $rg -Name $name).DefaultHostName
        
		try {
            $request = Invoke-WebRequest $url 
        } 
		catch { 
			$statusCode = $_.Exception.Response.StatusCode.Value__
			
			if ($statusCode -eq "403") {
				$outputText = "$url is private"
			} elseif ($statusCode -eq "404") {
				$outputText = "$url cannot be found (404)"
			}
			else {
				$outputText = "$url is undetermined (private|public with default content|public with custom content)"
			}
		}

		$statusCode = $request.statusCode
		$content = $request.content

        $defaultContent = @(
            "<title>Your Azure Function App is up and running.</title>"
            "<h2>Hey, Node developers!</h2>"           
        )  

        if ($statusCode -eq "200") {
            $contentType = "default"

            foreach ($dContent in $defaultContent) {
                if ($content.Contains($dContent)) {
                    $contentType = "default"
                    break
                } else {
                    $contentType = "custom"
                }
            }

            $outputText = "$url is public with $contentType content"
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

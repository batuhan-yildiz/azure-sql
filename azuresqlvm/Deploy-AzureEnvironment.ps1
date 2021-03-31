

# Main Code

Set-Item -Path Env:\SuppressAzurePowerShellBreakingChangeWarnings -Value $true

$resourceGroup = "azure-data-rg01"

$check = Get-AzContext -ErrorAction SilentlyContinue
if ($null -eq $check) 
{
    Connect-AzAccount -SubscriptionId $subscriptionId | out-null
}
else {
    Set-AzContext -SubscriptionId $subscriptionId | out-null
}
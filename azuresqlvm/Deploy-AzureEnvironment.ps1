# Connect to Azure Subscription
# Create a new Resource Group
# Create a new Virtual Network with 3 subnets

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$subscriptionId,
    [Parameter(Mandatory = $true)]
    [string]$resourceGroup = "azure-data-rg01",
    [Parameter(Mandatory = $true)]
    [string]$location = "westus2"
)
function NewMessage 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$message,
        [Parameter(Mandatory = $true)]
        [string]$type
    )
    if ($type -eq "success") {
        write-host $message -ForegroundColor Green
    }
    elseif ($type -eq "information") {
        write-host $message -ForegroundColor Yellow
    }
    elseif ($type -eq "error") {
        write-host $message -ForegroundColor Red
    }
    else {
        write-host "You need to pass message type as success/warning/error."
        Exit
    }
}

# Connect to Azure Subscription
function ConnectToAzure 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$subscriptionId
    )

    try {
        $check = Get-AzContext -ErrorAction SilentlyContinue
        if ($null -eq $check) {
            Connect-AzAccount -SubscriptionId $subscriptionId | out-null
        }
        else {
            Set-AzContext -SubscriptionId $subscriptionId | out-null
        }
    }
    catch {
        Write-Warning "Error occured = " $Error[0]
        Exit
    }

}

# Create a new Resource Group
function NewResourceGroup 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$location,
        [Parameter(Mandatory = $true)]
        [string]$resourceGroup
    )
    try {
            $message = ""
            $check = Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue
            if ($null -eq $check) {
                New-AzResourceGroup -Name $resourceGroup -Location $location -ErrorAction SilentlyContinue  | out-null
                
                $message = $resourceGroup + " resource group has been created."
                NewMessage -message $message -type "success"
            }
            else {
                $message = $resourceGroup + " resource group already exists." 
                NewMessage -message $message -type "information"    
            }
    }
    catch {
        Write-Warning "Error occured = " $Error[0]
    }

}

# Create a new Virtual Network
function NewVirtualNetwork 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$resourceGroup,
        [Parameter(Mandatory = $true)]
        [string]$location,
        [Parameter(Mandatory = $true)]
        [string]$subnet0_name,
        [Parameter(Mandatory = $true)]
        [string]$subnet0_addressRange,
        [Parameter()]
        [string]$subnet1_name,
        [Parameter()]
        [string]$subnet1_addressRange,
        [Parameter()]
        [string]$subnetBastion_name,
        [Parameter()]
        [string]$subnetBastion_addressRange,
        [Parameter(Mandatory = $true)]
        [string]$virtualNetworkName,
        [Parameter(Mandatory = $true)]
        [string]$addressSpaces,
        [Parameter(Mandatory = $true)]
        [string]$dnsIPAddress
    )

    try {
            $message = ""
            $check = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue
            if ($null -eq $check) {
                # Create Frontend Subnet
                $Params = @{
                    Name = $subnet0_name
                    AddressPrefix = $subnet0_addressRange
                }
                $subnet0 = New-AzVirtualNetworkSubnetConfig @Params -ErrorAction SilentlyContinue
                
                # Create Backend Subnet
                $Params = @{
                    Name = $subnet1_name
                    AddressPrefix = $subnet1_addressRange
                }
                $subnet1  = New-AzVirtualNetworkSubnetConfig @Params -ErrorAction SilentlyContinue

                # Create Bastion Subnet
                $Params = @{
                    Name = $subnetBastion_name
                    AddressPrefix = $subnetBastion_addressRange
                }
                $bastionSubnet  = New-AzVirtualNetworkSubnetConfig @Params -ErrorAction SilentlyContinue

                # Create Virtual Network
                $Params = @{
                    Name = $virtualNetworkName
                    ResourceGroupName = $resourceGroup
                    Location = $location
                    AddressPrefix = $addressSpaces
                    DnsServer = $dnsIPAddress
                    Subnet = $subnet0,$subnet1,$bastionSubnet
                }
                New-AzVirtualNetwork @Params -ErrorAction SilentlyContinue | out-null

                $message = $virtualNetworkName + " virtual network has been created."
                NewMessage -message $message -type "success"
            }
            else {
                $message = $virtualNetworkName + " virtual network already exists." 
                NewMessage -message $message -type "information"    
            }
    }
    catch {
        Write-Warning "Error occured = " $Error[0]
    }

}

# Main Code

Set-Item -Path Env:\SuppressAzurePowerShellBreakingChangeWarnings -Value $true

# Connect to Azure Subscription
ConnectToAzure -subscriptionId $subscriptionId

# Create a new Resource Group
$NewResourceGroupParams = @{
    location = $location
    resourceGroup = $resourceGroup
}
NewResourceGroup @NewResourceGroupParams

# Create a new Virtual Network with 3 subnets
$NewVirtualNetworkParams = @{
    resourceGroup = $resourceGroup
    location  = $location
    subnet0_name = "frontend"
    subnet0_addressRange = "10.10.20.0/24"
    subnet1_name = "backend"
    subnet1_addressRange = "10.10.21.0/25"
    subnetBastion_name = "AzureBastionSubnet" # This subnet is required for Bastion connection to Azure VM
    subnetBastion_addressRange = "10.10.21.128/27"
    virtualNetworkName = "VNet"
    addressSpaces = "10.10.20.0/23"
    dnsIPAddress = "10.10.21.10" # Set private IP address (privateIPAddress) of Domain Controller
}
NewVirtualNetwork @NewVirtualNetworkParams
# Connect to Azure Subscription
# Enable Firewall Rule
# Install Active Directory Domain Services
# Create a new Active Directory Organization Unit and make it default for computer objects

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$subscriptionId,
    [string]$resourceGroup = "azure-data-rg01",
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

# Enable Firewall Rule
function EnableFirewallRule 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$vmName,
        [Parameter(Mandatory = $true)]
        [string]$resourceGroup
    )
    try {
            # Create a temporary file in the users TEMP directory
            $file = $env:TEMP + "\FirewallRule.ps1"

            $commands = "Enable-NetFirewallRule -DisplayName ""File and Printer Sharing (Echo Request - ICMPv4-In)"""
            $commands | Out-File -FilePath $file -force

            $result = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup -VMName $vmName -CommandId "RunPowerShellScript" -ScriptPath $file

            if ($result.Status -eq "Succeeded") {
                $message = "Firewall rule has been enabled on $vmName."
                NewMessage -message $message -type "success"
            }
            else {
                $message = "Firewall rule couldn't be enabled on $vmName."
                NewMessage -message $message -type "error"
            }

            Remove-Item $file
    }
    catch {
        Remove-Item $file
        Write-Warning "Error occured = " $Error[0]
    }
}

# Install Active Directory Domain Services
function InstallADDS 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$vmName,
        [Parameter(Mandatory = $true)]
        [string]$resourceGroup,
        [Parameter(Mandatory = $true)]
        [string]$adminPassword
    )
    try {
            # Create a temporary file in the users TEMP directory
            $file = $env:TEMP + "\ADDS.ps1"

            $commands = "`$SecurePassword = ConvertTo-SecureString ""$adminPassword"" -AsPlainText -Force" + "`r`n"
            $commands = $commands + "`r`n"
            $commands = $commands + "#Install AD DS feature" + "`r`n"
            $commands = $commands + "Install-WindowsFeature AD-Domain-Services -IncludeManagementTools" + "`r`n"
            $commands = $commands + "`r`n"
            $commands = $commands + "#AD DS Deployment" + "`r`n"
            $commands = $commands + "Import-Module ADDSDeployment" + "`r`n"
            $commands = $commands + "Install-ADDSForest ``" + "`r`n"
            $commands = $commands + "-CreateDnsDelegation:`$false ``" + "`r`n"
            $commands = $commands + "-DatabasePath ""C:\Windows\NTDS"" ``" + "`r`n"
            $commands = $commands + "-DomainMode ""WinThreshold"" ``" + "`r`n"
            $commands = $commands + "-DomainName ""contoso.com"" ``" + "`r`n"
            $commands = $commands + "-DomainNetbiosName ""CONTOSO"" ``" + "`r`n"
            $commands = $commands + "-ForestMode ""WinThreshold"" ``" + "`r`n"
            $commands = $commands + "-InstallDns:`$true ``" + "`r`n"
            $commands = $commands + "-LogPath ""C:\Windows\NTDS"" ``" + "`r`n"
            $commands = $commands + "-NoRebootOnCompletion:`$true ``" + "`r`n"
            $commands = $commands + "-SafeModeAdministratorPassword `$SecurePassword ``" + "`r`n"
            $commands = $commands + "-SysvolPath ""C:\Windows\SYSVOL"" ``" + "`r`n"
            $commands = $commands + "-Force:`$true"
            $commands | Out-File -FilePath $file -force

            $result = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup -VMName $vmName -CommandId "RunPowerShellScript" -ScriptPath $file

            if ($result.Status -eq "Succeeded") {
                $message = "Active Directory has been enabled on $vmName."
                NewMessage -message $message -type "success"
            }
            else {
                $message = "Active Directory couldn't be enabled on $vmName."
                NewMessage -message $message -type "error"
            }

            Remove-Item $file
    }
    catch {
        Remove-Item $file
        Write-Warning "Error occured = " $Error[0]
    }
}    

# Create a new Active Directory Organization Unit and make it default for computer objects
function NewADOU 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$vmName,
        [Parameter(Mandatory = $true)]
        [string]$resourceGroup
    )
    try {
            # Create a temporary file in the users TEMP directory
            $file = $env:TEMP + "\ADDS.ps1"

            $commands = "#Create an OU and make it default computer objects OU" + "`r`n"
            $commands = $commands + "New-ADOrganizationalUnit -Name ""AlwaysOnOU"" -Path ""DC=CONTOSO,DC=COM""" + "`r`n"
            $commands = $commands + "redircmp ""OU=AlwaysOnOU,DC=CONTOSO,DC=COM"""
            $commands | Out-File -FilePath $file -force

            $result = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup -VMName $vmName -CommandId "RunPowerShellScript" -ScriptPath $file

            if ($result.Status -eq "Succeeded") {
                $message = "Active Directory Organization Unit has been created on $vmName."
                NewMessage -message $message -type "success"
            }
            else {
                $message = "Active Directory Organization Unit couldn't be created on $vmName."
                NewMessage -message $message -type "error"
            }

            Remove-Item $file
    }
    catch {
        Remove-Item $file
        Write-Warning "Error occured = " $Error[0]
    }
}    

# Main Code

# Connect to Azure Subscription
ConnectToAzure -subscriptionId $subscriptionId

# Enable Firewall Rule
#EnableFirewallRule -resourceGroup $resourceGroup -vmName "DCVM01" -ErrorAction SilentlyContinue
#EnableFirewallRule -resourceGroup $resourceGroup -vmName "AlwaysOnN1" -ErrorAction SilentlyContinue

# Install Active Directory Domain Services
#InstallADDS -resourceGroup $resourceGroup -vmName "DCVM01" -adminPassword "Microsoft123" -ErrorAction SilentlyContinue

# Create a new Active Directory Organization Unit and make it default for computer objects
#NewADOU -resourceGroup $resourceGroup -vmName "DCVM01" -ErrorAction SilentlyContinue

# Restart DCVM01 after AD Installation. It is not rebooted in InstallADDS because a new OU is created after install.
#Restart-AzVM -ResourceGroupName $resourceGroup -Name "DCVM01"




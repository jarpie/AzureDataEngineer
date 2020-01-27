# Set the location, resource group name, logical server name and database name for your server
$parameters1 = Import-Csv -Delimiter "," -Path .\input_file1.csv

$resourceGroupName = $parameters1.resourceGroupName
$location = $parameters1.Location
$serverName = $parameters1.serverName
$databaseName = $parameters1.databaseName

# Set an admin login and password for your server
$adminSqlLogin = Read-Host "Enter Username"
$password = Read-Host "Enter Password" -AsSecureString
$Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $password

# The ip address range that you want to allow to access your server
$myPubicIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
$startIp = "0.0.0.0"
$endIp = "0.0.0.0" 

# Create a resource group
$resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

# Create a server with a system wide unique server name
$server = New-AzureRmSqlServer -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $Credentials
    
# Create a server firewall rule that allows access from the specified IP range
$serverFirewallRule1 = New-AzureRmSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -FirewallRuleName "AllowedIPs1" -StartIpAddress $startIp -EndIpAddress $endIp

# Create a server firewall rule that allows access from user public IP
$serverFirewallRule2 = New-AzureRmSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -FirewallRuleName "MyPublicIP" -StartIpAddress $myPubicIP -EndIpAddress $myPubicIP

# Create a blank database with a Basic performance level
$database = New-AzureRmSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -RequestedServiceObjectiveName "Basic" `
    -SampleName "AdventureWorksLT"


# Set the location, resource group name, logical server name and database name for your server
$parameters2 = Import-Csv -Delimiter "," -Path .\input_file2.csv

$locationReplica = $parameters2.Location
$serverNameReplica = $parameters2.serverName

# Create a server with a system wide unique server name
$serverReplica = New-AzureRmSqlServer -ResourceGroupName $resourceGroupName `
    -ServerName $serverNameReplica `
    -Location $locationReplica `
    -SqlAdministratorCredentials $Credentials

# Create a server firewall rule that allows access from the specified IP range
$serverFirewallRule1Replica = New-AzureRmSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
    -ServerName $serverNameReplica `
    -FirewallRuleName "AllowedIPs1" -StartIpAddress $startIp -EndIpAddress $endIp

# Create a server firewall rule that allows access from user public IP
$serverFirewallRule2Replica = New-AzureRmSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
    -ServerName $serverNameReplica `
    -FirewallRuleName "MyPublicIP" -StartIpAddress $myPubicIP -EndIpAddress $myPubicIP

# Establish Active Geo-Replication
$databasegeo = Get-AzureRmSqlDatabase -DatabaseName $databaseName -ResourceGroupName $ResourceGroupName -ServerName $ServerName
$databasegeo | New-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName $resourceGroupName -PartnerServerName $serverNameReplica -AllowConnections "All"

# Clean up deployment 
# Remove-AzureRmResourceGroup -ResourceGroupName $resourceGroupName -Force

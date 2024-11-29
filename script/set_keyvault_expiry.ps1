param (
    [string]$SubscriptionName = "Alpha2phi", 
    [int]$YearsToAdd = 2                     
)

# Login to Azure
Connect-AzAccount

# Set the subscription context
Set-AzContext -SubscriptionName $SubscriptionName

# Get all Key Vaults in the subscription
$keyVaults = Get-AzKeyVault

# Define the expiration period (2 years)
$expirationDate = (Get-Date).AddYears($YearsToAdd)

# Loop through each Key Vault
foreach ($keyVault in $keyVaults) {
    Write-Host "Processing Key Vault: $($keyVault.VaultName)" -ForegroundColor Yellow
        
    # Set expiration for all keys in the Key Vault
    $keys = Get-AzKeyVaultKey -VaultName $keyVault.VaultName
    foreach ($key in $keys) {
        Write-Host "Setting expiration for key: $($key.Name)" -ForegroundColor Cyan
        Set-AzKeyVaultKey -VaultName $keyVault.VaultName -Name $key.Name -Expires $expirationDate
        Write-Host "Expiration date for key '$($key.Name)': $expirationDate" -ForegroundColor Green
    }

    # Set expiration for all secrets in the Key Vault
    $secrets = Get-AzKeyVaultSecret -VaultName $keyVault.VaultName
    foreach ($secret in $secrets) {
        Write-Host "Setting expiration for secret: $($secret.Name)" -ForegroundColor Cyan
        Set-AzKeyVaultSecret -VaultName $keyVault.VaultName -Name $secret.Name -Expires $expirationDate
        Write-Host "Expiration date for secret '$($secret.Name)': $expirationDate" -ForegroundColor Green
    }

    Write-Host "Completed processing Key Vault: $($keyVault.VaultName)" -ForegroundColor Green
}

Write-Host "All Key Vaults have been processed." -ForegroundColor Green

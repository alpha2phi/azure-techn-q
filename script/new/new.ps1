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

# Define the expiration period
$expirationDate = (Get-Date).AddYears($YearsToAdd)

# Function to set expiration dates for keys
function Set-KeyVaultKeyExpiry {
    param (
        [object]$KeyVault,
        [object]$Certificates,
        [datetime]$ExpirationDate
    )
    try {
        $keys = Get-AzKeyVaultKey -VaultName $KeyVault.VaultName
        foreach ($key in $keys) {
            if ($key.Enabled -eq $false) {
                Write-Host "Skipping disabled key: $($key.Name)`n" -ForegroundColor DarkYellow
                continue
            }

            $associatedCert = $null
            foreach ($cert in $Certificates) {
                $certDetails = Get-AzKeyVaultCertificate -VaultName $KeyVault.VaultName -Name $cert.Name
                $certKeyId = $certDetails.KeyId -replace "/[^/]+$", ""
                if ($certKeyId -like $key.Id) {
                    $associatedCert = $cert
                }
            }

            if ($associatedCert) {
                Write-Host "Key $($key.Name) is associated with a certificate '$($associatedCert.Name)'. Skipping..." -ForegroundColor Yellow
            } else {
                Write-Host "Setting expiration for key: $($key.Name) to $ExpirationDate" -ForegroundColor Cyan
                Set-AzKeyVaultKey -VaultName $KeyVault.VaultName -Name $key.Name -Expires $ExpirationDate
                Write-Host "Expiration date for key '$($key.Name)' set to: $ExpirationDate" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Error setting expiration for keys in Key Vault '$($KeyVault.VaultName)': $_" -ForegroundColor Red
    }
}

# Function to set expiration dates for secrets
function Set-KeyVaultSecretExpiry {
    param (
        [object]$KeyVault,
        [object]$Certificates,
        [datetime]$ExpirationDate
    )
    try {
        $secrets = Get-AzKeyVaultSecret -VaultName $KeyVault.VaultName
        foreach ($secret in $secrets) {
            if ($secret.Enabled -eq $false) {
                Write-Host "Skipping disabled secret: $($secret.Name)`n" -ForegroundColor DarkYellow
                continue
            }

            $associatedCert = $null
            foreach ($cert in $Certificates) {
                $certDetails = Get-AzKeyVaultCertificate -VaultName $KeyVault.VaultName -Name $cert.Name
                $certSecretId = $certDetails.SecretId -replace "/[^/]+$", ""
                if ($certSecretId -like $secret.Id) {
                    $associatedCert = $cert
                }
            }

            if ($associatedCert) {
                Write-Host "Secret $($secret.Name) is associated with a certificate '$($associatedCert.Name)'. Skipping..." -ForegroundColor Yellow
            } else {
                $currentSecret = Get-AzKeyVaultSecret -VaultName $KeyVault.VaultName -Name $secret.Name
                Write-Host "Setting expiration for secret: $($secret.Name) to $ExpirationDate" -ForegroundColor Cyan
                Set-AzKeyVaultSecret -VaultName $KeyVault.VaultName -Name $secret.Name -Expires $ExpirationDate -SecretValue $currentSecret.SecretValue -ContentType $currentSecret.ContentType -Tag $currentSecret.Tags -NotBefore $currentSecret.NotBefore
                Write-Host "Expiration date for secret '$($secret.Name)' set to: $ExpirationDate" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Error setting expiration for secrets in Key Vault '$($KeyVault.VaultName)': $_" -ForegroundColor Red
    }
}

# Process each Key Vault
foreach ($keyVault in $keyVaults) {
    Write-Host "Processing Key Vault: $($keyVault.VaultName)" -ForegroundColor Yellow

    # Get all certificates in the vault
    $certificates = Get-AzKeyVaultCertificate -VaultName $keyVault.VaultName

    # Call the functions to set expiration dates for keys and secrets
    Set-KeyVaultKeyExpiry -KeyVault $keyVault -Certificates $certificates -ExpirationDate $expirationDate
    Set-KeyVaultSecretExpiry -KeyVault $keyVault -Certificates $certificates -ExpirationDate $expirationDate

    Write-Host "`nCompleted processing Key Vault: $($keyVault.VaultName)" -ForegroundColor Green
}

Write-Host "All Key Vaults have been processed.`n`n" -ForegroundColor Green

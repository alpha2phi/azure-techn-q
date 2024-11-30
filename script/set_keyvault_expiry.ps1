param (
    [string]$SubscriptionName = "Alpha2phi",
    [int]$YearsToAdd = 2
)

# Login to Azure
# Connect-AzAccount

# Set the subscription context
Set-AzContext -SubscriptionName $SubscriptionName

# Get all Key Vaults in the subscription
$keyVaults = Get-AzKeyVault

# Define the expiration period
$expirationDate = (Get-Date).AddYears($YearsToAdd)

# Loop through each Key Vault
foreach ($keyVault in $keyVaults) {
    Write-Host "Processing Key Vault: $($keyVault.VaultName)" -ForegroundColor Yellow

    # Get all certificates in the vault
    $certificates = Get-AzKeyVaultCertificate -VaultName $keyVault.VaultName

    # Debugging. Checking certificate details
    # foreach ($cert in $certificates) {
    #     $certDetails = Get-AzKeyVaultCertificate -VaultName $keyVault.VaultName -Name $cert.Name
    #     # Write-Host "KeyId: $($certDetails.KeyId)"
    # Write-Host "Name: $($certDetails.Name)"
    # Write-Host "`n`n"
    # }

    # Set expiration for all keys in the Key Vault
    $keys = Get-AzKeyVaultKey -VaultName $keyVault.VaultName
    foreach ($key in $keys) {
        if ($key.Enabled -eq $false) {
            Write-Host "Skipping disabled key: $($key.Name)`n" -ForegroundColor DarkYellow
            continue
        }

        if ($key.Id) {

            Write-Host "Key Name: $($key.Name)"
            Write-Host "Key ID: $($key.Id)"

            # Find certificates that might be associated with this key
            $associatedCert = $null
            foreach ($cert in $certificates) {
                $certDetails = Get-AzKeyVaultCertificate -VaultName $keyVault.VaultName -Name $cert.Name
                # Write-Host ($certDetails | Format-List | Out-String)
                $certKeyid = $certDetails.KeyId -replace "/[^/]+$", ""
                if ($certKeyId -like $key.Id) {
                    $associatedCert = $cert 
                }
            }
            
            if ($associatedCert) {
                Write-Host "Key is associated with a certificate '$($associatedCert.Name)'. Skipping..." -ForegroundColor Yellow
                # Write-Host "Key '$($key.Name)' is associated with a certificate. Updating the certificate expiration." -ForegroundColor Cyan
                # Set-AzKeyVaultCertificateAttribute -VaultName $keyVault.VaultName -Name $associatedCert.Name -Expires $expirationDate
            }
            else {
                Write-Host "No associated certificates found. Proceed to set expiry date." -ForegroundColor Cyan
                Write-Host "Setting expiration for key: $($key.Name) to $expirationDate" -ForegroundColor Cyan
                Set-AzKeyVaultKey -VaultName $keyVault.VaultName -Name $key.Name -Expires $expirationDate
                Write-Host "Expiration date for key '$($key.Name)': $expirationDate" -ForegroundColor Green
            }
            Write-Host "-------------------`n"
        }
    }


    # Set expiration for all secrets in the Key Vault
    $secrets = Get-AzKeyVaultSecret -VaultName $keyVault.VaultName
    foreach ($secret in $secrets) {
        # Write-Host ($secret | Format-List | Out-String)

        if ($secret.Enabled -eq $false) {
            Write-Host "Skipping disabled secret: $($secret.Name)`n" -ForegroundColor DarkYellow
            continue
        }

        # Check if the secret is associated with a certificate
        $associatedCert = $null
        foreach ($cert in $certificates) {
            $certDetails = Get-AzKeyVaultCertificate -VaultName $keyVault.VaultName -Name $cert.Name
            $certSecretId = $certDetails.SecretId -replace "/[^/]+$", ""
            if ($certSecretId -like $secret.Id) {
                $associatedCert = $cert 
            }
        }
        if ($associatedCert) {
            Write-Host "Secret $($secret.name) is associated with a certificate '$($associatedCert.Name)'. Skipping..." -ForegroundColor Yellow
        }
        else {
            # $currentSecretValue= Get-AzKeyVaultSecret -VaultName $keyVault.VaultName -Name $secret.Name -AsPlainText
            # Write-Host "Current secret value $($currentSecretValue)"

            $currentSecret = Get-AzKeyVaultSecret -VaultName $keyVault.VaultName -Name $secret.Name 
            Write-Host "Setting expiration for secret: $($secret.Name) to $expirationDate" -ForegroundColor Cyan
            Set-AzKeyVaultSecret -VaultName $keyVault.VaultName -Name $secret.Name -Expires $expirationDate -SecretValue $currentSecret.SecretValue
            Write-Host "Expiration date for secret '$($secret.Name)': $expirationDate" -ForegroundColor Green
        }
    }

    Write-Host "`nCompleted processing Key Vault: $($keyVault.VaultName)" -ForegroundColor Green
}



Write-Host "All Key Vaults have been processed.`n`n" -ForegroundColor Green

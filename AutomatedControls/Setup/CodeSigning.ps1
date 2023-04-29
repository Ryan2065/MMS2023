$CertFolderLocation = 'C:\EphingCerts'
$CertSubject = 'CN=EphingAdmin.com'
$AzureAutomationInstallFolder = 'C:\Packages'  # Azure Arc location

if(-not (Test-Path $CertFolderLocation)) {
    $null = New-Item -Path $CertFolderLocation -ItemType Directory
}

#region Create Certificate
    # Create a self-signed certificate that can be used for code signing
    $SigningCert = New-SelfSignedCertificate -CertStoreLocation cert:\LocalMachine\my `
        -Subject $CertSubject `
        -KeyAlgorithm RSA `
        -KeyLength 2048 `
        -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" `
        -KeyExportPolicy Exportable `
        -KeyUsage DigitalSignature `
        -Type CodeSigningCert

    # Export the certificate so that it can be imported to the hybrid workers
    Export-Certificate -Cert $SigningCert -FilePath "$CertFolderLocation\hybridworkersigningcertificate.cer"
    # Retrieve the thumbprint for later use
    Write-Output "Code signing certificate thumbprint:"
    Write-Output $SigningCert.Thumbprint
#endregion

#region Run on Hybrid Runbook Workers to Import
    # Install the certificate into a location that will be used for validation.
    $null = New-Item -Path Cert:\LocalMachine\AutomationHybridStore -ErrorAction SilentlyContinue
    Import-Certificate -FilePath "$CertFolderLocation\hybridworkersigningcertificate.cer" -CertStoreLocation Cert:\LocalMachine\AutomationHybridStore

    # Import the certificate into the trusted root store so the certificate chain can be validated
    Import-Certificate -FilePath "$CertFolderLocation\hybridworkersigningcertificate.cer" -CertStoreLocation Cert:\LocalMachine\Root
#endregion

#region Run on Hybrid Runbook Workers
    # Configure the hybrid worker to use signature validation on runbooks.
    <#
        Docs say to use Set-HybridRunbookWorkerSignatureValidation, but it doesn't work on an Azure Arc server. Keeping here for reference.
        $HybridRegistrationDll = Get-ChildItem -Path $AzureAutomationInstallFolder -Filter Hybrid.Registration.Cmdlets.dll -Recurse -ErrorAction SilentlyContinue
        if(-not $HybridRegistrationDll) {
            Write-Error "Could not find Hybrid.Registration.Cmdlets.dll in $AzureAutomationInstallFolder"
            return
        }
        Import-Module $HybridRegistrationDll.FullName -Force
        Set-HybridRunbookWorkerSignatureValidation -Enable $true -TrustedCertStoreLocation "Cert:\LocalMachine\AutomationHybridStore"
    #>
    #Settings are in the registry - will require a restart of the Hybrid Runbook Worker service
    $TrustedStorePath = 'Cert:\LocalMachine\AutomationHybridStore'
    $EnableSignatureValidation = 'True'
    $HybridRunbookWorkerRegKey = 'HKLM:\SOFTWARE\Microsoft\HybridRunbookWorkerV2'
    Get-ChildItem $HybridRunbookWorkerRegKey | ForEach-Object{
        $HybridRunbookWorkerSubKey = "$($HybridRunbookWorkerRegKey)\$($_.PSChildName)"
        if($_.GetValue('TrustedStorePath') -ne $TrustedStorePath){
            Write-Host "Setting TrustedStorePath"
            $null = New-ItemProperty -Path $HybridRunbookWorkerSubKey -Name 'TrustedStorePath' -Value $TrustedStorePath -PropertyType String -Force
        }
        if($_.GetValue('EnableSignatureValidation') -ne $EnableSignatureValidation){
            Write-Host "Setting EnableSignatureValidation"
            $null = New-ItemProperty -Path $HybridRunbookWorkerSubKey -Name 'EnableSignatureValidation' -Value $EnableSignatureValidation -PropertyType String -Force
        }
    }
#endregion


<#
    Code used to sign a script
    $SigningCert = ( Get-ChildItem -Path cert:\LocalMachine\My\<CertificateThumbprint>)
    Set-AuthenticodeSignature .\TestRunbook.ps1 -Certificate $SigningCert
#>


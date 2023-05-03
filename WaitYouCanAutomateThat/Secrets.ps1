Install-Module Microsoft.PowerShell.SecretManagement -Repository PSGallery
Install-Module Microsoft.PowerShell.SecretStore -Repository PSGallery

Register-SecretVault -Name DefaultVaultStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

Set-Secret -Name 'Test' -Secret 'Test2'

Get-Secret -Name 'Test'
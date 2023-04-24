
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module Az.Automation -Force -Confirm:$false

$ResourceGroupName = "AutomationAccountRG"
$AutomationAccountName = "AutomationAccount"

$RunbookLocation = [System.IO.Path]::Join($PSScriptRoot, "Runbooks")

$Runbooks = Get-ChildItem -Path $RunbookLocation -Recurse -Include *.ps1 -File

# Import runbooks to Azure
foreach ($Runbook in $Runbooks) {
    Import-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Path $Runbook.FullName -Type PowerShell -Force -Published
}
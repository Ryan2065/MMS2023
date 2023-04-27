$VerbosePreference = 'SilentlyContinue'

<#
To run locally:
First run Connect-AzAccount to authenticate to Azure
Then run Set-AzContext -SubscriptionId '***' -TenantId '***' if more than one subscription
#>

#Install Az.Automation module
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module Az.Automation -Force -Confirm:$false

# Set ResourceGroup and Automation Account Name
$ResourceGroupName = "AutomationAccountRG"
$AutomationAccountName = "AutomationAccount"

# Set paths we'll need
$RunbookLocation = [System.IO.Path]::Join($PSScriptRoot, "Runbooks")
$ExportedRunbookFolder = [System.IO.Path]::Join($PSScriptRoot, "bin", "ExportedRunbooks")

# Get all runbooks in this repository
$Runbooks = Get-ChildItem -Path $RunbookLocation -Recurse -Include *.ps1 -File

# Get all runbooks in Azure
$AllAzureRunbooks = Get-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue

$null = New-Item -ItemType Directory -Path $ExportedRunbookFolder -Force
# Import runbooks to Azure
foreach ($Runbook in $Runbooks) {
    Export-AzAutomationRunbook -Name $Runbook.BaseName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -OutputFolder $ExportedRunbookFolder -Force -ErrorAction SilentlyContinue
    $ExportedRunbook = [System.IO.Path]::Join($ExportedRunbookFolder, $Runbook.Name)
    if(Test-Path $ExportedRunbook) {
        $ExportedRunbookContent = Get-Content $ExportedRunbook -Raw
        $GitRunbookContent = Get-Content $Runbook.FullName -Raw
        if($ExportedRunbookContent -eq $GitRunbookContent) {
            Write-Verbose "Runbook $($Runbook.BaseName) already exists in Azure and is up to date"
            continue
        }
        else{
            Write-Output "Runbook $($Runbook.BaseName) already exists in Azure but is out of date - Will import"
        }
    }
    else{
        Write-Output "Runbook $($Runbook.BaseName) does not exist in Azure - Will import"
    }
    $null = Import-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Path $Runbook.FullName -Type PowerShell -Force -Published
}

Foreach($AzureRunbook in $AllAzureRunbooks){
    $RunbookName = $AzureRunbook.Name
    $Runbook = $Runbooks | Where-Object {$_.BaseName -eq $RunbookName}
    if($null -eq $Runbook){
        Write-Output "Runbook $($RunbookName) exists in Azure but not in this repository - Will delete"
        $null = Remove-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $RunbookName -Force
    }
}

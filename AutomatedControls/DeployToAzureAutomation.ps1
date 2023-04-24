$VerbosePreference = 'Continue'
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module Az.Automation -Force -Confirm:$false

$ResourceGroupName = "AutomationAccountRG"
$AutomationAccountName = "AutomationAccount"

$RunbookLocation = [System.IO.Path]::Join($PSScriptRoot, "Runbooks")

$Runbooks = Get-ChildItem -Path $RunbookLocation -Recurse -Include *.ps1 -File

$AllAzureRunbooks = Get-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue
$ExportedRunbookFolder = [System.IO.Path]::Join($PSScriptRoot, "bin", "ExportedRunbooks")

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
            Write-Verbose "Runbook $($Runbook.BaseName) already exists in Azure but is out of date - Will import"
        }
    }
    else{
        Write-Verbose "Runbook $($Runbook.BaseName) does not exist in Azure - Will import"
        (Get-ChildItem $ExportedRunbookFolder -Recurse).FullName
    }
    $null = Import-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Path $Runbook.FullName -Type PowerShell -Force -Published
}
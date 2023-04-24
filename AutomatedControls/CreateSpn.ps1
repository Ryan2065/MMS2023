
$SpnName = '<Name of the Service Principal>'
$Subscription = '<subscription-id>'
$AzureAutomationResourceGroup = '<AzureAutomationResourceGroup>'
# Description: This script will create a service principal in Azure AD and assign it the Contributor role at the subscription level. This is required for the GitHub deployment to Azure Automation to work. "AutomationAccountRG" is the name of the resource group the automation account is in

az ad sp create-for-rbac -n $SpnName --role Contributor --scopes "/subscriptions/$Subscription/resourceGroups/$AzureAutomationResourceGroup"

<#
    Output is in the format 
    {
        "appId": "<client-id>",
        "displayName": "<SPN-Name>",
        "password": "<client-secret>",
        "tenant": "<tenant-id>"
    }

GitHub deploy is in main.yml

You now have:
    ClientId: From output of az command
    ClientSecret: From output of az command
    TenantId: From output of az command
    SubscriptionId: Line 2 - subscription you created the SPN in 

Create secrets in GitHub or somewhere else to fill in for Azure Login
#>


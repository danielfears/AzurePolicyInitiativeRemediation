# Azure Policy Initiative Remediation Script

This PowerShell script has been designed to automate the remediation of Azure policy initiatives, with the flexibility to target a single subscription or iterate across multiple subscriptions within an Azure tenant. It checks for policy initiative assignments and initiates remediation processes where applicable, leveraging a reusable function for efficient background execution.

## Prerequisites

Before executing this script, ensure that you have:

- PowerShell installed on your system.
- The Azure PowerShell module (`Az` module) installed. Install it using the command: `Install-Module -Name Az -AllowClobber -Scope CurrentUser`.
- Necessary permissions to manage Azure Policy assignments and remediations within your Azure tenant.

## Configuration

1. **Set Policy Initiatives**:
   Modify the `$policyInitiativeAssignmentNames` array and `$policyInitiativeDefinitionName` variable at the beginning of the script to include the policy initiatives you aim to remediate.

    ```powershell
    $policyInitiativeAssignmentNames = @(
        "policyInitiativeAssignmentName1",
        "policyInitiativeAssignmentName2"
    )
    $policyInitiativeDefinitionName = "policyInitiativeDefinitionName"
    ```

2. **Specify Subscription ID** (Optional):
   To target a specific subscription, set the `$subscriptionId` variable. Leave it blank (`""`) to iterate through all subscriptions in the tenant.

    ```powershell
    $subscriptionId = "<Your-Subscription-ID>"
    ```

## Execution

- **Authenticate with Azure**:
  If not already authenticated, the script will prompt you for your Azure credentials when run.

- **Run the Script**:
  Navigate to the directory containing the script and execute it by running:

    ```powershell
    .\PolicyRemediation.ps1
    ```

## Monitoring and Managing Background Tasks

The script initiates remediation jobs as background tasks. Use PowerShell job commands to manage these tasks:

- **Check status** of all background jobs:

    ```powershell
    Get-Job
    ```

- **Receive output** from a completed job:

    ```powershell
    Receive-Job -Id <job-id>
    ```

- **Remove** a finished job:

    ```powershell
    Remove-Job -Id <job-id>
    ```

## Output

The script outputs each step of the remediation process to the PowerShell console, detailing found policy assignments and the initiation of remediation jobs.

## Important Notes

- The script is configured to automatically start the remediation process. Ensure you have reviewed and are comfortable with the actions it will take.

- Verify the correct setup of policy initiatives and definitions in your Azure environment prior to running the script.

- Adequate permissions are required to view and manage policy assignments and remediations across your Azure tenant's subscriptions.

## Disclaimer

This script is provided "as-is". It is recommended to test in a non-production environment before using it in production settings.

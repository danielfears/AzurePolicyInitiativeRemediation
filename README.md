# Azure Policy Initiative Remediation Script

This PowerShell script is designed to automate the process of remediating Azure policy initiatives across multiple subscriptions in an Azure tenant. It specifically targets predefined policy initiatives, checks for their assignments in each subscription, and initiates a remediation process where applicable. The script has been enhanced to support running these remediation tasks as background jobs, allowing for non-blocking execution.

## Prerequisites

Before running this script, ensure that you have:

- PowerShell installed on your machine.
- Azure PowerShell module (`Az` module) installed. You can install it using `Install-Module -Name Az -AllowClobber -Scope CurrentUser`.
- Appropriate permissions to access and manage Azure Policy assignments and remediations in your Azure tenant.

## Usage

1. **Define Policy Initiatives**:
   Update the `$policyInitiativeAssignmentNames` array and `$policyInitiativeDefinitionName` variable at the top of the script to include the names of the policy initiatives you want to remediate.

    ```powershell
    $policyInitiativeAssignmentNames = @(
        "Initiative1",
        "Initiative2"
    )

    $policyInitiativeDefinitionName = "InitiativeDefinitionName"
    ```

2. **Run the Script**:
   Execute the script in a PowerShell session. This can be done by navigating to the directory containing the script and running:

    ```powershell
    .\PolicyRemediation.ps1
    ```

3. **Authenticate**:
   If you are not already authenticated, the script will prompt you to enter your Azure credentials.

4. **Running as a Background Task**:
   The script automatically starts the remediation jobs as background tasks. You can monitor these tasks using PowerShell job commands:
   
   - To check the status of all background jobs, use:
     ```powershell
     Get-Job
     ```
   - To receive the output of a completed job, use:
     ```powershell
     Receive-Job -Id <job-id>
     ```
   - To remove a finished job, use:
     ```powershell
     Remove-Job -Id <job-id>
     ```

5. **Monitor Output**:
   The script provides output in the PowerShell console, detailing each step of the process, including any found policy assignments and the initiation of remediation jobs.

## Important Notes

- The script currently has a line commented out that would start the actual remediation process. This is intentional to avoid unintended changes. To enable the remediation, uncomment the following line:

    ```powershell
    # Start-AzPolicyRemediation -Name "Remediation-"$($policyDefinition.PolicyDefinitionId) + "-" + $($assignment.PolicyAssignmentId) + "-" + (Get-Date -Format "yyyyMMddHHmmss") -PolicyAssignmentId $assignment.PolicyAssignmentId -PolicyDefinitionReferenceId $policyDefinition.policyDefinitionReferenceId
    ```

- Ensure that the policy initiatives and their respective definitions are correctly set up in your Azure environment before running this script.

- This script assumes that you have the necessary permissions to view and manage policy assignments and remediations across the subscriptions in your Azure tenant.

## Disclaimer

This script is provided as-is, and it is recommended to test it in a non-production environment before using it in a production environment.

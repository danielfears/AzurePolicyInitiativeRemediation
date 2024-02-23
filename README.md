# Bulk Azure Policy Initiative Remediator (BAPIR)

This PowerShell script automates the remediation of Azure policy initiatives, now offering expanded functionality to operate not just across subscriptions but also within Azure Management Groups. It locates policy initiative assignments and triggers remediation processes where necessary, employing a reusable function for efficient execution, both at the subscription level and across management group hierarchies.

## Prerequisites

Before executing this script, ensure that you have:

- PowerShell installed on your system.
- The Azure PowerShell module (`Az` module) installed. Install it using the command: `Install-Module -Name Az -AllowClobber -Scope CurrentUser`.
- Necessary permissions to manage Azure Policy assignments and remediations within your Azure tenant, including the management groups.

## Configuration

1. **Management Group and Policy Initiatives Configuration**:
   The script now requires specifying the target management group names and policy initiative details. Adjust the `$parentManagementGroupName`, `$PolicyInitiativeDefinitionName`, and `$PolicyInitiativeAssignmentNames` variables at the start of the script.

    ```powershell
    $parentManagementGroupName = "YourParentManagementGroupName"
    $PolicyInitiativeDefinitionName = "YourPolicyInitiativeDefinitionName"
    $PolicyInitiativeAssignmentNames = @("YourPolicyInitiativeAssignmentName1", "YourPolicyInitiativeAssignmentName2")
    ```

2. **Management Group Targeting**:
   The script has been enhanced to support iterating through child management groups under a specified parent management group for policy remediation. This is in addition to the optional subscription targeting.

    ```powershell
    # Fetching child Management Groups
    $childManagementGroups = Get-AzManagementGroup -GroupName $parentManagementGroupName -Recurse -Expand
    ```

## Execution

- **Authenticate with Azure**:
  If not already authenticated, the script will prompt you for your Azure credentials upon execution.

- **Run the Script**:
  Navigate to the script's directory and execute it with:

    ```powershell
    .\PolicyRemediation.ps1
    ```

## Monitoring and Managing Background Tasks

Remediation jobs initiated by the script run as background tasks. Utilize PowerShell job commands for task management:

- **Check the status** of all background jobs with `Get-Job`.
- **Receive output** from a completed job using `Receive-Job -Id <job-id>`.
- **Remove** a finished job with `Remove-Job -Id <job-id>`.

## Output

The script provides detailed console output for each step of the remediation process, including identification of policy assignments and the launch of remediation jobs.

## Important Notes

- The script now includes management group handling for comprehensive policy initiative remediation across your Azure environment.
- Ensure that policy initiatives and definitions are correctly configured in your Azure environment, including the necessary hierarchy of management groups, prior to execution.
- Adequate permissions are needed to view and manage policy assignments and remediations across subscriptions and management groups within your tenant.

## Disclaimer

This script is provided "as-is", with recommendations to test in a non-production environment before implementation in production settings.

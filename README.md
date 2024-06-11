# Azure Bulk Policy Remediator

## Overview

The Azure Bulk Policy Remediator is a PowerShell script designed to automate the remediation of Azure policy violations across multiple scopes, such as management groups or subscriptions. It is particularly useful in large environments where manual enforcement of policy compliance is impractical. The script handles each policy within an initiative separately, ensuring comprehensive remediation of all policies within an initiative.

## Key Features

- **Automated Azure Login**: Handles both local and CI/CD pipeline-based Azure logins.
- **Scope Management**: Supports remediation across different scopes, including child management groups.
- **Policy Remediation**: Automatically starts remediation jobs for policy assignments matching specified criteria.
- **Pipeline Integration**: Built primarily for use in a GitLab CI/CD pipeline.

## Usage

### Parameters

The script accepts several parameters, typically passed through environment variables:

- `AzureTenantId`: Tenant ID for Azure authentication.
- `AzureClientId`: Client ID for Azure authentication.
- `AzureClientSecret`: Client secret for Azure authentication.
- `policyType`: Type of policy (e.g., "PolicySet").
- `policyDefinitionName`: Name of the policy definition.
- `policyAssignmentName`: Name of the policy assignment.
- `policyRemediationScope`: Scope of the remediation (e.g., "ChildManagementGroups").
- `scopeName`: Name of the parent management group or subscription.

### Local Testing

For local testing, predefined values for the policy scope variables can be set. It includes a check to see if the user is already logged into Azure, and if not, it initiates a login using a local script (`Local-Testing.ps1`).

### Azure Login

- **Local Testing**: Uses the locally stored login script.
- **Pipeline Login**: Uses service principal credentials passed through environment variables for non-interactive login.

### Running the Pipeline in GitLab

1. Navigate to the **Pipelines** section in your GitLab project.
2. Click on **Run pipeline**.
3. Fill in the relevant information for each field as shown in the screenshot below:

   - `TENANT`: Select the environment to run the script in (e.g., DEV, PROD).
   - `POLICY_TYPE`: Policy Type (e.g., PolicySet).
   - `POLICY_DEFINITION_NAME`: Policy Initiative Definition Name to be used for Policy Remediation.
   - `POLICY_ASSIGNMENT_NAME`: Policy Initiative Assignment Name to be used for Policy Remediation.
   - `POLICY_REMEDIATION_SCOPE`: Policy Remediation Scope (e.g., ChildManagementGroups).
   - `SCOPE_NAME`: Name of the parent Management Group or Subscription - starting point for remediation.

4. Click on **Run pipeline** to start the remediation process.

### POLICY_REMEDIATION_SCOPE Values

#### ChildManagementGroups

Remediates policies across all child management groups under a specified parent management group. This allows for comprehensive policy enforcement across multiple management groups.

#### ChildSubscriptions (NYI)

Planned to remediate policies across all subscriptions under a specified parent management group. This will enable the script to enforce policy compliance across multiple subscriptions below a given management group.

#### SpecificSubscription (NYI)

Planned to target and remediate policies within a specific subscription. This will provide more granular control over policy remediation efforts for individual subscriptions.

## Functions

### Get-ScopeObject

Retrieves the scope object based on the specified remediation scope and scope name:

- **SpecificSubscription**: Retrieves a subscription object.
- **Default**: Retrieves a management group object.

### Start-PolicyRemediation

Handles the remediation process:

- Retrieves all policy assignments and policy set definitions.
- Matches policy assignments with the provided policy assignment name.
- Starts remediation jobs for matching policy definitions.

### Invoke-PolicyRemediation

Orchestrates the remediation process:

- Calls `Get-ScopeObject` to retrieve the scope object.
- Iterates through child management groups (or other scopes, when implemented).
- Calls `Start-PolicyRemediation` to initiate remediation jobs.

## Upcoming Improvements

### Support for Additional Scope Types

#### Child Subscriptions

Support will be extended to handle child subscriptions, allowing the script to iterate through all subscriptions under a management group and perform the necessary policy remediations.

#### Specific Subscription Remediation

Future improvements will include the ability to handle specific subscriptions directly, providing greater control and granularity.

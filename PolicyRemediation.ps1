# Azure Bulk Policy Remediator - authored by Daniel Fears

# Setup and parameters for CI/CD pipeline value input
[CmdletBinding()]
param (
    [string]$AzureTenantId = $env:ARM_TENANT_ID,
    [string]$AzureClientId = $env:ARM_CLIENT_ID,
    [string]$AzureClientSecret = $env:ARM_CLIENT_SECRET,
    [string]$policyType = $env:POLICY_TYPE, # Type of policy, either "Policy" or "PolicySet"
    [string]$policyDefinitionName = $env:POLICY_DEFINITION_NAME, # Name of the policy definition object
    [string]$policyAssignmentName = $env:POLICY_ASSIGNMENT_NAME, # Name of policy assignment object
    [string]$policyRemediationScope = $env:POLICY_REMEDIATION_SCOPE, # Scope of remediation, see readme for possible values
    [string]$scopeName = $env:SCOPE_NAME # Name of the parent Management Group or Subscription - starting point for defining relative scope
)

############################################################################################################

# For local testing - to be removed before go live #
if (Test-Path -Path "./Local-Testing.ps1") {

    # Define Policy scope variables - enter these here or during script execution
    $policyType = "" # Type of policy, either "Policy" or "PolicySet"
    $policyDefinitionName = "" # Name of the policy definition object
    $policyAssignmentName = "" # Name of policy assignment object
    $policyRemediationScope = "" # Scope of remediation, see above readme for possible values
    $scopeName = "" # Name of the parent Management Group or Subscription - starting point for remediation

    # Hashtable with variable names and their descriptions
    $variables = @{
        policyType = "Please enter policy type (Policy or PolicySet)"
        policyDefinitionName = "Please enter policy definition name"
        policyAssignmentName = "Please enter policy assignment name"
        policyRemediationScope = "Please enter policy remediation scope (ChildManagementGroups, ChildSubscriptions, SpecificSubscription)"
        scopeName = "Please enter scope name"
    }

    # Iterate over each variable and prompt if not set
    foreach ($key in $variables.Keys) {
        if (-not (Get-Variable -Name $key -ValueOnly)) {
            Set-Variable -Name $key -Value (Read-Host $variables[$key])
        }
    }

    # Check if already logged in to Azure, otherwise use locally stored login script
    $currentAzureContext = Get-AzContext
    if (-not $currentAzureContext) {
        Write-Host "Not logged in to Azure. Initiating login..."
        . ./Local-Testing.ps1
    } else {
        Write-Host "Already logged in as $($currentAzureContext.Account)"
    }
} else {

    Import-Module "./pshelperfunctions/PSHelperFunctions/PSHelperFunctions.psd1" -Force -Verbose

    # Pipeline login to Azure - non-interactive login
    $SecureClientSecret = ConvertTo-SecureString $AzureClientSecret -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($AzureClientId, $SecureClientSecret)
    
    try {
        Connect-AzAccount -Credential $credential -TenantId $AzureTenantId -ServicePrincipal -ErrorAction Stop
    }
    catch {
        Write-Error "Error occurred while logging in to Azure"
        Write-Host "Error: $_"
        exit
    }
}

############################################################################################################

# Function to get the scope object
function Get-ScopeObject {
    param (
        [string]$policyRemediationScope,
        [string]$scopeName,
        [string]$scopeType
    )

    if ($policyRemediationScope -eq "SpecificSubscription") {

        Write-Host "Scope type set to: $policyRemediationScope"
        Write-Host "Scope name: $scopeName"

        $scope = Get-AzSubscription -SubscriptionName $scopeName -Recurse -Expand

        if ($null -eq $scope) {
            throw "Subscription with name '$scopeName' not found"
        }
    } else {

        Write-Host "Scope type set to: $policyRemediationScope"
        Write-Host "Scope name: $scopeName"

        $scope = Get-AzManagementGroup -GroupName $scopeName -Recurse -Expand

        if ($null -eq $scope) {
            throw "Management Group with name '$scopeName' not found"
        }
    }

    return $scope
}

function Start-PolicyRemediation {

    param (
        [object]$scope,
        [string]$definitionScope,
        [object]$assignmentScope,
        [string]$policyAssignmentName,
        [string]$policyDefinitionName
    )

    # Retrieve all policy assignments
    $PolicyAssignments = Get-AzPolicyAssignment -Scope $assignmentScope.Id -WarningAction SilentlyContinue | Select-Object *, 
    @{Name = "InitiativeDisplayName"; Expression = { $_.Properties.DisplayName } },
    @{Name = "Scope"; Expression = { $_.Properties.Scope } },
    @{Name = "PolicyDefinitionId"; Expression = { $_.Properties.PolicyDefinitionId } } -ExcludeProperty 'Properties'

    # Retrieve all policy set definitions
    $policyDefinitions = Get-AzPolicySetDefinition -ManagementGroupName $definitionScope | Where-Object { $_.Properties.DisplayName -eq $policyDefinitionName } # Account for sets and individual policies
    $policyDefinitions = $policyDefinitions.Properties.PolicyDefinitions

    # Check if any policy initiative assignment matches the provided policy initiative assignment name
    $matchedPolicyAssignments = $PolicyAssignments | Where-Object { $_.InitiativeDisplayName -eq $policyAssignmentName }

    if ($matchedPolicyAssignments) {
        foreach ($assignment in $matchedPolicyAssignments) {
            Write-Host "Found policy initiative assignment with ID: $($assignment.PolicyAssignmentId) for initiative '$policyAssignmentName'"

            foreach ($policyDefinition in $policyDefinitions) {

                # Create the remediation job
                try {

                    $remediationName = "Remediation-" + $($policyDefinition.PolicyDefinitionId.Split("/")[-1]) + "-" + (Get-Date -Format "yyyyMMddHHmmssfff")

                    Start-AzPolicyRemediation -Scope $assignmentScope.Id -Name $remediationName -PolicyAssignmentId $assignment.PolicyAssignmentId -PolicyDefinitionReferenceId $policyDefinition.policyDefinitionReferenceId -AsJob

                    Write-Host ""
                    Write-Warning "`nRemediating the following:"
                    Write-Host "Management Group:"$assignmentScope.DisplayName
                    Write-Host "Policy Initiative: $policyAssignmentName"
                    Write-Host "Policy Name: $($policyDefinition.PolicyDefinitionId.Split("/")[-1])"
                    Write-Host "Policy Reference ID: $($policyDefinition.policyDefinitionReferenceId)"
                    Write-Host "Remediation Name: $remediationName" 

                }
                catch {

                    Write-Error "Error occurred while remediating the following:"
                    Write-Host "Management Group:"$assignmentScope.DisplayName
                    Write-Host "Policy Initiative: $policyAssignmentName"
                    Write-Host "Policy Name: $($policyDefinition.PolicyDefinitionId.Split("/")[-1])"
                    Write-Host "Policy Reference ID: $($policyDefinition.policyDefinitionReferenceId)"
                    Write-Host "Remediation Name: $remediationName"

                    Write-Host "Error: $_"
                }
            }
        }
    } else {
        Write-Host "No policy assignment found for initiative '$policyAssignmentName' at Scope:" $scope.DisplayName
    }

}

function Invoke-PolicyRemediation {
    
    # Get Scope object and set to variable
    $scope = Get-ScopeObject -policyRemediationScope $policyRemediationScope -scopeName $scopeName
    $definitionScope = $scope.ParentName

    # Case statement to handle different scope types
    switch ($policyRemediationScope) {
        "ChildManagementGroups" {

            $childManagementGroups = $scope.Children

            foreach ($childManagementGroup in $childManagementGroups) {
                $assignmentScope = $childManagementGroup
                Start-PolicyRemediation -scope $scope -definitionScope $definitionScope -assignmentScope $assignmentScope -policyAssignmentName $policyAssignmentName -policyDefinitionName $policyDefinitionName
            }
        }
        "ChildSubscriptions" { # Not yet implemented

            Write-Host "ChildSubscriptions scope not yet implemented"

            # $childManagementGroups = $scope.Children
            # foreach ($childManagementGroup in $childManagementGroups) {

            #     $subscriptions = $childManagementGroup.Children

            #     foreach ($subscription in $subscriptions) {
            #         $assignmentScope = $subscription
            #         Start-PolicyRemediation -scope $scope -definitionScope $definitionScope -assignmentScope $assignmentScope -policyAssignmentName $policyAssignmentName -policyDefinitionName $policyDefinitionName
            #     }
            # }
        }
        "SpecificSubscription" { # Not yet implemented

            Write-Host "SpecificSubscription scope not yet implemented"

        }
    }
    
}

Invoke-PolicyRemediation

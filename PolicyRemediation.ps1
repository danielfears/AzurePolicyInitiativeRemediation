function Start-PolicyInitiativeRemediation {
    param (
        [string]$SubscriptionId,
        [string[]]$PolicyInitiativeAssignmentNames,
        [string]$PolicyInitiativeDefinitionName
    )

    # Select the subscription
    Select-AzSubscription -SubscriptionId $SubscriptionId > $null
    Write-Host "Selected subscription: $SubscriptionId"

    # Retrieve all policy assignments
    $PolicyAssignments = Get-AzPolicyAssignment -WarningAction SilentlyContinue | Select-Object *, 
    @{Name = "InitiativeDisplayName"; Expression = { $_.Properties.DisplayName } },
    @{Name = "Scope"; Expression = { $_.Properties.Scope } },
    @{Name = "PolicyDefinitionId"; Expression = { $_.Properties.PolicyDefinitionId } } -ExcludeProperty 'Properties'

    $policySetDefinition = Get-AzPolicySetDefinition | Where-Object { $_.Name -eq $PolicyInitiativeDefinitionName }
    $policySetDefinition = $policySetDefinition.Properties.PolicyDefinitions

    foreach ($policyInitiativeAssignmentName in $PolicyInitiativeAssignmentNames) {
        $matchedPolicyAssignments = $PolicyAssignments | Where-Object { $_.InitiativeDisplayName -eq $policyInitiativeAssignmentName }

        if ($matchedPolicyAssignments) {
            foreach ($assignment in $matchedPolicyAssignments) {
                Write-Host "Found policy initiative assignment with ID: $($assignment.PolicyAssignmentId) for initiative '$policyInitiativeAssignmentName'"

                foreach ($policyDefinition in $policySetDefinition) {
                    $remediationName = "Remediation-" + $($policyDefinition.PolicyDefinitionId.Split("/")[-1]) + "-" + (Get-Date -Format "yyyyMMddHHmmssfff")

                    Write-Host ""
                    Write-Host "Remediating the following:"
                    Write-Host "Subscription: $SubscriptionId"
                    Write-Host "Policy Initiative: $policyInitiativeAssignmentName"
                    Write-Host "Policy Name: $($policyDefinition.PolicyDefinitionId.Split("/")[-1])"
                    Write-Host "Policy Reference ID: $($policyDefinition.policyDefinitionReferenceId)"
                    Write-Host "Remediation Name: $remediationName"

                    # Create the remediation job
                    Start-AzPolicyRemediation -Name $remediationName -PolicyAssignmentId $assignment.PolicyAssignmentId -PolicyDefinitionReferenceId $policyDefinition.policyDefinitionReferenceId -AsJob
                }
            }
        } else {
            Write-Warning "No policy assignment found for initiative '$policyInitiativeAssignmentName' in Subscription '$SubscriptionId'."
        }
    }
}

# Define the names of any policy initiatives to remediate
$policyInitiativeAssignmentNames = @("policyInitiativeAssignmentName1", "policyInitiativeAssignmentName2")
$policyInitiativeDefinitionName = "policyInitiativeDefinitionName"

# Set this to only run against a single Subscription - LEAVE BLANK TO ITERATE THROUGH ALL SUBSCRIPTIONS IN A GIVEN TENANT
$subscriptionId = ""

# Check for existing Azure session
$context = Get-AzContext -ErrorAction SilentlyContinue
if ($null -eq $context) {
    Connect-AzAccount
} else {
    Write-Host "Already connected to Azure as $($context.Account)"
}

# Determine whether to process a single subscription or all subscriptions
if (-not [string]::IsNullOrWhiteSpace($subscriptionId)) {
    Start-PolicyInitiativeRemediation -SubscriptionId $subscriptionId -PolicyInitiativeAssignmentNames $policyInitiativeAssignmentNames -PolicyInitiativeDefinitionName $policyInitiativeDefinitionName
} else {
    $subscriptions = Get-AzSubscription
    if ($null -eq $subscriptions -or $subscriptions.Count -eq 0) {
        Write-Host "No subscriptions found. Please check your Azure account permissions."
    } else {
        foreach ($subscription in $subscriptions) {
            Start-PolicyInitiativeRemediation -SubscriptionId $subscription.Id -PolicyInitiativeAssignmentNames $policyInitiativeAssignmentNames -PolicyInitiativeDefinitionName $policyInitiativeDefinitionName
        }
    }
}

Write-Warning "Script completed."

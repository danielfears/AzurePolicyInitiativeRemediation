# Define the names of the policy initiatives to remediate
$policyInitiativeAssignmentNames = @(
    "InitiativeAssignment1",
    "InitiativeAssignment2"
)

$policyInitiativeDefinitionName = "InitiativeDefinitionName"

# Check for existing Azure session
$context = Get-AzContext -ErrorAction SilentlyContinue

if ($null -eq $context) {
    # Authenticate with Azure if no session exists
    Connect-AzAccount
} else {
    Write-Host "Already connected to Azure as $($context.Account)"
}

# Get all subscriptions in the tenant
$subscriptions = Get-AzSubscription

if ($null -eq $subscriptions) {
    Write-Host "No subscriptions found. Please check your Azure account permissions."
    return
}

# Storing list of policies for initiative remediation
$policySetDefinition = Get-AzPolicySetDefinition | Where-Object { $_.Name -eq $policyInitiativeDefinitionName }
$policySetDefinition = $policySetDefinition.Properties.PolicyDefinitions

foreach ($subscription in $subscriptions) {

    # Select the subscription
    Select-AzSubscription -SubscriptionId $subscription.Id

    # Retrieve all policy assignments
    $PolicyAssignments = Get-AzPolicyAssignment -WarningAction SilentlyContinue | Select-Object *, 
    @{Name = "InitiativeDisplayName"; Expression = { $_.Properties.DisplayName } },
    @{Name = "Scope"; Expression = { $_.Properties.Scope } },
    @{Name = "PolicyDefinitionId"; Expression = { $_.Properties.PolicyDefinitionId } } -ExcludeProperty 'Properties'

    # Iterate through each policy initiative name
    foreach ($policyInitiativeAssignmentName in $policyInitiativeAssignmentNames) {

        # Find policy assignments with the specified initiative display name
        $matchedPolicyAssignments = $PolicyAssignments | Where-Object { $_.InitiativeDisplayName -eq $policyInitiativeAssignmentName }

        if ($matchedPolicyAssignments) {
            foreach ($assignment in $matchedPolicyAssignments) {
                Write-Host "Found policy initiative assignment with ID: $($assignment.PolicyAssignmentId) for initiative '$policyInitiativeAssignmentName'"

                # Create a remediation job for each policy assignment
                foreach ($policyDefinition in $policySetDefinition) {
                    
                    # Create a unique name for the remediation job with the policy initiative assignment name and the current date/time
                    $remediationName = "Remediation-" + $policyInitiativeAssignmentName + "-" + (Get-Date -Format "yyyyMMddHHmmssfff")

                    Write-Host ""
                    Write-Host "Remediating the following:"
                    Write-Host "Subscription: $($subscription.Name)"
                    Write-Host "Policy Initiative: $($policyInitiativeAssignmentName)"
                    Write-Host "Policy Name: $($policyDefinition.PolicyDefinitionId.Split("/")[-1])"
                    Write-Host "Policy Reference ID: $($policyDefinition.policyDefinitionReferenceId)"
                    Write-Host "Remediation Name: $($remediationName)"
                    Start-Sleep -Seconds 1

                    # Create the remediation job - uncomment the line below to create the remediation job
                    # Start-AzPolicyRemediation -Name "Remediation-"$($policyDefinition.PolicyDefinitionId) + "-" + $($assignment.PolicyAssignmentId) + "-" + (Get-Date -Format "yyyyMMddHHmmss") -PolicyAssignmentId $assignment.PolicyAssignmentId -PolicyDefinitionReferenceId $policyDefinition.policyDefinitionReferenceId -AsJob

                }
            }
        } else {
            Write-Host "No policy assignment found for initiative '$policyInitiativeAssignmentName' in Subscription '$($subscription.Name)'."
        }
    }
    Write-Host ""
}
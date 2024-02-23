function Start-PolicyInitiativeRemediationForMG {
    param (
        [string]$ManagementGroupId,
        [string[]]$PolicyInitiativeAssignmentNames,
        [string]$PolicyInitiativeDefinitionName,
        [string]$parentManagementGroupName,
        [string]$ManagementGroupName # New parameter to pass the name of the Management Group
    )

    Write-Host "Processing Management Group: $ManagementGroupName ($ManagementGroupId)" # Updated to include the name

    # Retrieve all policy assignments
    $PolicyAssignments = Get-AzPolicyAssignment -Scope $ManagementGroupId -WarningAction SilentlyContinue | Select-Object *, 
    @{Name = "InitiativeDisplayName"; Expression = { $_.Properties.DisplayName } },
    @{Name = "Scope"; Expression = { $_.Properties.Scope } },
    @{Name = "PolicyDefinitionId"; Expression = { $_.Properties.PolicyDefinitionId } } -ExcludeProperty 'Properties'

    $policySetDefinition = Get-AzPolicySetDefinition -ManagementGroupName $parentManagementGroupName | Where-Object { $_.Properties.DisplayName -eq $PolicyInitiativeDefinitionName }
    $policySetDefinition = $policySetDefinition.Properties.PolicyDefinitions

    foreach ($policyInitiativeAssignmentName in $PolicyInitiativeAssignmentNames) {
        $matchedPolicyAssignments = $PolicyAssignments | Where-Object { $_.InitiativeDisplayName -eq $policyInitiativeAssignmentName }

        if ($matchedPolicyAssignments) {
            foreach ($assignment in $matchedPolicyAssignments) {
                Write-Host "Found policy initiative assignment with ID: $($assignment.PolicyAssignmentId) for initiative '$policyInitiativeAssignmentName'"

                foreach ($policyDefinition in $policySetDefinition) {

                    # Create the remediation job
                    try {

                        $remediationName = "Remediation-" + $($policyDefinition.PolicyDefinitionId.Split("/")[-1]) + "-" + (Get-Date -Format "yyyyMMddHHmmssfff")

                        Write-Warning "`nRemediating the following:"
                        Write-Host "Management Group: $ManagementGroupName"
                        Write-Host "Policy Initiative: $policyInitiativeAssignmentName"
                        Write-Host "Policy Name: $($policyDefinition.PolicyDefinitionId.Split("/")[-1])"
                        Write-Host "Policy Reference ID: $($policyDefinition.policyDefinitionReferenceId)"
                        Write-Host "Remediation Name: $remediationName"

                        Start-AzPolicyRemediation -Scope $ManagementGroupId -Name $remediationName -PolicyAssignmentId $assignment.PolicyAssignmentId -PolicyDefinitionReferenceId $policyDefinition.policyDefinitionReferenceId -AsJob

                    }
                    catch {

                        Write-Error "Error occurred while remediating the following:"
                        Write-Host "Management Group: $ManagementGroupName"
                        Write-Host "Policy Initiative: $policyInitiativeAssignmentName"
                        Write-Host "Policy Name: $($policyDefinition.PolicyDefinitionId.Split("/")[-1])"
                        Write-Host "Policy Reference ID: $($policyDefinition.policyDefinitionReferenceId)"
                        Write-Host "Remediation Name: $remediationName"

                        Write-Host "Error: $_"
                    }

                    Start-Sleep -Milliseconds 100
                }
            }
        } else {
            Write-Warning "No policy assignment found for initiative '$policyInitiativeAssignmentName' in Management Group '$ManagementGroupId'."
        }
    }
}

# Check if already logged in to Azure
$currentAzureContext = Get-AzContext
if (-not $currentAzureContext) {
    Write-Host "Not logged in to Azure. Initiating login..."
    Connect-AzAccount
} else {
    Write-Host "Already logged in as $($currentAzureContext.Account)"
}

# Fetching child Management Groups
$parentManagementGroupName = "YourParentManagementGroupName"
$childManagementGroups = Get-AzManagementGroup -GroupName $parentManagementGroupName -Recurse -Expand

# Define the policy initiative definition name and assignment names
$PolicyInitiativeDefinitionName = "YourPolicyInitiativeDefinitionName"
$PolicyInitiativeAssignmentNames = @("YourPolicyInitiativeAssignmentName1", "YourPolicyInitiativeAssignmentName2")

# Loop through each child Management Group for policy remediation
foreach ($mg in $childManagementGroups.Children) {
    Start-PolicyInitiativeRemediationForMG -ManagementGroupId $mg.Id -ManagementGroupName $mg.DisplayName -parentManagementGroupName $parentManagementGroupName -PolicyInitiativeAssignmentNames $PolicyInitiativeAssignmentNames -PolicyInitiativeDefinitionName $PolicyInitiativeDefinitionName
}

Write-Host "`nAll specified policy initiative remediations have been initiated for child management groups under '$parentManagementGroupName'."

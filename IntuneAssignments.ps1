# Connect and change schema
Connect-MSGraph 
Update-MSGraphEnvironment -SchemaVersion 'beta' -Quiet
Connect-MSGraph -Quiet

function get-assignment {

    foreach ($Deployment in $Deployments) {
        $Assignment = ""
        write-host $Deployment.displayName
        
        # Check request type

        # Configuration Policy
        if ($Deployment."@odata.type" -like "*configuration") {
            $Assignment = (Get-IntuneDeviceConfigurationPolicyAssignment -deviceConfigurationId $Deployment.deviceConfigurationId).target
        }
        # Compliance Policy
        elseif ($Deployment."@odata.type" -like "*CompliancePolicy") {
            $Assignment = (Get-IntuneDeviceCompliancePolicyAssignment -deviceCompliancePolicyId $Deployment.deviceCompliancePolicyId).target
        }   
        # Application
        elseif ($Deployment."@odata.type" -like "*App" -or $Deployment."@odata.type" -like "*MSI" ) {
            $Assignment = (Get-IntuneMobileAppAssignment -MobileAppId $Deployment.MobileAppId).target
            write-host "     Assignment:      " (Get-IntuneMobileAppAssignment -MobileAppId $Deployment.MobileAppId).intent
        } 

        # check for single or multiple assignments
        if ($Assignment -is [array]) {
    
            $n = 0
    
            do {
                if ($Assignment[$n]."@odata.type" -eq "#microsoft.graph.groupAssignmentTarget") {
                    $displayname = (get-groups -groupId $Assignment[$n].groupid).displayName
                    Write-Host "     Included groups: " $displayname 
                }
                else {
                    $displayname = (get-groups -groupId $Assignment[$n].groupid).displayName
                    Write-Host "     Excluded groups: " $displayname 
                }        
                $n = $n + 1
            } while ($n -lt $Assignment.count)
        }  
        else {
            $displayname = (get-groups -groupId $Assignment.groupid).displayName
            Write-Host "     Included groups: " $displayname 
        }
    }
    # insert blank line after request type
    write-host "`n"
}

# Get the number of Device Configurations and assignments
$deployments = get-IntuneDeviceConfigurationPolicy
write-host "number of Device Configurations found: " $deployments.count -ForegroundColor Yellow
get-assignment

# Get the number of Compliance Policies and assignments
$deployments = Get-IntuneDeviceCompliancePolicy
write-host "number of Compliance Policies found: " $deployments.count -ForegroundColor Yellow
get-assignment

# Get the number of Applications and assignments
$deployments = Get-IntuneMobileApp -Filter "isAssigned eq true" 
write-host "number of Apps found: " $deployments.count -ForegroundColor Yellow
get-assignment
# Application (client) ID, tenant Name and secret
$clientId = ""
$tenantName = ""
$clientSecret = ""
$resource = "https://graph.microsoft.com/"

#Variables
$GroupName = "DEMO_Windows10"

# Site configuration
$SiteCode = "" # Site code 
$ProviderMachineName = "" # SMS Provider machine name

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

$ReqTokenBody = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    client_Id     = $clientID
    Client_Secret = $clientSecret
} 

$TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody

#Get Groups
$apiUrl = 'https://graph.microsoft.com/beta/groups'
$Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Tokenresponse.access_token)" } -Uri $apiUrl -Method Get
$Groups = ($Data | select-object Value).Value

Foreach ($Group in $Groups){
    if ($group.displayName -eq $GroupName){

        #Check if SCCM Collection exist
        if (!(Get-CMDeviceCollection -Name $GroupName)){
            New-CMDeviceCollection -Name $GroupName -LimitingCollectionId SMS00001
        }
        else {
            Remove-CMDeviceCollectionDirectMembershipRule -CollectionName $GroupName -ResourceName *
        }

        #Get Group Members
        $id = $Group.id
        $apiUrl = "https://graph.microsoft.com/beta/groups/$id/members"
        $Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Tokenresponse.access_token)" } -Uri $apiUrl -Method Get
        $GroupMembers = ($Data | select-object Value).Value 

        foreach ($GroupMember in $GroupMembers){
            $CMDevice = Get-CMDevice -Name $GroupMember.displayName
            Add-CMDeviceCollectionDirectMembershipRule -CollectionName $GroupName -ResourceId $CMDevice.ResourceID
        } 
    }
} 
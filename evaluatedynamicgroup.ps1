# Application (client) ID, tenant Name and secret
$clientId = ""
$tenantName = ""
$clientSecret = ""
$Username = ""
$Password = ""


$ReqTokenBody = @{
    Grant_Type    = "Password"
    client_Id     = $clientID
    Client_Secret = $clientSecret
    Username      = $Username
    Password      = $Password
    Scope         = "https://graph.microsoft.com/.default"
} 

$TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody 

$body = @{ 
    "memberId" = "" 
    "membershipRule" = '(device.deviceOSType -match "IPad" or device.deviceOSType -match "IPhone" )'
 } | ConvertTo-Json


$apiUrl = 'https://graph.microsoft.com/beta/groups/evaluateDynamicMembership '
$data = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Tokenresponse.access_token)" } -Uri $apiUrl -Method Post -ContentType 'application/json' -Body $body

write-host "Rule: " $data.membershipRule "Result: " $data.membershipRuleEvaluationResult
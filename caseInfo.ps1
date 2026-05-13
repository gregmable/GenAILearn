$clientId = "72957161055032363202"
$clientSecret = "9672C0DCDF4C2A8C6D442590B59935D6"
$tokenUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token"
$caseTypeUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/api/application/v2/casetypes/DMOrg-GridMana-Work-GridMonitoring"

$body = @{ grant_type = "client_credentials"; client_id = $clientId; client_secret = $clientSecret }
$tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
$accessToken = $tokenResponse.access_token

$headers = @{ "Authorization" = "Bearer $accessToken"; "Accept" = "application/json" }
$caseTypeData = Invoke-RestMethod -Uri $caseTypeUrl -Headers $headers -Method Get
$caseTypeData | ConvertTo-Json -Depth 10

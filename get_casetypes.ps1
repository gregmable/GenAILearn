$clientId = '72957161055032363202'
$clientSecret = '9672C0DCDF4C2A8C6D442590B59935D6'
$baseUrl = 'https://lab-16330-us-east-1.internal.pegalabs.io'
$tokenEndpoint = "$baseUrl/prweb/PRRestService/oauth2/v1/token"
$caseTypesEndpoint = "$baseUrl/prweb/api/application/v2/casetypes"
$body = @{ grant_type = 'client_credentials'; client_id = $clientId; client_secret = $clientSecret }
$tokenResponse = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded'
$headers = @{ Authorization = "Bearer $($tokenResponse.access_token)" }
$caseTypesResponse = Invoke-RestMethod -Uri $caseTypesEndpoint -Method Get -Headers $headers
$caseTypesResponse.caseTypes | Select-Object ID, name | Format-Table -HideTableHeaders

$clientId = "55807741833173538590"
$clientSecret = "AB0CEEA87C9C6949F72B0E25137D777E"
$tokenUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token"
$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
}
$tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
$accessToken = $tokenResponse.access_token

$endpoints = @(
    "/prweb/api/application/v2/casetypes",
    "/prweb/api/application/v2/caseTypes",
    "/prweb/api/v2/casetypes",
    "/prweb/api/application/v1/casetypes"
)

$baseUrl = "https://lab-16330-us-east-1.internal.pegalabs.io"
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Accept"        = "application/json"
}

foreach ($endpoint in $endpoints) {
    Write-Host "Testing $endpoint..."
    try {
        $response = Invoke-WebRequest -Uri ($baseUrl + $endpoint) -Headers $headers -Method Get
        Write-Host "Status: $($response.StatusCode)"
        Write-Host "Body: $($response.Content)"
        if ($response.StatusCode -eq 200) {
           break
        }
    } catch {
        Write-Host "Error at $endpoint`: $_"
    }
}

$clientId = '55807741833173538590'
$clientSecret = 'AB0CEEA87C9C6949F72B0E25137D777E'
$tokenUrl = 'https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token'
$base64Auth = 'NTU4MDc3NDE4MzMxNzM1Mzg1OTA6QUIwQ0VFQTg3QzlDNjk0OUY3MkIwRTI1MTM3RDc3N0U='

try {
    $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Headers @{Authorization="Basic $base64Auth"} -Body "grant_type=client_credentials" -ContentType "application/x-www-form-urlencoded"
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
                # Success
            }
        } catch {
            Write-Host "Error at $endpoint: $(_)"
        }
    }
} catch {
    Write-Host "Token Error: $(_)"
}

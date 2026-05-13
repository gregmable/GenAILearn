$clientId = "72957161055032363202"
$clientSecret = "9672C0DCDF4C2A8C6D442590B59935D6"
$tokenUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token"

$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
}

try {
    $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
    $accessToken = $tokenResponse.access_token
    Write-Host "Token obtained successfully."

    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type"  = "application/json"
    }

    $caseData = @{
        "caseTypeID" = "DMOrg-GridMana-Work-GridMonitoring"
    }

    $createUrl1 = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/api/application/v2/cases"
    
    Write-Host "Attempting creation at $createUrl1..."
    try {
        $response = Invoke-RestMethod -Uri $createUrl1 -Method Post -Headers $headers -Body ($caseData | ConvertTo-Json)
        Write-Host "Success at Endpoint 1"
        $response | ConvertTo-Json -Depth 10
    } catch {
        Write-Host "Failed at Endpoint 1: $($_.Exception.Message)"
        if ($_.ErrorDetails.Message) { Write-Host "Error Details: $($_.ErrorDetails.Message)" }
        
        $typesUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/api/application/v2/case-types"
        Write-Host "Fetching case types to resolve link..."
        $typesResponse = Invoke-RestMethod -Uri $typesUrl -Method Get -Headers $headers
        $targetType = $typesResponse.caseTypes | Where-Object { $_.ID -eq "DMOrg-GridMana-Work-GridMonitoring" }
        
        if ($targetType -and $targetType.links.create) {
             $createUrl2 = $targetType.links.create.href
             if ($createUrl2 -notlike "http*") {
                $baseUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/api/application/v2"
                $createUrl2 = "$baseUrl$createUrl2"
             }

             Write-Host "Attempting creation at resolved endpoint: $createUrl2"
             try {
                $response = Invoke-RestMethod -Uri $createUrl2 -Method Post -Headers $headers -Body ($caseData | ConvertTo-Json)
                Write-Host "Success at Endpoint 2"
                $response | ConvertTo-Json -Depth 10
             } catch {
                Write-Host "Failed at Endpoint 2: $($_.Exception.Message)"
                if ($_.ErrorDetails.Message) { Write-Host "Error Details: $($_.ErrorDetails.Message)" }
             }
        } else {
            Write-Host "Could not find create link in case-types response."
            $typesResponse | ConvertTo-Json -Depth 5
        }
    }
} catch {
    Write-Host "Failed: $($_.Exception.Message)"
}

$clientId = "72957161055032363202"
$clientSecret = "9672C0DCDF4C2A8C6D442590B59935D6"
$tokenUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token"
$baseUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/api/application/v2"
$caseType = "DMOrg-GridMana-Work-GridMonitoring"

try {
    $body = @{ grant_type = "client_credentials"; client_id = $clientId; client_secret = $clientSecret }
    $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
    $accessToken = $tokenResponse.access_token
    Write-Host "Token obtained."
} catch {
    Write-Error "Failed to get token: $_"
    exit
}

$actions = @("pyStartCase", "pyCreateCase", "pxCreateTopCase", "pyDefault", "pyNew")
$headers = @{ "Authorization" = "Bearer $accessToken"; "Accept" = "application/json" }

foreach ($action in $actions) {
    foreach ($suffix in @("", "?viewType=page")) {
        $url = "$baseUrl/casetypes/$caseType/actions/$action$suffix"
        try {
            $response = Invoke-WebRequest -Uri $url -Headers $headers -Method Get
            Write-Host "`nResult for $url"
            Write-Host "Status: $($response.StatusCode)"
            $response.Content
        } catch {
            Write-Host "`nResult for $url"
            if ($_.Exception.Response) {
                Write-Host "Status: $($_.Exception.Response.StatusCode.Value__)"
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                Write-Host "Response: $($reader.ReadToEnd())"
            } else {
                Write-Host "Error: $($_.Exception.Message)"
            }
        }
    }
}

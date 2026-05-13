$clientId = "72957161055032363202"
$clientSecret = "9672C0DCDF4C2A8C6D442590B59935D6"
$tokenUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token"
$mcpUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/app/GridMana/api/service/v1/mcp/DMOrg-GridMana-Work!Grid"

try {
    Write-Host "1. Getting token..."
    $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body @{grant_type="client_credentials";client_id=$clientId;client_secret=$clientSecret}
    $token = $tokenResponse.access_token
    Write-Host "   Token obtained: $($token.Substring(0,20))..."

    $headers = @{ 
        Authorization = "Bearer $token"
        Accept = "application/json, text/event-stream"
        "Content-Type" = "application/json"
    }

    Write-Host "2. Sending initialize..."
    $initPayload = @{ jsonrpc="2.0"; id=1; method="initialize"; params=@{ protocolVersion="2024-11-05"; capabilities=@{}; clientInfo=@{ name="pwsh-debug"; version="1.0" } } } | ConvertTo-Json -Compress
    Write-Host "   Payload: $initPayload"
    
    $initResp = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $initPayload
    Write-Host "   Status: $($initResp.StatusCode)"
    Write-Host "   Response Body: $($initResp.Content)"
    
    Write-Host "3. All Response Headers:"
    foreach ($hkey in $initResp.Headers.Keys) {
        $val = $initResp.Headers[$hkey]
        Write-Host "   Header: $hkey = $val"
    }
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        try {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $body = $reader.ReadToEnd()
            Write-Host "Response body: $body"
        } catch {
            Write-Host "Could not read response body."
        }
    }
}

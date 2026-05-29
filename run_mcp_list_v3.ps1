$params = @{
    Method = "Post"
    Uri = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token"
    ContentType = "application/x-www-form-urlencoded"
    Body = @{
        grant_type = "client_credentials"
        client_id = "72957161055032363202"
        client_secret = "9672C0DCDF4C2A8C6D442590B59935D6"
    }
}
$tokenResponse = Invoke-RestMethod @params
$accessToken = $tokenResponse.access_token

$headers = @{
    Authorization = "Bearer $accessToken"
    Accept = "application/json, text/event-stream"
}

$mcpUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/app/fraud-investigation/api/service/v1/mcp/O91ILP-FraudInv-Work!Fraud"

$initPayload = @{
    jsonrpc = "2.0"
    method = "initialize"
    params = @{
        protocolVersion = "2024-11-05"
        capabilities = @{}
        clientInfo = @{
            name = "pwsh-client"
            version = "1.0.0"
        }
    }
    id = 1
} | ConvertTo-Json

$initResp = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $initPayload -ContentType "application/json" -SkipHttpErrorCheck

# Get all header keys to find the session id header precisely
$sessionIdHeaderKey = $initResp.Headers.Keys | Where-Object { $_ -like "*mcp-session-id*" } | Select-Object -First 1
$sessionId = $initResp.Headers[$sessionIdHeaderKey]

$sessionHeaders = $headers.Clone()
$sessionHeaders[$sessionIdHeaderKey] = $sessionId

$notifPayload = @{
    jsonrpc = "2.0"
    method = "notifications/initialized"
} | ConvertTo-Json
$notifResp = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $sessionHeaders -Body $notifPayload -ContentType "application/json" -SkipHttpErrorCheck

$listPayload = @{
    jsonrpc = "2.0"
    method = "tools/list"
    id = 2
} | ConvertTo-Json
$listResp = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $sessionHeaders -Body $listPayload -ContentType "application/json" -SkipHttpErrorCheck

Write-Output "init status: $($initResp.StatusCode)"
Write-Output "notif status: $($notifResp.StatusCode)"
Write-Output "list status: $($listResp.StatusCode)"
Write-Output "response content: $($listResp.Content.Substring(0, [Math]::Min(800, $listResp.Content.Length)))"

$params = @{
    Method = 'Post'
    Uri = 'https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token'
    ContentType = 'application/x-www-form-urlencoded'
    Body = @{
        grant_type = 'client_credentials'
        client_id = '72957161055032363202'
        client_secret = '9672C0DCDF4C2A8C6D442590B59935D6'
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
    id = 1
    method = "initialize"
    params = @{
        protocolVersion = "2024-11-05"
        capabilities = @{}
        clientInfo = @{ name = "pwsh-client"; version = "1.0.0" }
    }
} | ConvertTo-Json -Compress

$initResp = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $initPayload -ContentType "application/json"
$sessionId = $initResp.Headers["mcp-session-id"]

$notifPayload = @{
    jsonrpc = "2.0"
    method = "notifications/initialized"
} | ConvertTo-Json -Compress
$null = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers ($headers + @{"mcp-session-id" = $sessionId}) -Body $notifPayload -ContentType "application/json"

$listPayload = @{
    jsonrpc = "2.0"
    id = 2
    method = "tools/list"
} | ConvertTo-Json -Compress
$listResp = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers ($headers + @{"mcp-session-id" = $sessionId}) -Body $listPayload -ContentType "application/json"

$listObj = $listResp.Content | ConvertFrom-Json
$listObj.result.tools.name

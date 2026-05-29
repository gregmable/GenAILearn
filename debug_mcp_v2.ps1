$mcpUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/app/GridMana/api/service/v1/mcp/DMOrg-GridMana-Work!Grid"
$clientId = "72957161055032363202"
$clientSecret = "9672C0DCDF4C2A8C6D442590B59935D6"
$tokenUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token"
try {
    $authBody = @{ grant_type = "client_credentials"; client_id = $clientId; client_secret = $clientSecret }
    $authRes = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $authBody -ContentType "application/x-www-form-urlencoded"
    $token = $authRes.access_token
    $headers = @{ "Authorization" = "Bearer $token"; "Accept" = "application/json, text/event-stream"; "Content-Type" = "application/json" }
    
    $initPayload = @{ jsonrpc = "2.0"; id = 1; method = "initialize"; params = @{ protocolVersion = "2024-10-07"; capabilities = @{ tools = @{} }; clientInfo = @{ name = "pwsh-client"; version = "1.0.0" } } }
    $initRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body ($initPayload | ConvertTo-Json -Depth 10) -UseBasicParsing
    $mcpSessionId = $initRes.Headers["mcp-session-id"]
    $headers["mcp-session-id"] = $mcpSessionId
    
    $notifPayload = @{ jsonrpc = "2.0"; method = "notifications/initialized" }
    $null = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body ($notifPayload | ConvertTo-Json -Depth 10) -UseBasicParsing
    
    $listPayload = @{ jsonrpc = "2.0"; id = 3; method = "tools/list" }
    $listRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body ($listPayload | ConvertTo-Json -Depth 10) -UseBasicParsing
    $parsed = $listRes.Content | ConvertFrom-Json
    if ($parsed.result.tools) {
        $parsed.result.tools.name
    } else {
        $listRes.Content
    }
} catch {
    if ($_.Exception.Response) {
        $_.Exception.Response.Content.ReadAsStringAsync().Result
    } else {
        $_.Exception.Message
    }
}

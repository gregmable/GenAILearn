$mcp = Get-Content mcp.json | ConvertFrom-Json
$server = $mcp.servers.'fraud-investigation-mcp'
$auth = $server.auth

# 1. Get OAuth Token
$tokenBody = @{
    grant_type    = "client_credentials"
    client_id     = $auth.clientId
    client_secret = $auth.clientSecret
}
$tokenResponse = Invoke-RestMethod -Uri $auth.tokenUrl -Method Post -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
$accessToken = $tokenResponse.access_token

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Accept"        = "application/json, text/event-stream"
    "Content-Type"  = "application/json"
}

# 2. Call MCP Initialize
$initPayload = @{
    jsonrpc = "2.0"
    id      = 1
    method  = "initialize"
    params  = @{
        protocolVersion = "2024-11-05"
        capabilities    = @{ tools = @{} }
        clientInfo      = @{ name = "pwsh-client"; version = "1.0.0" }
    }
} | ConvertTo-Json

try {
    $initResponse = Invoke-WebRequest -Uri $server.url -Method Post -Body $initPayload -Headers $headers -WebSession $session
    
    # Extract session ID from headers
    $mcpSessionId = $initResponse.Headers["mcp-session-id"]
    if (-not $mcpSessionId) {
        $mcpSessionId = $initResponse.Headers["X-MCP-Session-ID"]
    }
    
    # Also check cookies from the session
    if (-not $mcpSessionId) {
        foreach ($cookie in $session.Cookies.GetCookies($server.url)) {
            if ($cookie.Name -eq "mcp-session-id" -or $cookie.Name -eq "X-MCP-Session-ID") {
                $mcpSessionId = $cookie.Value
                break
            }
        }
    }

    if ($mcpSessionId) {
        $headers["mcp-session-id"] = $mcpSessionId
    }

    # Send notifications/initialized
    $notifPayload = @{
        jsonrpc = "2.0"
        method  = "notifications/initialized"
    } | ConvertTo-Json
    Invoke-WebRequest -Uri $server.url -Method Post -Body $notifPayload -Headers $headers -WebSession $session | Out-Null

    # 4. List tools
    $listPayload = @{
        jsonrpc = "2.0"
        id      = 2
        method  = "tools/list"
    } | ConvertTo-Json
    $listResponse = Invoke-WebRequest -Uri $server.url -Method Post -Body $listPayload -Headers $headers -WebSession $session
    $toolsJson = $listResponse.Content | ConvertFrom-Json
    
    if ($toolsJson.result.tools) {
        $toolsJson.result.tools.name
    } else {
        $toolsJson | ConvertTo-Json -Depth 10
    }
} catch {
    $_.Exception.Message
    if ($_.ErrorDetails.Message) {
        $_.ErrorDetails.Message
    }
}

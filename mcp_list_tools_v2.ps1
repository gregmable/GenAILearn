$config = Get-Content -Raw mcp.json | ConvertFrom-Json
$server = $config.servers.'fraud-investigation-mcp'
$auth = $server.auth

# 1. Get OAuth token
$body = @{
    grant_type    = 'client_credentials'
    client_id     = $auth.clientId
    client_secret = $auth.clientSecret
}
$tokenResponse = Invoke-RestMethod -Uri $auth.tokenUrl -Method Post -ContentType 'application/x-www-form-urlencoded' -Body $body
$accessToken = $tokenResponse.access_token

# 2. Setup Session and Headers
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$headers = @{
    'Authorization' = 'Bearer ' + $accessToken
    'Accept'        = 'application/json, text/event-stream'
    'Content-Type'  = 'application/json'
}

# 3. Initialize
$initializeBody = @{
    jsonrpc = '2.0'
    id      = 1
    method  = 'initialize'
    params  = @{
        protocolVersion = '2024-11-05'
        capabilities    = @{}
        clientInfo      = @{ name = 'pwsh-client'; version = '1.0.0' }
    }
} | ConvertTo-Json
$initResponse = Invoke-WebRequest -Uri $server.url -Method Post -Headers $headers -Body $initializeBody -WebSession $session
$initContent = $initResponse.Content | ConvertFrom-Json
$mcpSessionId = $initContent.result.'mcp-session-id'.ToString()

# 4. Capture JSESSIONID
$jsessionid = $session.Cookies.GetCookies($server.url) | Where-Object { $_.Name -eq 'JSESSIONID' } | Select-Object -ExpandProperty Value

# 5. Set Headers for further calls
$headers['mcp-session-id'] = $mcpSessionId
if ($jsessionid) {
    $headers['Cookie'] = "JSESSIONID=$jsessionid"
}

# 6. Send notifications/initialized
$initializedNotification = @{
    jsonrpc = '2.0'
    method  = 'notifications/initialized'
} | ConvertTo-Json
Invoke-WebRequest -Uri $server.url -Method Post -Headers $headers -Body $initializedNotification -WebSession $session | Out-Null

# 7. Call tools/list
$listToolsBody = @{
    jsonrpc = '2.0'
    id      = 2
    method  = 'tools/list'
} | ConvertTo-Json

$response = Invoke-WebRequest -Uri $server.url -Method Post -Headers $headers -Body $listToolsBody -WebSession $session -ErrorAction SilentlyContinue

if ($response.StatusCode -ne 200) {
    # Retry with query param
    $retryUrl = "$($server.url)?sessionId=$mcpSessionId"
    $response = Invoke-WebRequest -Uri $retryUrl -Method Post -Headers $headers -Body $listToolsBody -WebSession $session -ErrorAction SilentlyContinue
}

# 8. Final Status and Output
Write-Output "Status: $($response.StatusCode)"
if ($response.StatusCode -eq 200) {
    $content = $response.Content | ConvertFrom-Json
    $content.result.tools | ForEach-Object { $_.name }
} else {
    $response.Content
}

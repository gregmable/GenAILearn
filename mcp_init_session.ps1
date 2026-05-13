$clientId = "72957161055032363202"
$clientSecret = "9672C0DCDF4C2A8C6D442590B59935D6"
$tokenUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token"
$mcpUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/app/GridMana/api/service/v1/mcp/DMOrg-GridMana-Work!Grid"
$sessionFile = ".\mcp_session.json"

# Get token
$authRes = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body @{grant_type='client_credentials';client_id=$clientId;client_secret=$clientSecret}
$token = $authRes.access_token
Write-Output "Token obtained"

$headers = @{
    "Authorization" = "Bearer $token"
    "Accept"        = "application/json, text/event-stream"
    "Content-Type"  = "application/json"
}

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

# Initialize
$initPayload = @{
    jsonrpc = "2.0"
    id = 1
    method = "initialize"
    params = @{
        protocolVersion = "2024-11-05"
        capabilities = @{ tools = @{} }
        clientInfo = @{ name = "queryCases"; version = "1.0" }
    }
} | ConvertTo-Json -Depth 10

Write-Output "Initializing..."
$initRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $initPayload -WebSession $session -UseBasicParsing
Write-Output "Init Status: $($initRes.StatusCode)"

# Extract session ID
$mcpSessionId = $initRes.Headers["mcp-session-id"]
Write-Output "Session ID: $mcpSessionId"

# Extract JSESSIONID
$jsessionId = $null
foreach ($cookie in $session.Cookies.GetCookies($mcpUrl)) {
    if ($cookie.Name -eq "JSESSIONID") {
        $jsessionId = $cookie.Value
        break
    }
}

# Save session info to file for later use
$sessionInfo = @{
    mcpSessionId = $mcpSessionId
    jsessionId = $jsessionId
    token = $token
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}
$sessionInfo | ConvertTo-Json | Set-Content -Path $sessionFile
Write-Output "Session saved to $sessionFile"
Write-Output "JSESSIONID: $jsessionId"

# Notification
$headers["mcp-session-id"] = $mcpSessionId
$notifPayload = @{
    jsonrpc = "2.0"
    method = "notifications/initialized"
} | ConvertTo-Json -Depth 10

Write-Output "Sending notification..."
$notifRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $notifPayload -WebSession $session -UseBasicParsing
Write-Output "Notification Status: $($notifRes.StatusCode)"

$clientId = "72957161055032363202"
$clientSecret = "9672C0DCDF4C2A8C6D442590B59935D6"
$tokenUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token"
$mcpUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/app/GridMana/api/service/v1/mcp/DMOrg-GridMana-Work!Grid"

$authBody = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
}

$authRes = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $authBody -ContentType "application/x-www-form-urlencoded"
$token = $authRes.access_token
Write-Host "Token: $($token.Substring(0,20))..."

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
        clientInfo = @{ name = "debug"; version = "1.0" }
    }
}

Write-Host "`n=== INITIALIZE ==="
$initRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body ($initPayload | ConvertTo-Json -Depth 10) -WebSession $session -UseBasicParsing
Write-Host "Status: $($initRes.StatusCode)"
Write-Host "Content: $($initRes.Content)"
Write-Host "Headers:"
$initRes.Headers.GetEnumerator() | ForEach-Object { Write-Host "  $($_.Key): $($_.Value)" }

$mcpSessionId = $initRes.Headers["mcp-session-id"]
$headers["mcp-session-id"] = $mcpSessionId
Write-Host "Session ID: $mcpSessionId"

# Show session cookies
Write-Host "`nSession Cookies:"
$session.Cookies.GetCookies($mcpUrl) | ForEach-Object { Write-Host "  $($_.Name) = $($_.Value)" }

# Notification
$notifPayload = @{
    jsonrpc = "2.0"
    method = "notifications/initialized"
}

Write-Host "`n=== NOTIFICATION ==="
$notifRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body ($notifPayload | ConvertTo-Json -Depth 10) -WebSession $session -UseBasicParsing
Write-Host "Status: $($notifRes.StatusCode)"
Write-Host "Content: $($notifRes.Content)"

# Show session cookies after notification
Write-Host "`nSession Cookies after notification:"
$session.Cookies.GetCookies($mcpUrl) | ForEach-Object { Write-Host "  $($_.Name) = $($_.Value)" }

# Try tools/list
$listPayload = @{
    jsonrpc = "2.0"
    id = 3
    method = "tools/list"
}

Write-Host "`n=== TOOLS/LIST ==="
Write-Host "Request headers being sent:"
$headers.GetEnumerator() | ForEach-Object { Write-Host "  $($_.Key): $($_.Value)" }

try {
    $listRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body ($listPayload | ConvertTo-Json -Depth 10) -WebSession $session -UseBasicParsing
    Write-Host "Status: $($listRes.StatusCode)"
    Write-Host "Content: $($listRes.Content)"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $errorResponse = $reader.ReadToEnd()
    Write-Host "Error Response: $errorResponse"
}

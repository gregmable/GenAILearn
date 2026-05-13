param(
    [switch]$Raw
)

$clientId = "72957161055032363202"
$clientSecret = "9672C0DCDF4C2A8C6D442590B59935D6"
$tokenUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token"
$mcpUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/app/GridMana/api/service/v1/mcp/DMOrg-GridMana-Work!Grid"

$authBody = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
}

try {
    $authRes = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $authBody -ContentType "application/x-www-form-urlencoded"
    $token = $authRes.access_token
    Write-Output "Access Token obtained."
} catch {
    Write-Output "Token Error: $($_.Exception.Message)"
    exit
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Accept"        = "application/json, text/event-stream"
    "Content-Type"  = "application/json"
}

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

# Call initialize
$initPayload = @{
    jsonrpc = "2.0"
    id = 1
    method = "initialize"
    params = @{
        protocolVersion = "2024-10-07"
        capabilities = @{ tools = @{} }
        clientInfo = @{ name = "pwsh-client"; version = "1.0.0" }
    }
}
$initRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body ($initPayload | ConvertTo-Json -Depth 10) -WebSession $session -UseBasicParsing
Write-Output "Initialize Status: $($initRes.StatusCode)"

# Stateful MCP servers require the session id from initialize on all subsequent calls.
$mcpSessionId = $initRes.Headers["mcp-session-id"]
if ([string]::IsNullOrWhiteSpace($mcpSessionId)) {
    Write-Output "Initialize Error: mcp-session-id header missing."
    exit
}
$headers["mcp-session-id"] = $mcpSessionId
Write-Output "MCP Session ID: $mcpSessionId"

# Call notifications/initialized
$notifPayload = @{
    jsonrpc = "2.0"
    method = "notifications/initialized"
}
$notifRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body ($notifPayload | ConvertTo-Json -Depth 10) -WebSession $session -UseBasicParsing
Write-Output "Notification Status: $($notifRes.StatusCode)"

# Check available tools
$listPayload = @{
    jsonrpc = "2.0"
    id = 3
    method = "tools/list"
}
try {
    $listRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body ($listPayload | ConvertTo-Json -Depth 10) -WebSession $session -UseBasicParsing
    Write-Output "List Tools Status: $($listRes.StatusCode)"
    if ($Raw) {
        Write-Output "List Tools Body: $($listRes.Content)"
        exit
    }

    $parsed = $listRes.Content | ConvertFrom-Json
    $tools = $parsed.result.tools

    if (-not $tools) {
        Write-Output "No tools returned."
        exit
    }

    $toolRows = $tools | ForEach-Object {
        [pscustomobject]@{
            Name = $_.name
        }
    }

    Write-Output "Tools:"
    $toolRows | Format-Table -AutoSize
} catch {
    Write-Output "List Tools Error: $($_.Exception.Message)"
}

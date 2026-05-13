$clientId = "72957161055032363202"
$clientSecret = "9672C0DCDF4C2A8C6D442590B59935D6"
$tokenUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token"
$mcpUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/app/GridMana/api/service/v1/mcp/DMOrg-GridMana-Work!Grid"

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

# CRITICAL: Extract and persist session ID
$mcpSessionId = $initRes.Headers["mcp-session-id"]
Write-Output "Session ID from init: $mcpSessionId"

# Add session ID to headers for ALL future requests
$headers["mcp-session-id"] = $mcpSessionId

# Extract JSESSIONID cookie and persist it
$jsessionId = $null
foreach ($cookie in $session.Cookies.GetCookies($mcpUrl)) {
    if ($cookie.Name -eq "JSESSIONID") {
        $jsessionId = $cookie.Value
        Write-Output "JSESSIONID: $jsessionId"
        break
    }
}

# Notification
$notifPayload = @{
    jsonrpc = "2.0"
    method = "notifications/initialized"
} | ConvertTo-Json -Depth 10

Write-Output "Sending notification..."
$notifRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $notifPayload -WebSession $session -UseBasicParsing
Write-Output "Notification Status: $($notifRes.StatusCode)"

# CRITICAL: Verify mcp-session-id is still in headers
Write-Output "Headers before tools/list:"
Write-Output "  mcp-session-id: $($headers['mcp-session-id'])"
Write-Output "  Authorization: $($headers['Authorization'].Substring(0,20))..."

# List tools
$listPayload = @{
    jsonrpc = "2.0"
    id = 3
    method = "tools/list"
} | ConvertTo-Json -Depth 10

Write-Output "Listing tools..."
try {
    $listRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $listPayload -WebSession $session -UseBasicParsing -SkipHttpErrorCheck
    Write-Output "List Status: $($listRes.StatusCode)"
    Write-Output "List Response: $($listRes.Content)"
    
    if ($listRes.StatusCode -eq 200) {
        $toolsList = $listRes.Content | ConvertFrom-Json
        Write-Output "`nAvailable tools:"
        $toolsList.result.tools | ForEach-Object { Write-Output "  - $($_.name)" }
    }
} catch {
    Write-Output "List Error: $_"
}

# Call Get_Grid_Case_Types
Write-Output "`nCalling Get_Grid_Case_Types..."
$callPayload = @{
    jsonrpc = "2.0"
    id = 4
    method = "tools/call"
    params = @{
        name = "Get_Grid_Case_Types"
        arguments = @{}
    }
} | ConvertTo-Json -Depth 10

try {
    $callRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $callPayload -WebSession $session -UseBasicParsing -SkipHttpErrorCheck
    Write-Output "Call Status: $($callRes.StatusCode)"
    Write-Output "Call Response: $($callRes.Content)"
} catch {
    Write-Output "Call Error: $_"
}

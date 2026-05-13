$clientId = "72957161055032363202"
$clientSecret = "9672C0DCDF4C2A8C6D442590B59935D6"
$tokenUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token"
$mcpUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/app/GridMana/api/service/v1/mcp/DMOrg-GridMana-Work!Grid"

# Get token
$authRes = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body @{
    grant_type    = 'client_credentials'
    client_id     = $clientId
    client_secret = $clientSecret
} -ContentType 'application/x-www-form-urlencoded'

$token = $authRes.access_token

# Use Dictionary to preserve Accept header exactly as required
$hdrs = [System.Collections.Generic.Dictionary[string,string]]::new()
$hdrs["Authorization"] = "Bearer $token"
$hdrs["Accept"]        = "application/json, text/event-stream"
$hdrs["Content-Type"]  = "application/json"

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

# Initialize
$initBody = @{
    jsonrpc = "2.0"; id = 1; method = "initialize"
    params = @{
        protocolVersion = "2024-11-05"
        capabilities    = @{}
        clientInfo      = @{ name = "getGridCaseTypes"; version = "1.0" }
    }
} | ConvertTo-Json -Depth 10 -Compress

$initRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $hdrs -Body $initBody -WebSession $session -UseBasicParsing -SkipHttpErrorCheck
$sid = @($initRes.Headers["mcp-session-id"])[0]
if (-not $sid) { Write-Error "No mcp-session-id returned"; exit 1 }
$hdrs["mcp-session-id"] = $sid

# Send initialized notification
$notifBody = '{"jsonrpc":"2.0","method":"notifications/initialized"}'
Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $hdrs -Body $notifBody -WebSession $session -UseBasicParsing -SkipHttpErrorCheck | Out-Null

# Call Get_Grid_Case_Types
$callBody = @{
    jsonrpc = "2.0"; id = 2; method = "tools/call"
    params  = @{ name = "Get_Grid_Case_Types"; arguments = @{} }
} | ConvertTo-Json -Depth 5 -Compress

$callRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $hdrs -Body $callBody -WebSession $session -UseBasicParsing -SkipHttpErrorCheck

if ($callRes.StatusCode -ne 200) {
    Write-Error "Error $($callRes.StatusCode): $($callRes.Content)"
    exit 1
}

$parsed = $callRes.Content | ConvertFrom-Json
$text = $parsed.result.content[0].text
if ($text) {
    $data = $text | ConvertFrom-Json
    $caseTypes = if ($data.caseTypes) { $data.caseTypes } elseif ($data.Response.caseTypes) { $data.Response.caseTypes } else { $null }
    if ($caseTypes) {
        $caseTypes | Select-Object ID, name | Format-Table -AutoSize
    } else {
        Write-Output $text
    }
} else {
    Write-Output $callRes.Content
}

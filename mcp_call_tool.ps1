$mcpUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/app/GridMana/api/service/v1/mcp/DMOrg-GridMana-Work!Grid"
$sessionFile = ".\mcp_session.json"

if (-not (Test-Path $sessionFile)) {
    Write-Output "Error: $sessionFile not found. Run mcp_init_session.ps1 first."
    exit
}

# Load session info
$sessionInfo = Get-Content -Path $sessionFile | ConvertFrom-Json
$mcpSessionId = $sessionInfo.mcpSessionId
$token = $sessionInfo.token
$jsessionId = $sessionInfo.jsessionId

Write-Output "Using saved session:"
Write-Output "  Session ID: $mcpSessionId"
Write-Output "  JSESSIONID: $jsessionId"

$headers = @{
    "Authorization" = "Bearer $token"
    "Accept"        = "application/json, text/event-stream"
    "Content-Type"  = "application/json"
    "mcp-session-id" = $mcpSessionId
    "Cookie"        = "JSESSIONID=$jsessionId"
}

# Try tools/list
$listPayload = @{
    jsonrpc = "2.0"
    id = 3
    method = "tools/list"
} | ConvertTo-Json -Depth 10

Write-Output "`nListing tools..."
$listRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $listPayload -UseBasicParsing -SkipHttpErrorCheck
Write-Output "List Status: $($listRes.StatusCode)"
Write-Output "List Response: $($listRes.Content)"

if ($listRes.StatusCode -eq 200) {
    $toolsList = $listRes.Content | ConvertFrom-Json
    Write-Output "`nAvailable tools:"
    $toolsList.result.tools | ForEach-Object { Write-Output "  - $($_.name)" }
}

# Try Get_Grid_Case_Types
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

$callRes = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $callPayload -UseBasicParsing -SkipHttpErrorCheck
Write-Output "Call Status: $($callRes.StatusCode)"
Write-Output "Call Response: $($callRes.Content)"

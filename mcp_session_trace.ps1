$ErrorActionPreference = 'Stop'

$clientId = '72957161055032363202'
$clientSecret = '9672C0DCDF4C2A8C6D442590B59935D6'
$baseUrl = 'https://lab-16330-us-east-1.internal.pegalabs.io'
$tokenUrl = "$baseUrl/prweb/PRRestService/oauth2/v1/token"
$mcpUrl = "$baseUrl/prweb/app/GridMana/api/service/v1/mcp/DMOrg-GridMana-Work!Grid"

function Write-Section($title) {
    Write-Output "`n=== $title ==="
}

function Show-Response($label, $resp) {
    Write-Output "$label STATUS: $($resp.StatusCode)"
    if ($resp.Headers) {
        $sid = $resp.Headers['mcp-session-id']
        if ($sid) { Write-Output "$label mcp-session-id: $sid" }
        $setCookie = $resp.Headers['Set-Cookie']
        if ($setCookie) { Write-Output "$label Set-Cookie: $setCookie" }
    }
    if ($resp.Content) {
        Write-Output "$label BODY:"
        Write-Output $resp.Content
    }
}

function Invoke-RequestSafe {
    param(
        [string]$Label,
        [string]$Uri,
        [hashtable]$Headers,
        [string]$Body,
        $WebSession
    )

    try {
        $resp = Invoke-WebRequest -Uri $Uri -Method Post -Headers $Headers -Body $Body -WebSession $WebSession -UseBasicParsing -SkipHttpErrorCheck
        Show-Response $Label $resp
        return $resp
    }
    catch {
        Write-Output "$Label ERROR: $($_.Exception.Message)"
        throw
    }
}

Write-Section '1) OAuth Token'
$tokenBody = @{ grant_type = 'client_credentials'; client_id = $clientId; client_secret = $clientSecret }
$tokenResp = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $tokenBody -ContentType 'application/x-www-form-urlencoded'
$accessToken = $tokenResp.access_token
if (-not $accessToken) { throw 'No access token returned.' }
Write-Output 'Token acquired: YES'

$commonHeaders = @{
    Authorization = "Bearer $accessToken"
    Accept = 'application/json, text/event-stream'
    'Content-Type' = 'application/json'
}

Write-Section '2) Initialize'
$initPayload = @{
    jsonrpc = '2.0'
    id = 1
    method = 'initialize'
    params = @{
        protocolVersion = '2025-11-25'
        capabilities = @{}
        clientInfo = @{ name = 'pwsh-trace-client'; version = '1.0.0' }
    }
} | ConvertTo-Json -Depth 10

$initResp = Invoke-RequestSafe -Label 'INIT' -Uri $mcpUrl -Headers $commonHeaders -Body $initPayload -WebSession $null
$session = $null
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
# Re-send initialize with a persistent web session so cookies are retained explicitly
$initResp2 = Invoke-RequestSafe -Label 'INIT(PERSISTENT)' -Uri $mcpUrl -Headers $commonHeaders -Body $initPayload -WebSession $session

$sessionId = $initResp2.Headers['mcp-session-id']
$sessionId = @($sessionId)[0]
if (-not $sessionId) {
    throw 'No mcp-session-id returned from initialize.'
}
Write-Output "Captured session id: $sessionId"

$serverProtocol = $null
try {
    $initJson = $initResp2.Content | ConvertFrom-Json
    $serverProtocol = $initJson.result.protocolVersion
} catch {}
if ($serverProtocol) {
    Write-Output "Server protocol version: $serverProtocol"
}

$followHeaders = @{}
$commonHeaders.Keys | ForEach-Object { $followHeaders[$_] = $commonHeaders[$_] }
$followHeaders['mcp-session-id'] = $sessionId

Write-Section '3) notifications/initialized'
$notifPayload = @{ jsonrpc = '2.0'; method = 'notifications/initialized'; params = @{} } | ConvertTo-Json -Depth 5
$notifResp = Invoke-RequestSafe -Label 'NOTIFY' -Uri $mcpUrl -Headers $followHeaders -Body $notifPayload -WebSession $session

Write-Section '4) tools/list (header+cookie)'
$listPayload = @{ jsonrpc = '2.0'; id = 2; method = 'tools/list'; params = @{} } | ConvertTo-Json -Depth 5
$listResp = Invoke-RequestSafe -Label 'TOOLS_LIST' -Uri $mcpUrl -Headers $followHeaders -Body $listPayload -WebSession $session

Write-Section '5) tools/list (query sessionId fallback)'
$fallbackUrl = "$mcpUrl?sessionId=$([uri]::EscapeDataString($sessionId))"
$listResp2 = Invoke-RequestSafe -Label 'TOOLS_LIST_FALLBACK' -Uri $fallbackUrl -Headers $followHeaders -Body $listPayload -WebSession $session

Write-Section 'Done'
Write-Output 'Completed MCP session trace run.'

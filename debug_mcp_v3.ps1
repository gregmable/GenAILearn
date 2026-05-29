$mcpUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/app/GridMana/api/service/v1/mcp/DMOrg-GridMana-Work!Grid"
$clientId = "72957161055032363202"
$clientSecret = "9672C0DCDF4C2A8C6D442590B59935D6"
$tokenUrl = "https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token"
function Invoke-MCP {
    param($method, $params = $null, $id = $null, $headers)
    $payload = @{ jsonrpc = "2.0"; method = $method }
    if ($params) { $payload.params = $params }
    if ($id) { $payload.id = $id }
    try {
        $res = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body ($payload | ConvertTo-Json -Depth 10) -UseBasicParsing
        return $res
    } catch {
        if ($_.Exception.Response) {
            $content = $_.Exception.Response.Content.ReadAsStringAsync().Result
            Write-Error "MCP Error: $content"
        } else {
            Write-Error $_.Exception.Message
        }
        exit
    }
}
$authBody = @{ grant_type = "client_credentials"; client_id = $clientId; client_secret = $clientSecret }
$authRes = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $authBody -ContentType "application/x-www-form-urlencoded"
$token = $authRes.access_token
$headers = @{ "Authorization" = "Bearer $token"; "Accept" = "application/json, text/event-stream"; "Content-Type" = "application/json" }
$initRes = Invoke-MCP -method "initialize" -id 1 -headers $headers -params @{ protocolVersion = "2024-10-07"; capabilities = @{ tools = @{} }; clientInfo = @{ name = "pwsh-client"; version = "1.0.0" } }
$mcpSessionId = $initRes.Headers["mcp-session-id"]
$headers["mcp-session-id"] = $mcpSessionId
$null = Invoke-MCP -method "notifications/initialized" -headers $headers
$listRes = Invoke-MCP -method "tools/list" -id 3 -headers $headers
$parsed = $listRes.Content | ConvertFrom-Json
if ($parsed.result.tools) {
    $parsed.result.tools.name
} else {
    $listRes.Content
}

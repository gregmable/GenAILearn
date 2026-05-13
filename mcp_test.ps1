$clientId='72957161055032363202'
$clientSecret='9672C0DCDF4C2A8C6D442590B59935D6'
$tokenUrl='https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token'
$mcpUrl='https://lab-16330-us-east-1.internal.pegalabs.io/prweb/app/GridMana/api/service/v1/mcp/DMOrg-GridMana-Work!Grid'

try {
    $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body @{grant_type='client_credentials';client_id=$clientId;client_secret=$clientSecret}
    $token = $tokenResponse.access_token
    $headers = @{ Authorization = "Bearer $token"; Accept = "application/json, text/event-stream"; "Content-Type" = "application/json" }
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

    Write-Host "--- INITIALIZE ---"
    $initPayload = @{ jsonrpc="2.0"; id=1; method="initialize"; params=@{ protocolVersion="2024-11-05"; capabilities=@{}; clientInfo=@{ name="pwsh-client"; version="1.0" } } } | ConvertTo-Json -Compress
    $initResp = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $initPayload -WebSession $session
    $initResp.Content

    # Persist MCP session id for all follow-up calls on stateful MCP servers.
    $mcpSessionId = $initResp.Headers['mcp-session-id']
    if ([string]::IsNullOrWhiteSpace($mcpSessionId)) {
        Write-Host "Error: mcp-session-id header missing from initialize response"
        exit
    }
    $headers['mcp-session-id'] = $mcpSessionId
    Write-Host "MCP Session ID: $mcpSessionId"

    Write-Host "--- NOTIFICATIONS/INITIALIZED ---"
    $notifPayload = @{ jsonrpc="2.0"; method="notifications/initialized" } | ConvertTo-Json -Compress
    $notifResp = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $notifPayload -WebSession $session
    Write-Host "Status: $($notifResp.StatusCode)"

    Write-Host "--- TOOLS/CALL ---"
    $callPayload = @{ jsonrpc="2.0"; id=2; method="tools/call"; params=@{ name="pzCreateRuleTool"; arguments=@{} } } | ConvertTo-Json -Compress
    $callResp = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $callPayload -WebSession $session
    $callResp.Content
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.ReadToEnd()
    }
}

$clientId='72957161055032363202';
$clientSecret='9672C0DCDF4C2A8C6D442590B59935D6';
$tokenUrl='https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token';
$mcpUrl='https://lab-16330-us-east-1.internal.pegalabs.io/prweb/app/GridMana/api/service/v1/mcp/DMOrg-GridMana-Work!Grid';

$tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body @{grant_type='client_credentials';client_id=$clientId;client_secret=$clientSecret};
$token = $tokenResponse.access_token;

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession;
$headers = @{ 
    'Authorization' = "Bearer $token";
    'Accept' = 'application/json, text/event-stream';
    'Content-Type' = 'application/json'
};

$initPayload = @{ 
    jsonrpc="2.0"; 
    id=1; 
    method="initialize"; 
    params=@{ 
        protocolVersion="2024-11-05"; 
        capabilities=@{}; 
        clientInfo=@{ name="pwsh-client"; version="1.0" } 
    } 
} | ConvertTo-Json -Compress;

Write-Host "--- Initializing ---";
try {
    $initResp = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $initPayload -WebSession $session;
    Write-Host "Initialize Status: $($initResp.StatusCode)";
    $mcpSessionId = $initResp.Headers['mcp-session-id'];
    Write-Host "MCP-Session-ID: $mcpSessionId";

    if ($mcpSessionId) {
        $headers['mcp-session-id'] = $mcpSessionId;
        $notifPayload = @{ jsonrpc="2.0"; method="notifications/initialized" } | ConvertTo-Json -Compress;
        $notifResp = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $notifPayload -WebSession $session;
        Write-Host "Notification Status: $($notifResp.StatusCode)";

        $listPayload = @{ jsonrpc="2.0"; id=2; method="tools/list"; params=@{} } | ConvertTo-Json -Compress;
        $listResp = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $listPayload -WebSession $session;
        Write-Host "List Status: $($listResp.StatusCode)";
        $listResp.Content | ConvertFrom-Json | ConvertTo-Json;
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)";
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream());
        Write-Host "Error Response: $($reader.ReadToEnd())";
    }
}

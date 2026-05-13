$clientId = '72957161055032363202'
$clientSecret = '9672C0DCDF4C2A8C6D442590B59935D6'
$tokenUrl = 'https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token'
$agentUrl = 'https://lab-16330-us-east-1.internal.pegalabs.io/prweb/app/GridMana/api/agent2agent/v1/ai-agents/DMORG-GRIDMANA-UIPAGES!GRIDMANAAGENT/.well-known/agent.json'
$body = @{ grant_type = 'client_credentials'; client_id = $clientId; client_secret = $clientSecret }
try {
    $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded'
    $accessToken = $tokenResponse.access_token
    $headers = @{ Authorization = "Bearer $accessToken" }
    $agentResponse = Invoke-RestMethod -Uri $agentUrl -Method Get -Headers $headers
    [PSCustomObject]@{ Status = 'Success'; Name = $agentResponse.name; Description = $agentResponse.description; Model = $agentResponse.model } | Format-List
} catch {
    [PSCustomObject]@{ Status = 'Failure'; Error = $_.Exception.Message } | Format-List
}

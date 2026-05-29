$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$mcpConfig = Get-Content mcp.json | ConvertFrom-Json
$config = $mcpConfig.servers.'fraud-investigation-mcp'

# 1) Get token
$authHeaderValue = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($config.auth.clientId):$($config.auth.clientSecret)"))
$tokenParams = @{
    Method      = "Post"
    Uri         = $config.auth.tokenUrl
    Headers     = @{ Authorization = "Basic $authHeaderValue" }
    ContentType = "application/x-www-form-urlencoded"
    Body        = "grant_type=client_credentials"
}
$tokenResponse = Invoke-RestMethod @tokenParams
$accessToken = $tokenResponse.access_token

$acceptHeader = "application/json, text/event-stream"

# 2) Initialize
$initBody = @{
    jsonrpc = "2.0"
    id = 1
    method = "initialize"
    params = @{
        protocolVersion = "2024-11-05"
        capabilities = @{}
        clientInfo = @{ name = "tester"; version = "1.0.0" }
    }
} | ConvertTo-Json
$initResponse = Invoke-WebRequest -Uri $config.url -Method Post -Body $initBody -ContentType "application/json" -Headers @{ Authorization = "Bearer $accessToken"; Accept = $acceptHeader } -WebSession $session -ErrorAction SilentlyContinue

# 3) Extract mcp-session-id
$sid = $initResponse.Headers."mcp-session-id"
if ($sid -is [array]) { $sid = $sid[0] }

# Extract JSESSIONID if present for the Cookie
$jsessionid = $session.Cookies.GetCookies($config.url) | Where-Object { $_.Name -eq "JSESSIONID" } | Select-Object -ExpandProperty Value -First 1
$headers = @{
    Authorization = "Bearer $accessToken"
    "mcp-session-id" = $sid
    Accept = $acceptHeader
}
if ($jsessionid) { $headers["Cookie"] = "JSESSIONID=$jsessionid" }

# 4) send notifications/initialized
$notifBody = @{
    jsonrpc = "2.0"
    method = "notifications/initialized"
} | ConvertTo-Json
$notifResponse = Invoke-WebRequest -Uri $config.url -Method Post -Body $notifBody -ContentType "application/json" -Headers $headers -WebSession $session -ErrorAction SilentlyContinue

# 5) send tools/list
$listBody = @{
    jsonrpc = "2.0"
    id = 2
    method = "tools/list"
} | ConvertTo-Json
$listResponse = Invoke-WebRequest -Uri $config.url -Method Post -Body $listBody -ContentType "application/json" -Headers $headers -WebSession $session -ErrorAction SilentlyContinue

Write-Host "init status: $($initResponse.StatusCode)"
Write-Host "sid value: $sid"
Write-Host "notif status: $($notifResponse.StatusCode)"
Write-Host "list status: $($listResponse.StatusCode)"
if ($listResponse.Content) {
    Write-Host "response body snippet: $($listResponse.Content.SubString(0, [Math]::Min(200, $listResponse.Content.Length)))"
} else {
    Write-Host "response body snippet: NO CONTENT"
}

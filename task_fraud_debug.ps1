try {
    $config = Get-Content -Raw mcp.json | ConvertFrom-Json
    $server = $config.servers.'fraud-investigation-mcp'
    $auth = $server.auth

    $body = @{
        grant_type    = "client_credentials"
        client_id     = $auth.clientId
        client_secret = $auth.clientSecret
    }

    $tokenResponse = Invoke-RestMethod -Uri $auth.tokenUrl -Method Post -ContentType "application/x-www-form-urlencoded" -Body $body
    $accessToken = $tokenResponse.access_token

    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Accept"        = "application/json, text/event-stream"
        "Content-Type"  = "application/json"
    }

    $initializeBody = @{
        jsonrpc = "2.0"
        id      = 1
        method  = "initialize"
        params  = @{
            protocolVersion = "2024-11-05"
            capabilities    = @{}
            clientInfo      = @{
                name    = "pwsh-client"
                version = "1.0.0"
            }
        }
    } | ConvertTo-Json

    $initResponse = Invoke-WebRequest -Uri $server.url -Method Post -Headers $headers -Body $initializeBody -WebSession $session
    $initContent = $initResponse.Content | ConvertFrom-Json
    
    if (-not $initContent.result.'mcp-session-id') {
        Write-Host "No mcp-session-id found in init response"
        Write-Host $initResponse.Content
        exit
    }

    $mcpSessionId = $initContent.result.'mcp-session-id'.ToString()
    $headers["mcp-session-id"] = $mcpSessionId

    $jsessionid = $session.Cookies.GetCookies($server.url) | Where-Object { $_.Name -eq "JSESSIONID" } | Select-Object -ExpandProperty Value
    if ($jsessionid) {
        $headers["Cookie"] = "JSESSIONID=$jsessionid"
    }

    $initializedNotification = @{
        jsonrpc = "2.0"
        method  = "notifications/initialized"
    } | ConvertTo-Json

    Invoke-WebRequest -Uri $server.url -Method Post -Headers $headers -Body $initializedNotification -WebSession $session | Out-Null

    $listToolsBody = @{
        jsonrpc = "2.0"
        id      = 2
        method  = "tools/list"
    } | ConvertTo-Json

    $toolsResponse = Invoke-WebRequest -Uri $server.url -Method Post -Headers $headers -Body $listToolsBody -WebSession $session

    if ($toolsResponse.StatusCode -eq 200) {
        $toolsContent = $toolsResponse.Content | ConvertFrom-Json
        if ($toolsContent.result.tools) {
            $toolsContent.result.tools | ForEach-Object { $_.name }
        } else {
            # If result.tools is missing, maybe it's in a different format
            Write-Host "Tools list is empty or missing in the result"
            Write-Host $toolsResponse.Content
        }
    } else {
        Write-Host "Status Code: $($toolsResponse.StatusCode)"
        Write-Host $toolsResponse.Content
    }
} catch {
    Write-Host "An error occurred: $($_.Exception.Message)"
    Write-Host $_.ScriptStackTrace
}

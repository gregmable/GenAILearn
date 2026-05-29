$config = Get-Content mcp.json | ConvertFrom-Json
$results = foreach ($serverKey in $config.servers.PSObject.Properties.Name) {
    $server = $config.servers.$serverKey
    $auth = $server.auth
    
    $initStatus = "Failed"
    $listStatus = "N/A"
    $toolNames = ""
    
    try {
        # Get OAuth Token
        $authBody = @{
            grant_type = $auth.grantType
            client_id = $auth.clientId
            client_secret = $auth.clientSecret
        }
        if ($auth.scopes -and $auth.scopes.Count -gt 0) {
            $authBody.scope = $auth.scopes -join " "
        }
        
        $tokenResponse = Invoke-RestMethod -Method Post -Uri $auth.tokenUrl -Body $authBody -ContentType "application/x-www-form-urlencoded"
        $token = $tokenResponse.access_token
        
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
        
        $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        
        # MCP Initialize
        $initBody = @{
            jsonrpc = "2.0"
            id = 1
            method = "initialize"
            params = @{
                protocolVersion = "2024-11-05"
                capabilities = @{}
                clientInfo = @{ name = "pwsh-client"; version = "1.0.0" }
            }
        } | ConvertTo-Json
        
        $initRes = Invoke-RestMethod -Method Post -Uri $server.url -Headers $headers -Body $initBody -WebSession $session
        if ($initRes.PSObject.Properties.Name -contains "result") {
            $initStatus = "Success"
            
            # MCP Initialized Notification
            $initializedBody = @{
                jsonrpc = "2.0"
                method = "notifications/initialized"
            } | ConvertTo-Json
            Invoke-RestMethod -Method Post -Uri $server.url -Headers $headers -Body $initializedBody -WebSession $session | Out-Null
            
            # MCP List Tools
            $listBody = @{
                jsonrpc = "2.0"
                id = 2
                method = "tools/list"
            } | ConvertTo-Json
            
            try {
                $listRes = Invoke-RestMethod -Method Post -Uri $server.url -Headers $headers -Body $listBody -WebSession $session
                if ($listRes.PSObject.Properties.Name -contains "result") {
                    $listStatus = "Success"
                    $toolNames = ($listRes.result.tools | ForEach-Object { $_.name }) -join ", "
                } else {
                    $listStatus = "RPC Error: " + ($listRes.error | ConvertTo-Json -Compress)
                }
            } catch {
                $msg = $_.Exception.Message
                if ($_.Exception.InnerException -and $_.Exception.InnerException.Response) {
                     $reader = New-Object System.IO.StreamReader($_.Exception.InnerException.Response.GetResponseStream())
                     $msg = $reader.ReadToEnd()
                }
                $listStatus = "HTTP Error: $msg"
            }
        } else {
            $initStatus = "RPC Error: " + ($initRes.error | ConvertTo-Json -Compress)
        }
    } catch {
        $msg = $_.Exception.Message
        if ($_.Exception.InnerException -and $_.Exception.InnerException.Response) {
             $reader = New-Object System.IO.StreamReader($_.Exception.InnerException.Response.GetResponseStream())
             $msg = $reader.ReadToEnd()
        }
        if ($initStatus -eq "Failed") { $initStatus = "HTTP Error: $msg" }
        else { $listStatus = "HTTP Error: $msg" }
    }
    
    [PSCustomObject]@{
        Server = $serverKey
        Init = $initStatus
        List = $listStatus
        Tools = $toolNames
    }
}
$results | Format-Table -AutoSize

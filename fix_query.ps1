72957161055032363202 = '72957161055032363202'
9672C0DCDF4C2A8C6D442590B59935D6 = '9672C0DCDF4C2A8C6D442590B59935D6'
https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token = 'https://lab-16330-us-east-1.internal.pegalabs.io/prweb/PRRestService/oauth2/v1/token'
https://lab-16330-us-east-1.internal.pegalabs.io/prweb/app/GridMana/api/service/v1/mcp/DMOrg-GridMana-Work!Grid = 'https://lab-16330-us-east-1.internal.pegalabs.io/prweb/app/GridMana/api/service/v1/mcp/DMOrg-GridMana-Work!Grid'

try {
    Write-Host "Getting OAuth token..."
    @{access_token=eyJraWQiOiI0MTIzRkFERjIwNTk0QzI0QkZBMDI1MjZEODE4NjBBMyIsInR5cCI6IkpXVCIsImFsZyI6IlJTMjU2In0.eyJhdWQiOiJ1cm46NzI5NTcxNjEwNTUwMzIzNjMyMDIiLCJzdWIiOiJwZWdhIiwiYXBwX25hbWUiOiJHcmlkTWFuYSIsIm5iZiI6MTc3ODY3NzMzNiwiYXBwX3ZlcnNpb24iOiIwMS4wMS4wMSIsImlzcyI6InVybjpsYWItMTYzMzAtdXMtZWFzdC0xLmludGVybmFsLnBlZ2FsYWJzLmlvIiwiZXhwIjoxNzc4Njc4MjM2LCJpYXQiOjE3Nzg2NzczMzYsImp0aSI6IkQ5ODQ0RDBERTVBRDlBMjhCRDc5NkQ1QjkyNkY4MjY4Iiwib3BlcmF0b3JfYWNjZXNzIjoiR3JpZE1hbmE6QXV0aG9ycyJ9.IUOV_jxT2xf6_ovD-tOO7mR6gs7NuuMlLYpekJnojC2CwFFkPW-zMpm_RxDxYzHSZiPGiAqNu8EBDQYIJ4rzKPkvIbOWlvfWQNS7r5Tp9IbIKHjo5OB-9CzhBqNRn8_Ld2F84pHYtGEm0otT5pd-Kx49iJablvcls15oDK-1S5PdUdFvdhiS2HD_P_4o2pAuRJNqgH_5FJI4px471gzelczPp9N_0nWGpU2Ou4JaYVFN2kIQAuDhaUnj9U3wAaiAVWuTznmBNGFEThC3lCb3JDEbIOfA_8LDqz7BtoGmmhxVAdYPvIj6lWUmgJJ81CCZpTN6ARi8u9V5fT3H9YtIcbxYlbwlXIDUhx2yL4xFFVs_uyNSUlNSCpS5PP1g8_70aaAUQDGJqRAXraC5j1CuSwzF_VLynciJxH8_p5oCAdrA_loSVju5b5aXqsGui96CnmDfp7vpCMhnz10aDXGoi0N7fFlQGdXy1PJEB7Q_tH7wra0Xq0dBj1WjExOVtZPPAtfXnuxmhTgY2_gZERdug11TAIEwJv3cAb7e3d4vNj1-b7goFeV-BJwTgkUfOcYM1Dp5kW5X8A6-vimo7h--KxysGP5EeRnXd_UdeOU3AG0gpkra6hwcbjmdmJxPpew6LS1OIW0nZNfnJQ0VFBx7q-zP7PoQmYhVRjM31OzlHUU; token_type=bearer; expires_in=900} = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body @{grant_type='client_credentials';client_id=$clientId;client_secret=$clientSecret}
    $token = $tokenResponse.access_token
    $headers = @{ Authorization = "Bearer $token"; Accept = "application/json, text/event-stream"; "Content-Type" = "application/json" }
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

    Write-Host "Initializing MCP session..."
    $initPayload = @{ jsonrpc="2.0"; id=1; method="initialize"; params=@{ protocolVersion="2024-11-05"; capabilities=@{}; clientInfo=@{ name="queryCases"; version="1.0" } } } | ConvertTo-Json -Compress
    $initResp = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $initPayload -WebSession $session
    
    $mcpSessionId = $initResp.Headers['mcp-session-id']
    if ([string]::IsNullOrWhiteSpace($mcpSessionId)) {
        Write-Host "Error: mcp-session-id header missing"
        exit
    }
    $headers['mcp-session-id'] = $mcpSessionId
    Write-Host "Session ID: $mcpSessionId"

    Write-Host "Sending initialized notification..."
    $notifPayload = @{ jsonrpc="2.0"; method="notifications/initialized" } | ConvertTo-Json -Compress
    Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $notifPayload -WebSession $session | Out-Null

    Write-Host "Listing available tools..."
    $listPayload = @{ jsonrpc="2.0"; id=2; method="tools/list" } | ConvertTo-Json -Compress
    try {
        $listResp = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $listPayload -WebSession $session
        $listContent = $listResp.Content | ConvertFrom-Json
        Write-Host "Available tools:"
        $listContent.result.tools | ForEach-Object { Write-Host "  - $($_.name)" }

        Write-Host "
Calling Get_Grid_Case_Types..."
        $callPayload = @{ jsonrpc="2.0"; id=3; method="tools/call"; params=@{ name="Get_Grid_Case_Types"; arguments=@{} } } | ConvertTo-Json -Compress
        $callResp = Invoke-WebRequest -Uri $mcpUrl -Method Post -Headers $headers -Body $callPayload -WebSession $session
        Write-Host $callResp.Content
    } catch {
        Write-Host "Operation failed: $($_.Exception.Message)"
        if ($_.Exception.Response) {
             $stream = $_.Exception.Response.GetResponseStream()
             $reader = New-Object System.IO.StreamReader($stream)
             Write-Host "Response Body: $($reader.ReadToEnd())"
        }
    }

} catch {
    Write-Host "Fatal Error: $($_.Exception.Message)"
}

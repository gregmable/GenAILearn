$ErrorActionPreference = "Stop"
$clientId = '72957161055032363202'
$clientSecret = '9672C0DCDF4C2A8C6D442590B59935D6'
$base = 'https://lab-16330-us-east-1.internal.pegalabs.io'
$tokenUrl = "$base/prweb/PRRestService/oauth2/v1/token"
$mcpUrl = "$base/prweb/app/GridMana/api/service/v1/mcp/DMOrg-GridMana-Work!Grid"

$token = (Invoke-RestMethod -Uri $tokenUrl -Method Post -Body @{grant_type='client_credentials';client_id=$clientId;client_secret=$clientSecret} -ContentType 'application/x-www-form-urlencoded').access_token
$ws = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$h = @{Authorization="Bearer $token";Accept='application/json, text/event-stream';'Content-Type'='application/json'}

$init = @{jsonrpc='2.0';id=1;method='initialize';params=@{protocolVersion='2025-11-25';capabilities=@{};clientInfo=@{name='pwsh-key-probe';version='1.0.0'}}} | ConvertTo-Json -Depth 10
$r1 = Invoke-WebRequest -Uri $mcpUrl -Method Post -WebSession $ws -Headers $h -Body $init -UseBasicParsing
$sid = @($r1.Headers['mcp-session-id'])[0]
$h['mcp-session-id'] = $sid
$notif = @{jsonrpc='2.0';method='notifications/initialized';params=@{}} | ConvertTo-Json -Depth 5
$null = Invoke-WebRequest -Uri $mcpUrl -Method Post -WebSession $ws -Headers $h -Body $notif -UseBasicParsing

$tests = @(
 @{label='A_pyRuleName_pyClassName'; schema='{"pyRuleName":"AlertInfoID","pyClassName":"DMOrg-GridMana-Work-GridMonitoring","pyLabel":"Alert Info ID","pyPropertyMode":"String"}'},
 @{label='B_pyPropertyName_pyClassName'; schema='{"pyPropertyName":"AlertInfoID","pyClassName":"DMOrg-GridMana-Work-GridMonitoring","pyLabel":"Alert Info ID","pyPropertyMode":"String"}'},
 @{label='C_name_appliesTo'; schema='{"name":"AlertInfoID","appliesToClass":"DMOrg-GridMana-Work-GridMonitoring","label":"Alert Info ID","mode":"String"}'},
 @{label='D_pyRuleName_appliesToClass'; schema='{"pyRuleName":"AlertInfoID","appliesToClass":"DMOrg-GridMana-Work-GridMonitoring","pyLabel":"Alert Info ID","pyPropertyMode":"String"}'}
)

foreach($t in $tests){
  $call = @{jsonrpc='2.0';id=(Get-Random -Minimum 100 -Maximum 999);method='tools/call';params=@{name='pzCreateRuleTool';arguments=@{ruleType='Property';ruleSchema=$t.schema}}} | ConvertTo-Json -Depth 20
  Write-Output "---$($t.label)---"
  try {
    $r = Invoke-WebRequest -Uri $mcpUrl -Method Post -WebSession $ws -Headers $h -Body $call -UseBasicParsing
    Write-Output "STATUS=$($r.StatusCode)"
    Write-Output "BODY=$($r.Content)"
  } catch {
    $resp = $_.Exception.Response
    if($resp){
      $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
      $txt = $sr.ReadToEnd(); $sr.Close()
      Write-Output "ERROR_STATUS=$([int]$resp.StatusCode)"
      Write-Output "ERROR_BODY=$txt"
    } else {
      Write-Output "ERROR=$($_.Exception.Message)"
    }
  }
}

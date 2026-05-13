$clientId = "72957161055032363202"
$clientSecret = "9672C0DCDF4C2A8C6D442590B59935D6"
$baseUrl = "https://lab-16330-us-east-1.internal.pegalabs.io"
$tokenUrl = "$baseUrl/prweb/PRRestService/oauth2/v1/token"
$body = @{ grant_type="client_credentials"; client_id=$clientId; client_secret=$clientSecret }
$tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
$headers = @{ "Authorization" = "Bearer $($tokenResponse.access_token)"; "Content-Type" = "application/json" }
$createCaseUrl = "$baseUrl/prweb/api/application/v2/cases"
$casePayload = @{ caseTypeID = "DMOrg-GridMana-Work-GridMonitoring" } | ConvertTo-Json
$caseResponse = Invoke-RestMethod -Uri $createCaseUrl -Method Post -Headers $headers -Body $casePayload
$caseID = $caseResponse.ID
Write-Host "Created Case ID: $caseID"
$getCaseUrl = "$baseUrl/prweb/api/application/v2/cases/$caseID"
$caseData = Invoke-RestMethod -Uri $getCaseUrl -Method Get -Headers $headers
$assignment = $caseData.nextAssignments[0]
if ($null -eq $assignment) { 
    Write-Host "No next assignment found! Full case response nextAssignments follow:"
    $caseData.nextAssignments | ConvertTo-Json | Write-Host
    exit 
}
$action = $assignment.actions | Where-Object { $_.ID -eq "ReviewAlertDetails" }
$actionHref = $action.links.submit.href
$patchBody1 = @{ content = @{ InfoNoticeAlert = "Test notice 1" } } | ConvertTo-Json
try {
    $resp1 = Invoke-WebRequest -Uri $actionHref -Method Patch -Headers $headers -Body $patchBody1
    Write-Output "PATCH 1 (InfoNoticeAlert): Status $($resp1.StatusCode)"
} catch {
    Write-Output "PATCH 1 (InfoNoticeAlert): Error $($_.Exception.Message)"
}
$patchBody2 = @{ content = @{ ".InfoNoticeAlert" = "Test notice 2" } } | ConvertTo-Json
try {
    $resp2 = Invoke-WebRequest -Uri $actionHref -Method Patch -Headers $headers -Body $patchBody2
    Write-Output "PATCH 2 (.InfoNoticeAlert): Status $($resp2.StatusCode)"
} catch {
    Write-Output "PATCH 2 (.InfoNoticeAlert): Error $($_.Exception.Message)"
}
$finalCase = Invoke-RestMethod -Uri $getCaseUrl -Method Get -Headers $headers
$contentStr = $finalCase.content | ConvertTo-Json
Write-Output "Verification: InfoNoticeAlert found? $($contentStr -match 'Test notice 1')"
Write-Output "Verification: .InfoNoticeAlert found? $($contentStr -match 'Test notice 2')"

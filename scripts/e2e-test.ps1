param(
  [string]$Gateway = 'http://localhost:4000'
)

Write-Host "Waiting for gateway to become healthy..."
for ($i=0; $i -lt 30; $i++) {
  try {
    $res = Invoke-RestMethod -Uri "$Gateway/api/health" -UseBasicParsing -ErrorAction Stop
    if ($res.status -eq 'ok') { Write-Host 'Gateway healthy'; break }
  } catch { Start-Sleep -Seconds 2 }
}

Write-Host 'Registering test user...'
$reg = Invoke-RestMethod -Uri "$Gateway/api/auth/register" -Method Post -Body (@{name='e2e';email='e2e@example.com';password='secret'} | ConvertTo-Json) -ContentType 'application/json'
Write-Host "Register response: $($reg | ConvertTo-Json -Depth 3)"

$token = $reg.token
if (-not $token) { Write-Error 'Token missing from register response'; exit 1 }

Write-Host 'Creating a task...'
$create = Invoke-RestMethod -Uri "$Gateway/api/tasks" -Method Post -Body (@{title='E2E Task'} | ConvertTo-Json) -Headers @{ Authorization = "Bearer $token" } -ContentType 'application/json'
Write-Host "Create task response: $($create | ConvertTo-Json -Depth 3)"

Write-Host 'E2E flow completed'

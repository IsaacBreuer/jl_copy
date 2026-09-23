$db = (Get-ItemProperty 'HKCU:\Software\VB and VBA Program Settings\Tuition\Databases' -Name Master -ErrorAction SilentlyContinue).Master
Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '   ECAP Processing Services - JL Database Export' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''
if (-not $db -or -not (Test-Path $db)) {
  Write-Host '  JL WAS NOT FOUND ON THIS COMPUTER.' -ForegroundColor Red
  Write-Host '  Please run this on a computer that uses the JL program.' -ForegroundColor Red
  Write-Host '  Questions? Call ECAP' -ForegroundColor Red
  Read-Host '   Press and key to exit'
  exit
  exit
} else {
  Write-Host "  JL database found:" -ForegroundColor Gray
  Write-Host "     $db" -ForegroundColor Gray
  $desk = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' -Name Desktop -ErrorAction SilentlyContinue).Desktop
  if (-not $desk -or -not (Test-Path $desk)) { $desk = "$env:USERPROFILE\Desktop" }
  $tmp = Join-Path $env:TEMP 'ECAP_JL'
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  New-Item $tmp -ItemType Directory | Out-Null
  Write-Host '  Copying database...' -ForegroundColor Gray
  Copy-Item -LiteralPath $db -Destination $tmp
  $name = (Get-Date -Format 'yyyy-MM-dd') + ' JL For ECAP.zip'
  $zip  = Join-Path $desk $name



  
  Write-Host '  Creating zip file...' -ForegroundColor Gray
  Write-Host '  This can take several minutes. Please do not close this window.' -ForegroundColor Yellow
  $ProgressPreference = 'SilentlyContinue'
  $srcMB = ''
  try { $srcMB = '{0:N0}' -f ((Get-Item $tmp\*).Length / 1MB) } catch { }
  if ($srcMB) { Write-Host "  (compressing about $srcMB MB)" -ForegroundColor Gray }
  $job = $null
  try { $job = Start-Job -ScriptBlock { param($s,$d) Compress-Archive -Path $s -DestinationPath $d -Force } -ArgumentList "$tmp\*", $zip } catch { }
  if ($job) {
    while ($job.State -eq 'Running') {
      $done = 0
      try { if (Test-Path $zip) { $done = '{0:N0}' -f ((Get-Item $zip).Length / 1MB) } } catch { }
      Write-Host " Working... $done MB written   "  -ForegroundColor Gray
      Start-Sleep -Seconds 2
    }
    Receive-Job $job -ErrorAction SilentlyContinue | Out-Null
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    Write-Host ''
  } else {
    Compress-Archive -Path "$tmp\*" -DestinationPath $zip -Force
  }
  
  Remove-Item $tmp -Recurse -Force
  if (Test-Path $zip) {

      $size = ''
    try { $size = '  (size: ' + ('{0:N1}' -f ((Get-Item $zip).Length / 1MB)) + ' MB)' } catch { }
    
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Green
    Write-Host '  DONE!' -ForegroundColor Green
    Write-Host ''
    Write-Host '  A file named:' -ForegroundColor Green
    Write-Host "       $name" -ForegroundColor Yellow
    Write-Host '  was saved to your Desktop.' -ForegroundColor Green
        
   if ($size) { Write-Host "     $size" -ForegroundColor Gray }
    Write-Host ''
    Write-Host '  Please send THIS file to ECAP.' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Green
    Write-Host ''
    Start-Process explorer.exe -ArgumentList ('/select,"{0}"' -f $zip)
  } else {
    Write-Host '  ERROR: The zip file could not be created.' -ForegroundColor Red
    Write-Host '  Please call ECAP at 347-598-8798' -ForegroundColor Red
  }
  Read-Host '  Press Enter to finish'
  exit
  exit
  
}

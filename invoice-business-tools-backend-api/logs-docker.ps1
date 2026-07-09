Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Invoice Business Tools - Container Logs" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop viewing logs" -ForegroundColor Yellow
Write-Host ""

docker-compose logs -f

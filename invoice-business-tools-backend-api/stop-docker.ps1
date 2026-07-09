Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Stopping Invoice Business Tools Backend" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

docker-compose stop

Write-Host ""
Write-Host "Containers stopped." -ForegroundColor Green
Write-Host ""
Write-Host "To start again: docker-compose up -d" -ForegroundColor Yellow
Write-Host "To remove containers: docker-compose down" -ForegroundColor Yellow
Write-Host "To remove everything including data: docker-compose down -v" -ForegroundColor Red
Write-Host ""
Read-Host "Press Enter to exit"

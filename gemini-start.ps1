# Full Gemini session starter: Proxy (Gemini) -> Claude Code
# Run: .\gemini-start.ps1   or just   gemini   (if alias is configured)
param(
    [switch]$SkipProxy,
    [int]$Port = 8083
)

$repo = "D:\AI BASE\DEEPSEEK"
$url  = "http://127.0.0.1:${Port}"
$auth = @{"x-api-key" = "freecc"}
$green = "Green"
$cyan  = "Cyan"
$gray  = "Gray"

Write-Host ""
Write-Host "=====================================" -ForegroundColor $cyan
Write-Host "  Gemini -> Claude Code Launcher     " -ForegroundColor $cyan
Write-Host "=====================================" -ForegroundColor $cyan
Write-Host ""

# ---- Step: Proxy ----
if (-not $SkipProxy) {
    Write-Host "[1/1] Gemini proxy" -ForegroundColor $cyan

    # Check if already running
    $alreadyRunning = $false
    try {
        $check = Invoke-WebRequest -Uri "$url/v1/models" -Headers $auth -TimeoutSec 2 -ErrorAction Stop
        Write-Host "  Already running at $url" -ForegroundColor $green
        $alreadyRunning = $true
    } catch {
        # Not running, start it
    }

    if (-not $alreadyRunning) {
        Write-Host "  Starting Gemini proxy at $url ..." -ForegroundColor $gray

        # Start in new window with FCC_ENV_FILE override
        Start-Process -FilePath "pwsh" `
            -WorkingDirectory $repo `
            -ArgumentList "-NoExit", "-Command",
                "`$env:FCC_ENV_FILE = '.env.gemini'; Write-Host 'Gemini proxy on port $Port' -ForegroundColor Cyan; uv run uvicorn server:app --host 127.0.0.1 --port $Port" `
            -WindowStyle Normal

        # Wait for proxy to be ready
        Write-Host "  Waiting for proxy..." -NoNewline
        for ($i = 0; $i -lt 30; $i++) {
            Start-Sleep -Seconds 1
            Write-Host -NoNewline "."
            try {
                $check = Invoke-WebRequest -Uri "$url/v1/models" -Headers $auth -TimeoutSec 2 -ErrorAction Stop
                Write-Host ""
                Write-Host "  Gemini proxy ready at $url" -ForegroundColor $green
                break
            } catch {
                if ($i -eq 29) {
                    Write-Host ""
                    Write-Host "  WARNING: Proxy didn't respond after 30s. Check the server window for errors." -ForegroundColor Yellow
                }
            }
        }
    }
} else {
    Write-Host "[1/1] Proxy: skipped (-SkipProxy)" -ForegroundColor $gray
}

# ---- Done ----
Write-Host ""
Write-Host "=====================================" -ForegroundColor $cyan
Write-Host "  Setup complete. Now run:           " -ForegroundColor $green
Write-Host "                                     "
Write-Host "    gemini                           " -ForegroundColor $green
Write-Host "                                     "
Write-Host "  (if gemini alias is configured)    " -ForegroundColor $gray
Write-Host "=====================================" -ForegroundColor $cyan
Write-Host ""

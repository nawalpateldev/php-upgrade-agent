# ====================================================================
# Universal AI Agent & Skill Installer (Windows PowerShell)
# Configures PHP Upgrade Agent for Copilot, Cursor, Claude, Windsurf, Gemini, Codex
# ====================================================================

[CmdletBinding()]
param (
    [Parameter(Position=0)]
    [string]$LLM = ""
)

$scriptDir = $PSScriptRoot
$templateDir = Join-Path $scriptDir ".agents\templates"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "   PHP Upgrade Agent and Security Hardener - Multi-LLM Setup        " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "Configures zero-breakage PHP modernization and php2shell fixes.`n"

# Modular LLM Provider Directory
$providers = @(
    @{ Id = "copilot";  Name = "GitHub Copilot";                        Default = $true },
    @{ Id = "cursor";   Name = "Cursor";                                Default = $false },
    @{ Id = "claude";   Name = "Claude Code";                           Default = $false },
    @{ Id = "windsurf"; Name = "Windsurf";                              Default = $false },
    @{ Id = "gemini";   Name = "Gemini Code Assist / Antigravity";      Default = $false },
    @{ Id = "codex";    Name = "OpenAI Codex / ChatGPT Dev Tools";      Default = $false },
    @{ Id = "all";      Name = "Universal Setup (Configure All Providers)"; Default = $false }
)

if ([string]::IsNullOrWhiteSpace($LLM)) {
    Write-Host "Select your primary AI Coding Assistant:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $providers.Count; $i++) {
        $p = $providers[$i]
        $num = $i + 1
        if ($p.Default) {
            Write-Host "  [$num] $($p.Name) " -NoNewline
            Write-Host "(Default - Press Enter)" -ForegroundColor Green
        } else {
            Write-Host "  [$num] $($p.Name)"
        }
    }
    Write-Host ""
    $choice = Read-Host "Enter selection [1-$($providers.Count)] (Default: 1)"

    if ([string]::IsNullOrWhiteSpace($choice) -or $choice -eq "1") {
        $LLM = "copilot"
    } elseif ($choice -match '^\d+$' -and [int]$choice -le $providers.Count -and [int]$choice -ge 1) {
        $LLM = $providers[[int]$choice - 1].Id
    } else {
        $matched = $providers | Where-Object { $_.Id -ieq $choice }
        if ($matched) { $LLM = $matched.Id } else { $LLM = "copilot" }
    }
}

$LLM = $LLM.ToLower()

Write-Host "`n[*] Configuring AI Assistant Adapter: " -NoNewline
Write-Host "$($LLM.ToUpper())" -ForegroundColor Green

# --------------------------------------------------------------------
# Safe File Merge Helper (Never deletes or overwrites existing content)
# --------------------------------------------------------------------
function Safe-Merge-Content {
    param (
        [string]$FilePath,
        [string]$Content,
        [string]$MarkerName = "PHP-UPGRADE-AGENT"
    )

    $startMarker = "<!-- $MarkerName-START -->"
    $endMarker = "<!-- $MarkerName-END -->"
    $wrappedContent = "`n$startMarker`n$Content`n$endMarker`n"

    $parentDir = Split-Path $FilePath
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    if (Test-Path $FilePath) {
        $existing = Get-Content $FilePath -Raw -Encoding utf8
        if ($existing -match [regex]::Escape($startMarker) -and $existing -match [regex]::Escape($endMarker)) {
            $pattern = "(?s)" + [regex]::Escape($startMarker) + ".*?" + [regex]::Escape($endMarker)
            $updated = [regex]::Replace($existing, $pattern, $wrappedContent.Trim())
            Set-Content -Path $FilePath -Value $updated -Encoding utf8
            Write-Host "  [+] Updated $FilePath (safely updated existing block)" -ForegroundColor Green
        } else {
            Add-Content -Path $FilePath -Value $wrappedContent -Encoding utf8
            Write-Host "  [+] Appended to existing $FilePath (preserved your existing settings)" -ForegroundColor Green
        }
    } else {
        Set-Content -Path $FilePath -Value $wrappedContent.Trim() -Encoding utf8
        Write-Host "  [+] Created $FilePath" -ForegroundColor Green
    }
}

# --------------------------------------------------------------------
# Provider Setup Routines
# --------------------------------------------------------------------
function Setup-Copilot {
    Write-Host "[*] Configuring GitHub Copilot adapter (additive)..."
    $copilotContent = Get-Content (Join-Path $templateDir "copilot-instructions.md") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $scriptDir ".github\copilot-instructions.md") -Content $copilotContent

    $promptsDir = Join-Path $scriptDir ".github\prompts"
    if (-not (Test-Path $promptsDir)) { New-Item -ItemType Directory -Path $promptsDir -Force | Out-Null }
    Write-Host "  [+] Checked .github\prompts\ (existing prompts preserved)" -ForegroundColor Green
}

function Setup-Cursor {
    Write-Host "[*] Configuring Cursor adapter (additive)..."
    $cursorContent = Get-Content (Join-Path $templateDir "cursorrules") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $scriptDir ".cursorrules") -Content $cursorContent

    $cursorRulesDir = Join-Path $scriptDir ".cursor\rules"
    if (-not (Test-Path $cursorRulesDir)) { New-Item -ItemType Directory -Path $cursorRulesDir -Force | Out-Null }
    Safe-Merge-Content -FilePath (Join-Path $cursorRulesDir "php-upgrade.mdc") -Content $cursorContent
}

function Setup-Claude {
    Write-Host "[*] Configuring Claude Code adapter (additive)..."
    $claudeContent = Get-Content (Join-Path $templateDir "CLAUDE.md") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $scriptDir "CLAUDE.md") -Content $claudeContent
}

function Setup-Windsurf {
    Write-Host "[*] Configuring Windsurf adapter (additive)..."
    $windsurfContent = Get-Content (Join-Path $templateDir "windsurfrules") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $scriptDir ".windsurfrules") -Content $windsurfContent

    $windsurfRulesDir = Join-Path $scriptDir ".windsurf\rules"
    if (-not (Test-Path $windsurfRulesDir)) { New-Item -ItemType Directory -Path $windsurfRulesDir -Force | Out-Null }
    Safe-Merge-Content -FilePath (Join-Path $windsurfRulesDir "php-upgrade.md") -Content $windsurfContent
}

function Setup-Gemini {
    Write-Host "[*] Configuring Gemini Code Assist / Antigravity adapter (additive)..."
    $geminiContent = Get-Content (Join-Path $templateDir "GEMINI.md") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $scriptDir "GEMINI.md") -Content $geminiContent
}

function Setup-Codex {
    Write-Host "[*] Configuring OpenAI Codex / ChatGPT Dev Tools adapter (additive)..."
    $codexContent = Get-Content (Join-Path $templateDir "codex-instructions.md") -Raw -Encoding utf8
    $chatgptDir = Join-Path $scriptDir ".chatgpt"
    if (-not (Test-Path $chatgptDir)) { New-Item -ItemType Directory -Path $chatgptDir -Force | Out-Null }
    Safe-Merge-Content -FilePath (Join-Path $chatgptDir "instructions.md") -Content $codexContent
}

# --------------------------------------------------------------------
# Apply Selected Configuration
# --------------------------------------------------------------------
switch ($LLM) {
    "copilot"  { Setup-Copilot }
    "cursor"   { Setup-Cursor }
    "claude"   { Setup-Claude }
    "windsurf" { Setup-Windsurf }
    "gemini"   { Setup-Gemini }
    "codex"    { Setup-Codex }
    default    {
        Setup-Copilot
        Setup-Cursor
        Setup-Claude
        Setup-Windsurf
        Setup-Gemini
        Setup-Codex
    }
}

# Check Composer dependencies quietly
$vendorDir = Join-Path $scriptDir "vendor"
if (-not (Test-Path $vendorDir)) {
    $composerCmd = Get-Command composer -ErrorAction SilentlyContinue
    if ($composerCmd) {
        Write-Host "`n[*] Checking Composer tooling dependencies..." -ForegroundColor Cyan
        try {
            $prevErrorAction = $ErrorActionPreference
            $ErrorActionPreference = 'SilentlyContinue'
            & composer install --no-interaction --quiet 2>$null
            $ErrorActionPreference = $prevErrorAction
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [+] Tooling packages installed successfully." -ForegroundColor Green
            }
        } catch {
            # Ignore offline network sandbox errors
        }
    }
}

# --------------------------------------------------------------------
# Final Confirmation & Suggested Commands
# --------------------------------------------------------------------
Write-Host "`n====================================================================" -ForegroundColor Green
Write-Host "   [+] INSTALLATION COMPLETE: All Agents & Skills Are Active!       " -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "Canonical rules and skills reside safely in: .agents/`n"

Write-Host "RECOMMENDED NEXT STEPS & COMMANDS TO RUN NOW:" -ForegroundColor Yellow
Write-Host "--------------------------------------------------------------------"

Write-Host "1. Scan for php2shell & RCE vulnerabilities:" -ForegroundColor White
Write-Host "   php .agents/skills/php2shell-fixer/scripts/php2shell-audit.php --path=.`n" -ForegroundColor Cyan

Write-Host "2. Scan for OWASP Top 10 security flaws (SQLi, SSRF, Deserialization):" -ForegroundColor White
Write-Host "   php .agents/skills/php-security-hardener/scripts/security-audit.php .`n" -ForegroundColor Cyan

Write-Host "3. Preview safe PHP Core AST modernization (Up to PHP 8.5+ / Latest):" -ForegroundColor White
Write-Host "   vendor/bin/rector process --dry-run --config=.agents/skills/php-core-upgrader/scripts/rector-php-upgrade.php`n" -ForegroundColor Cyan

Write-Host "4. Preview Framework upgrade plan (Laravel 8 -> 12+ / Latest):" -ForegroundColor White
Write-Host "   vendor/bin/rector process --dry-run --config=.agents/skills/laravel-upgrader/scripts/rector-laravel.php`n" -ForegroundColor Cyan

Write-Host "5. Run static analysis deprecation audit:" -ForegroundColor White
Write-Host "   vendor/bin/phpstan analyse -c .agents/skills/php-core-upgrader/scripts/phpstan.neon`n" -ForegroundColor Cyan

Write-Host "OR ASK YOUR AI ASSISTANT DIRECTLY:" -ForegroundColor Yellow
Write-Host '   "Audit this codebase for php2shell vulnerabilities, check deprecations,' -ForegroundColor White
Write-Host '    and generate a stepwise non-breaking PHP upgrade roadmap."' -ForegroundColor White
Write-Host "====================================================================`n" -ForegroundColor Cyan

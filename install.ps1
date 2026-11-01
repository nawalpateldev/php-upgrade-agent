# ====================================================================
# Universal AI Agent & Skill Installer (Windows PowerShell)
# Configures PHP Upgrade Agent for GitHub Copilot, Claude Code, Cursor, and Gemini
# ====================================================================

[CmdletBinding()]
param (
    [Parameter(Position=0)]
    [ValidateSet("copilot", "claude", "cursor", "gemini", "all", "")]
    [string]$LLM = ""
)

$scriptDir = $PSScriptRoot
$templateDir = Join-Path $scriptDir ".agents\templates"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "   🚀 PHP Upgrade Agent & Security Hardener - Multi-LLM Setup       " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "Configures zero-breakage PHP modernization and php2shell fixes for:"
Write-Host " • GitHub Copilot (Default)"
Write-Host " • Claude Code"
Write-Host " • Cursor"
Write-Host " • Google Gemini / Antigravity`n"

if ([string]::IsNullOrWhiteSpace($LLM)) {
    Write-Host "Select your primary AI Coding Assistant:" -ForegroundColor Yellow
    Write-Host "  [1] GitHub Copilot " -NoNewline
    Write-Host "(Default - Press Enter)" -ForegroundColor Green
    Write-Host "  [2] Claude Code"
    Write-Host "  [3] Cursor"
    Write-Host "  [4] Google Gemini / Antigravity"
    Write-Host "  [5] Universal Setup (Configure All Assistants)`n"

    $choice = Read-Host "Enter selection [1-5] (Default: 1)"

    switch ($choice) {
        "2" { $LLM = "claude" }
        "3" { $LLM = "cursor" }
        "4" { $LLM = "gemini" }
        "5" { $LLM = "all" }
        default { $LLM = "copilot" }
    }
}

Write-Host "`n[*] Applying configuration for: " -NoNewline
Write-Host "$($LLM.ToUpper())" -ForegroundColor Green

function Setup-Copilot {
    Write-Host "[*] Setting up GitHub Copilot adapter..."
    $githubDir = Join-Path $scriptDir ".github"
    $promptsDir = Join-Path $githubDir "prompts"
    if (-not (Test-Path $promptsDir)) { New-Item -ItemType Directory -Path $promptsDir -Force | Out-Null }

    Copy-Item -Path (Join-Path $templateDir "copilot-instructions.md") -Destination (Join-Path $githubDir "copilot-instructions.md") -Force
    Write-Host "  [+] Configured .github\copilot-instructions.md" -ForegroundColor Green
}

function Setup-Claude {
    Write-Host "[*] Setting up Claude Code adapter..."
    Copy-Item -Path (Join-Path $templateDir "CLAUDE.md") -Destination (Join-Path $scriptDir "CLAUDE.md") -Force
    Write-Host "  [+] Configured CLAUDE.md" -ForegroundColor Green
}

function Setup-Cursor {
    Write-Host "[*] Setting up Cursor adapter..."
    $cursorRulesDir = Join-Path $scriptDir ".cursor\rules"
    if (-not (Test-Path $cursorRulesDir)) { New-Item -ItemType Directory -Path $cursorRulesDir -Force | Out-Null }

    Copy-Item -Path (Join-Path $templateDir "cursorrules") -Destination (Join-Path $scriptDir ".cursorrules") -Force
    Copy-Item -Path (Join-Path $templateDir "cursorrules") -Destination (Join-Path $cursorRulesDir "php-upgrade.mdc") -Force
    Write-Host "  [+] Configured .cursorrules and .cursor\rules\php-upgrade.mdc" -ForegroundColor Green
}

function Setup-Gemini {
    Write-Host "[*] Setting up Google Gemini / Antigravity adapter..."
    Copy-Item -Path (Join-Path $templateDir "GEMINI.md") -Destination (Join-Path $scriptDir "GEMINI.md") -Force
    Write-Host "  [+] Configured GEMINI.md" -ForegroundColor Green
}

switch ($LLM) {
    "copilot" { Setup-Copilot }
    "claude"  { Setup-Claude }
    "cursor"  { Setup-Cursor }
    "gemini"  { Setup-Gemini }
    default   { 
        Setup-Copilot
        Setup-Claude
        Setup-Cursor
        Setup-Gemini
    }
}

Write-Host "`n[+] Installation Complete!" -ForegroundColor Green
Write-Host "AI Assistant configured successfully. Agents, rules, and skills reside in: .agents/`n"

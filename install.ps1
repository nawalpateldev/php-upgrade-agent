# ====================================================================
# Universal AI Agent & Plugin Manager (Windows PowerShell)
# Adds or removes PHP Upgrade Agent for Copilot, Claude, Cursor, Windsurf, Gemini, Codex
# ====================================================================

[CmdletBinding()]
param (
    [Parameter(Position=0)]
    [string]$Action = "install",

    [Parameter(Position=1)]
    [string]$LLM = "",

    [switch]$Uninstall
)

if ($Uninstall -or $Action -ieq "remove" -or $Action -ieq "uninstall") {
    $Action = "remove"
} else {
    $Action = "install"
}

$scriptDir = $PSScriptRoot
$templateDir = Join-Path $scriptDir ".agents\templates"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "   PHP Upgrade Agent and Security Hardener - Plugin Manager         " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "Easily add or remove AI plugins, skills, and modernization adapters.`n"

# Modular LLM Provider Directory
$providers = @(
    @{ Id = "copilot";  Name = "GitHub Copilot";                        Default = $true },
    @{ Id = "claude";   Name = "Claude Code (Plugin & Slash Commands)"; Default = $false },
    @{ Id = "cursor";   Name = "Cursor";                                Default = $false },
    @{ Id = "windsurf"; Name = "Windsurf";                              Default = $false },
    @{ Id = "gemini";   Name = "Gemini Code Assist / Antigravity";      Default = $false },
    @{ Id = "codex";    Name = "OpenAI Codex / ChatGPT Dev Tools";      Default = $false },
    @{ Id = "all";      Name = "Universal Setup (All Providers)";       Default = $false }
)

if ([string]::IsNullOrWhiteSpace($LLM)) {
    Write-Host "Current Action: " -NoNewline
    if ($Action -eq "install") {
        Write-Host "INSTALL / ADD PLUGIN" -ForegroundColor Green
    } else {
        Write-Host "REMOVE / UNINSTALL PLUGIN" -ForegroundColor Yellow
    }

    Write-Host "`nSelect AI Coding Assistant:" -ForegroundColor Yellow
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
    Write-Host "  [U] Toggle Action to UNINSTALL / REMOVE"
    Write-Host ""
    $choice = Read-Host "Enter selection [1-$($providers.Count) or U] (Default: 1)"

    if ($choice -ieq "u") {
        $Action = "remove"
        Write-Host "`n[!] Action switched to: REMOVE / UNINSTALL" -ForegroundColor Yellow
        $choice = Read-Host "Select provider to remove [1-$($providers.Count)] (Default: all)"
        if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "7" }
    }

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

# --------------------------------------------------------------------
# Safe Content Merger & Cleaner
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

function Remove-Merge-Content {
    param (
        [string]$FilePath,
        [string]$MarkerName = "PHP-UPGRADE-AGENT"
    )

    if (Test-Path $FilePath) {
        $startMarker = "<!-- $MarkerName-START -->"
        $endMarker = "<!-- $MarkerName-END -->"
        $content = Get-Content $FilePath -Raw -Encoding utf8
        if ($content -match [regex]::Escape($startMarker) -and $content -match [regex]::Escape($endMarker)) {
            $pattern = "(?s)\r?\n?" + [regex]::Escape($startMarker) + ".*?" + [regex]::Escape($endMarker) + "\r?\n?"
            $cleaned = [regex]::Replace($content, $pattern, "").Trim()
            if ([string]::IsNullOrWhiteSpace($cleaned)) {
                Remove-Item $FilePath -Force
                Write-Host "  [-] Removed $FilePath (was only containing plugin configuration)" -ForegroundColor Yellow
            } else {
                Set-Content -Path $FilePath -Value $cleaned -Encoding utf8
                Write-Host "  [-] Cleaned $FilePath (removed plugin block, preserved your other settings)" -ForegroundColor Yellow
            }
        }
    }
}

# --------------------------------------------------------------------
# Installation Routines
# --------------------------------------------------------------------
function Install-Copilot {
    Write-Host "[*] Adding GitHub Copilot plugin adapter..."
    $copilotContent = Get-Content (Join-Path $templateDir "copilot-instructions.md") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $scriptDir ".github\copilot-instructions.md") -Content $copilotContent
}

function Install-Claude {
    Write-Host "[*] Adding Claude Code plugin & slash commands..."
    $claudeContent = Get-Content (Join-Path $templateDir "CLAUDE.md") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $scriptDir "CLAUDE.md") -Content $claudeContent
    Write-Host "  [+] Claude Code plugin manifest active in .claude-plugin\plugin.json" -ForegroundColor Green
    Write-Host "  [+] Slash commands active: /php-audit, /php-upgrade, /laravel-upgrade, /php2shell-fix" -ForegroundColor Green
}

function Install-Cursor {
    Write-Host "[*] Adding Cursor plugin adapter..."
    $cursorContent = Get-Content (Join-Path $templateDir "cursorrules") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $scriptDir ".cursorrules") -Content $cursorContent
    $cursorRulesDir = Join-Path $scriptDir ".cursor\rules"
    if (-not (Test-Path $cursorRulesDir)) { New-Item -ItemType Directory -Path $cursorRulesDir -Force | Out-Null }
    Safe-Merge-Content -FilePath (Join-Path $cursorRulesDir "php-upgrade.mdc") -Content $cursorContent
}

function Install-Windsurf {
    Write-Host "[*] Adding Windsurf plugin adapter..."
    $windsurfContent = Get-Content (Join-Path $templateDir "windsurfrules") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $scriptDir ".windsurfrules") -Content $windsurfContent
    $windsurfRulesDir = Join-Path $scriptDir ".windsurf\rules"
    if (-not (Test-Path $windsurfRulesDir)) { New-Item -ItemType Directory -Path $windsurfRulesDir -Force | Out-Null }
    Safe-Merge-Content -FilePath (Join-Path $windsurfRulesDir "php-upgrade.md") -Content $windsurfContent
}

function Install-Gemini {
    Write-Host "[*] Adding Gemini Code Assist / Antigravity plugin adapter..."
    $geminiContent = Get-Content (Join-Path $templateDir "GEMINI.md") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $scriptDir "GEMINI.md") -Content $geminiContent
}

function Install-Codex {
    Write-Host "[*] Adding OpenAI Codex / ChatGPT Dev Tools plugin adapter..."
    $codexContent = Get-Content (Join-Path $templateDir "codex-instructions.md") -Raw -Encoding utf8
    $chatgptDir = Join-Path $scriptDir ".chatgpt"
    if (-not (Test-Path $chatgptDir)) { New-Item -ItemType Directory -Path $chatgptDir -Force | Out-Null }
    Safe-Merge-Content -FilePath (Join-Path $chatgptDir "instructions.md") -Content $codexContent
}

# --------------------------------------------------------------------
# Removal Routines
# --------------------------------------------------------------------
function Remove-Copilot {
    Write-Host "[*] Removing GitHub Copilot adapter..."
    Remove-Merge-Content -FilePath (Join-Path $scriptDir ".github\copilot-instructions.md")
}

function Remove-Claude {
    Write-Host "[*] Removing Claude Code adapter..."
    Remove-Merge-Content -FilePath (Join-Path $scriptDir "CLAUDE.md")
}

function Remove-Cursor {
    Write-Host "[*] Removing Cursor adapter..."
    Remove-Merge-Content -FilePath (Join-Path $scriptDir ".cursorrules")
    Remove-Merge-Content -FilePath (Join-Path $scriptDir ".cursor\rules\php-upgrade.mdc")
}

function Remove-Windsurf {
    Write-Host "[*] Removing Windsurf adapter..."
    Remove-Merge-Content -FilePath (Join-Path $scriptDir ".windsurfrules")
    Remove-Merge-Content -FilePath (Join-Path $scriptDir ".windsurf\rules\php-upgrade.md")
}

function Remove-Gemini {
    Write-Host "[*] Removing Gemini Code Assist adapter..."
    Remove-Merge-Content -FilePath (Join-Path $scriptDir "GEMINI.md")
}

function Remove-Codex {
    Write-Host "[*] Removing OpenAI Codex / ChatGPT adapter..."
    Remove-Merge-Content -FilePath (Join-Path $scriptDir ".chatgpt\instructions.md")
}

# --------------------------------------------------------------------
# Execute Action
# --------------------------------------------------------------------
if ($Action -eq "install") {
    switch ($LLM) {
        "copilot"  { Install-Copilot }
        "claude"   { Install-Claude }
        "cursor"   { Install-Cursor }
        "windsurf" { Install-Windsurf }
        "gemini"   { Install-Gemini }
        "codex"    { Install-Codex }
        default    {
            Install-Copilot
            Install-Claude
            Install-Cursor
            Install-Windsurf
            Install-Gemini
            Install-Codex
        }
    }

    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host "   [+] PLUGIN INSTALLED: All Skills and Adapters Are Active!       " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host "Canonical rules and skills reside safely in: .agents/"
    Write-Host "To remove anytime, run: .\install.ps1 -Uninstall`n" -ForegroundColor DarkGray

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
} else {
    switch ($LLM) {
        "copilot"  { Remove-Copilot }
        "claude"   { Remove-Claude }
        "cursor"   { Remove-Cursor }
        "windsurf" { Remove-Windsurf }
        "gemini"   { Remove-Gemini }
        "codex"    { Remove-Codex }
        default    {
            Remove-Copilot
            Remove-Claude
            Remove-Cursor
            Remove-Windsurf
            Remove-Gemini
            Remove-Codex
        }
    }

    Write-Host "`n====================================================================" -ForegroundColor Yellow
    Write-Host "   [-] PLUGIN REMOVED: Cleanly uninstalled selected adapters!      " -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Yellow
    Write-Host "To re-add anytime, simply run: .\install.ps1`n" -ForegroundColor Green
}

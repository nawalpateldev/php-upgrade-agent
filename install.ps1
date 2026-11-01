# ====================================================================
# Universal AI Agent & Plugin Manager (Windows PowerShell)
# Installs or removes PHP Upgrade Agent into your Project Root
# Supports: Copilot, Claude, Cursor, Windsurf, Gemini, Codex
# ====================================================================

[CmdletBinding()]
param (
    [Parameter(Position=0)]
    [string]$Action = "install",

    [Parameter(Position=1)]
    [string]$LLM = "",

    [Parameter(Position=2)]
    [Alias("Path", "Target", "Project")]
    [string]$TargetPath = "",

    [switch]$Uninstall
)

if ($Uninstall -or $Action -ieq "remove" -or $Action -ieq "uninstall") {
    $Action = "remove"
} else {
    $Action = "install"
}

$toolkitDir = $PSScriptRoot
$templateDir = Join-Path $toolkitDir ".agents\templates"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "   PHP Upgrade Agent & Security Hardener - Project Plugin Installer " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "Installs agent skills, rules, and AI adapters directly into your Project Root.`n"

# --------------------------------------------------------------------
# 1. Detect & Resolve Target Project Root
# --------------------------------------------------------------------
$parentDir = Split-Path $toolkitDir -Parent

# Check if parent directory looks like a PHP project (contains composer.json or artisan)
$hasParentProject = $false
if ($parentDir -and (Test-Path $parentDir)) {
    if ((Test-Path (Join-Path $parentDir "composer.json")) -or (Test-Path (Join-Path $parentDir "artisan"))) {
        $hasParentProject = $true
    }
}

if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    $suggestedTarget = if ($hasParentProject) { $parentDir } else { $toolkitDir }

    Write-Host "Select Target Project Root:" -ForegroundColor Yellow
    if ($hasParentProject) {
        Write-Host "  [1] Parent Project Root ($suggestedTarget) " -NoNewline
        Write-Host "(Recommended - Press Enter)" -ForegroundColor Green
        Write-Host "  [2] Current Directory ($toolkitDir)"
        Write-Host "  [3] Custom Path"
        $pathChoice = Read-Host "`nEnter selection [1-3] or type absolute path (Default: 1)"

        if ([string]::IsNullOrWhiteSpace($pathChoice) -or $pathChoice -eq "1") {
            $TargetPath = $suggestedTarget
        } elseif ($pathChoice -eq "2") {
            $TargetPath = $toolkitDir
        } elseif (Test-Path $pathChoice) {
            $TargetPath = $pathChoice
        } else {
            $customPath = Read-Host "Enter full path to project root"
            $TargetPath = if (Test-Path $customPath) { $customPath } else { $suggestedTarget }
        }
    } else {
        Write-Host "  [1] Current Directory ($toolkitDir) " -NoNewline
        Write-Host "(Default - Press Enter)" -ForegroundColor Green
        Write-Host "  [2] Parent Directory ($parentDir)"
        Write-Host "  [3] Custom Path"
        $pathChoice = Read-Host "`nEnter selection [1-3] (Default: 1)"

        if ($pathChoice -eq "2") {
            $TargetPath = $parentDir
        } elseif ($pathChoice -eq "3") {
            $customPath = Read-Host "Enter full path to project root"
            $TargetPath = if (Test-Path $customPath) { $customPath } else { $toolkitDir }
        } else {
            $TargetPath = $toolkitDir
        }
    }
}

# Resolve to clean absolute path
$targetDir = (Resolve-Path $TargetPath).Path
Write-Host "`n[*] Target Project Root: " -NoNewline
Write-Host "$targetDir" -ForegroundColor Cyan

# --------------------------------------------------------------------
# 2. Select AI Provider
# --------------------------------------------------------------------
$providers = @(
    @{ Id = "copilot";  Name = "GitHub Copilot (.github/)";             Default = $true },
    @{ Id = "claude";   Name = "Claude Code (.claude/ & CLAUDE.md)";     Default = $false },
    @{ Id = "cursor";   Name = "Cursor (.cursor/ & .cursorrules)";       Default = $false },
    @{ Id = "windsurf"; Name = "Windsurf (.windsurf/ & .windsurfrules)"; Default = $false },
    @{ Id = "gemini";   Name = "Gemini Code Assist (GEMINI.md)";         Default = $false },
    @{ Id = "codex";    Name = "OpenAI Codex / ChatGPT (.chatgpt/)";     Default = $false },
    @{ Id = "all";      Name = "Universal Setup (All Providers)";        Default = $false }
)

if ([string]::IsNullOrWhiteSpace($LLM)) {
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
        $choice = Read-Host "Select provider to remove [1-$($providers.Count)] (Default: 7/all)"
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
# 3. Helpers: Safe Content Merger & Cleaner
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

    $parentFolder = Split-Path $FilePath
    if (-not (Test-Path $parentFolder)) {
        New-Item -ItemType Directory -Path $parentFolder -Force | Out-Null
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
            Write-Host "  [+] Appended to existing $FilePath (preserved existing settings)" -ForegroundColor Green
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
# 4. Copy Core Skills & Rules to Project Root (if different directory)
# --------------------------------------------------------------------
function Sync-Agents-Folder {
    $targetAgents = Join-Path $targetDir ".agents"
    if ($targetDir -ne $toolkitDir) {
        Write-Host "[*] Syncing .agents/ skills and rules into project root..."
        if (-not (Test-Path $targetAgents)) { New-Item -ItemType Directory -Path $targetAgents -Force | Out-Null }
        
        $srcSkills = Join-Path $toolkitDir ".agents\skills"
        $destSkills = Join-Path $targetAgents "skills"
        if (Test-Path $srcSkills) {
            Copy-Item -Path $srcSkills -Destination $destSkills -Recurse -Force
        }

        $srcRules = Join-Path $toolkitDir ".agents\rules"
        $destRules = Join-Path $targetAgents "rules"
        if (Test-Path $srcRules) {
            Copy-Item -Path $srcRules -Destination $destRules -Recurse -Force
        }

        Write-Host "  [+] .agents/ synced to project root: $targetAgents" -ForegroundColor Green
    }
}

# --------------------------------------------------------------------
# 5. Installation Routines (Targeting $targetDir)
# --------------------------------------------------------------------
function Install-Copilot {
    Write-Host "[*] Configuring GitHub Copilot adapter in project root ($targetDir\.github)..."
    $copilotContent = Get-Content (Join-Path $templateDir "copilot-instructions.md") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $targetDir ".github\copilot-instructions.md") -Content $copilotContent

    # Copy prompts into project root .github/prompts (if different directory)
    $srcPrompts = Join-Path $toolkitDir ".github\prompts"
    $destPrompts = Join-Path $targetDir ".github\prompts"
    if ($targetDir -ne $toolkitDir -and (Test-Path $srcPrompts)) {
        if (-not (Test-Path $destPrompts)) { New-Item -ItemType Directory -Path $destPrompts -Force | Out-Null }
        Copy-Item -Path "$srcPrompts\*" -Destination $destPrompts -Force
        Write-Host "  [+] Prompts installed into $destPrompts" -ForegroundColor Green
    }
}

function Install-Claude {
    Write-Host "[*] Configuring Claude Code plugin in project root ($targetDir\.claude)..."
    $claudeContent = Get-Content (Join-Path $templateDir "CLAUDE.md") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $targetDir "CLAUDE.md") -Content $claudeContent

    # Copy Claude commands and plugin manifest into project root (if different directory)
    if ($targetDir -ne $toolkitDir) {
        $srcCommands = Join-Path $toolkitDir ".claude\commands"
        $destCommands = Join-Path $targetDir ".claude\commands"
        if (Test-Path $srcCommands) {
            if (-not (Test-Path $destCommands)) { New-Item -ItemType Directory -Path $destCommands -Force | Out-Null }
            Copy-Item -Path "$srcCommands\*" -Destination $destCommands -Force
            Write-Host "  [+] Slash commands installed into $destCommands" -ForegroundColor Green
        }

        $srcClaudePlugin = Join-Path $toolkitDir ".claude-plugin"
        $destClaudePlugin = Join-Path $targetDir ".claude-plugin"
        if (Test-Path $srcClaudePlugin) {
            if (-not (Test-Path $destClaudePlugin)) { New-Item -ItemType Directory -Path $destClaudePlugin -Force | Out-Null }
            Copy-Item -Path "$srcClaudePlugin\*" -Destination $destClaudePlugin -Force
            Write-Host "  [+] Plugin manifest installed into $destClaudePlugin\plugin.json" -ForegroundColor Green
        }
    }
}

function Install-Cursor {
    Write-Host "[*] Configuring Cursor adapter in project root ($targetDir\.cursor)..."
    $cursorContent = Get-Content (Join-Path $templateDir "cursorrules") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $targetDir ".cursorrules") -Content $cursorContent
    $cursorRulesDir = Join-Path $targetDir ".cursor\rules"
    if (-not (Test-Path $cursorRulesDir)) { New-Item -ItemType Directory -Path $cursorRulesDir -Force | Out-Null }
    Safe-Merge-Content -FilePath (Join-Path $cursorRulesDir "php-upgrade.mdc") -Content $cursorContent
}

function Install-Windsurf {
    Write-Host "[*] Configuring Windsurf adapter in project root ($targetDir\.windsurf)..."
    $windsurfContent = Get-Content (Join-Path $templateDir "windsurfrules") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $targetDir ".windsurfrules") -Content $windsurfContent
    $windsurfRulesDir = Join-Path $targetDir ".windsurf\rules"
    if (-not (Test-Path $windsurfRulesDir)) { New-Item -ItemType Directory -Path $windsurfRulesDir -Force | Out-Null }
    Safe-Merge-Content -FilePath (Join-Path $windsurfRulesDir "php-upgrade.md") -Content $windsurfContent
}

function Install-Gemini {
    Write-Host "[*] Configuring Gemini Code Assist / Antigravity in project root ($targetDir\GEMINI.md)..."
    $geminiContent = Get-Content (Join-Path $templateDir "GEMINI.md") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $targetDir "GEMINI.md") -Content $geminiContent
}

function Install-Codex {
    Write-Host "[*] Configuring OpenAI Codex / ChatGPT in project root ($targetDir\.chatgpt)..."
    $codexContent = Get-Content (Join-Path $templateDir "codex-instructions.md") -Raw -Encoding utf8
    $chatgptDir = Join-Path $targetDir ".chatgpt"
    if (-not (Test-Path $chatgptDir)) { New-Item -ItemType Directory -Path $chatgptDir -Force | Out-Null }
    Safe-Merge-Content -FilePath (Join-Path $chatgptDir "instructions.md") -Content $codexContent
}

# --------------------------------------------------------------------
# 6. Removal Routines (Targeting $targetDir)
# --------------------------------------------------------------------
function Remove-Copilot {
    Write-Host "[*] Removing GitHub Copilot adapter from $targetDir\.github..."
    Remove-Merge-Content -FilePath (Join-Path $targetDir ".github\copilot-instructions.md")
}

function Remove-Claude {
    Write-Host "[*] Removing Claude Code adapter from $targetDir..."
    Remove-Merge-Content -FilePath (Join-Path $targetDir "CLAUDE.md")
    $cmdDir = Join-Path $targetDir ".claude\commands"
    if (Test-Path $cmdDir) {
        Remove-Item (Join-Path $cmdDir "php-audit.md") -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $cmdDir "php-upgrade.md") -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $cmdDir "laravel-upgrade.md") -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $cmdDir "php2shell-fix.md") -ErrorAction SilentlyContinue
    }
}

function Remove-Cursor {
    Write-Host "[*] Removing Cursor adapter from $targetDir..."
    Remove-Merge-Content -FilePath (Join-Path $targetDir ".cursorrules")
    Remove-Merge-Content -FilePath (Join-Path $targetDir ".cursor\rules\php-upgrade.mdc")
}

function Remove-Windsurf {
    Write-Host "[*] Removing Windsurf adapter from $targetDir..."
    Remove-Merge-Content -FilePath (Join-Path $targetDir ".windsurfrules")
    Remove-Merge-Content -FilePath (Join-Path $targetDir ".windsurf\rules\php-upgrade.md")
}

function Remove-Gemini {
    Write-Host "[*] Removing Gemini Code Assist adapter from $targetDir..."
    Remove-Merge-Content -FilePath (Join-Path $targetDir "GEMINI.md")
}

function Remove-Codex {
    Write-Host "[*] Removing OpenAI Codex / ChatGPT adapter from $targetDir..."
    Remove-Merge-Content -FilePath (Join-Path $targetDir ".chatgpt\instructions.md")
}

# --------------------------------------------------------------------
# 7. Execute Action
# --------------------------------------------------------------------
if ($Action -eq "install") {
    Sync-Agents-Folder

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
    Write-Host "   [+] PLUGIN INSTALLED: Project Root is Fully Configured!          " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host "Project Root: $targetDir" -ForegroundColor Cyan
    Write-Host "Canonical rules and skills reside safely in: $targetDir\.agents\" -ForegroundColor Cyan
    Write-Host "To remove anytime, run: .\install.ps1 -Uninstall -TargetPath `"$targetDir`"`n" -ForegroundColor DarkGray

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
    Write-Host "   [-] PLUGIN REMOVED: Cleanly uninstalled from Project Root!      " -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Yellow
    Write-Host "Target: $targetDir" -ForegroundColor Cyan
    Write-Host "To re-add anytime, simply run: .\install.ps1 -TargetPath `"$targetDir`"`n" -ForegroundColor Green
}

# ====================================================================
# Universal AI Agent & Plugin Manager (Windows PowerShell)
# Installs or removes PHP Upgrade Agents & Skills into your Project Root
# Supports Multi-Select (e.g. Copilot, Claude, Gemini in one run)
#
# SAFETY GUARANTEES:
# 1. NEVER touches or modifies any PHP source code (*.php) or application files.
# 2. NEVER runs composer install on user's target project.
# 3. NEVER deletes any user file, folder, or custom configurations.
# 4. Strictly additive: all AI instructions are safely isolated between
#    <!-- PHP-UPGRADE-AGENT-START --> and <!-- PHP-UPGRADE-AGENT-END --> markers.
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
Write-Host "   PHP Upgrade Agent & Skills - Multi-LLM Plugin Installer          " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "[SAFETY INVARIANT] Never modifies your PHP code, database, or composer files.`n" -ForegroundColor Green

# 6 Core Modernization & Security Skills
$toolkitSkills = @(
    "php-core-upgrader",
    "laravel-upgrader",
    "symfony-upgrader",
    "codeigniter-upgrader",
    "php2shell-fixer",
    "php-security-hardener"
)

# 3 Specialized Agent Definitions
$toolkitAgents = @(
    "php-upgrade-architect.agent.json",
    "framework-migrator.agent.json",
    "php2shell-remediator.agent.json"
)

# Claude Slash Commands
$toolkitClaudeCommands = @(
    "php-audit.md",
    "php-upgrade.md",
    "laravel-upgrade.md",
    "php2shell-fix.md"
)

# --------------------------------------------------------------------
# 1. Detect & Resolve Target Project Root
# --------------------------------------------------------------------
$parentDir = Split-Path $toolkitDir -Parent
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
        $pathChoice = Read-Host "`nEnter selection [1-3 or path] (Default: 1)"

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

$targetDir = (Resolve-Path $TargetPath).Path
Write-Host "`n[*] Target Project Root: " -NoNewline
Write-Host "$targetDir" -ForegroundColor Cyan

# --------------------------------------------------------------------
# 2. Select AI Provider(s) - Supports Multi-Select
# --------------------------------------------------------------------
$providers = @(
    @{ Id = "copilot";  Name = "GitHub Copilot (Agents in .github/agents/ & .github/skills/)"; Default = $true },
    @{ Id = "claude";   Name = "Claude Code (Skills in .claude/skills/ & CLAUDE.md)";          Default = $false },
    @{ Id = "cursor";   Name = "Cursor (Agent Rules in .cursor/rules/)";                      Default = $false },
    @{ Id = "windsurf"; Name = "Windsurf (Agent Rules in .windsurf/rules/)";                  Default = $false },
    @{ Id = "gemini";   Name = "Gemini Code Assist / Antigravity (.agents/ & GEMINI.md)";      Default = $false },
    @{ Id = "codex";    Name = "OpenAI Codex / ChatGPT Dev Tools (.chatgpt/)";                 Default = $false },
    @{ Id = "all";      Name = "Universal Setup (All Providers)";                             Default = $false }
)

if ([string]::IsNullOrWhiteSpace($LLM)) {
    Write-Host "`nSelect AI Coding Assistant(s):" -ForegroundColor Yellow
    Write-Host "  Tip: You can select multiple assistants (e.g. 1,2,5 or 1 2 5)" -ForegroundColor DarkGray
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
    $rawChoice = Read-Host "Enter selection [e.g. 1,2,5 or press Enter for 1]"

    if ($rawChoice -ieq "u") {
        $Action = "remove"
        Write-Host "`n[!] Action switched to: REMOVE / UNINSTALL" -ForegroundColor Yellow
        $rawChoice = Read-Host "Select provider(s) to remove [e.g. 1,2 or all] (Default: all)"
        if ([string]::IsNullOrWhiteSpace($rawChoice)) { $rawChoice = "7" }
    }

    $LLM = $rawChoice
}

# Parse Multi-Select Input
$selectedLLMs = @()
if ([string]::IsNullOrWhiteSpace($LLM) -or $LLM.Trim() -eq "1") {
    $selectedLLMs = @("copilot")
} else {
    $tokens = $LLM -split '[,;\s]+' | Where-Object { $_ -ne "" }
    foreach ($token in $tokens) {
        if ($token -match '^\d+$' -and [int]$token -ge 1 -and [int]$token -le $providers.Count) {
            $selectedLLMs += $providers[[int]$token - 1].Id
        } else {
            $matched = $providers | Where-Object { $_.Id -ieq $token }
            if ($matched) {
                $selectedLLMs += $matched.Id
            }
        }
    }
    if ($selectedLLMs.Count -eq 0) {
        $selectedLLMs = @("copilot")
    }
}

if ($selectedLLMs -contains "all") {
    $selectedLLMs = @("copilot", "claude", "cursor", "windsurf", "gemini", "codex")
} else {
    $selectedLLMs = $selectedLLMs | Select-Object -Unique
}

Write-Host "`n[*] Selected Assistant(s) to $($Action.ToUpper()): " -NoNewline
Write-Host ($selectedLLMs -join ", ").ToUpper() -ForegroundColor Green

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
            Write-Host "  [+] Updated $FilePath (safely updated isolated agent block)" -ForegroundColor Green
        } else {
            Add-Content -Path $FilePath -Value $wrappedContent -Encoding utf8
            Write-Host "  [+] Appended to existing $FilePath (your original settings are 100% preserved)" -ForegroundColor Green
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
            Set-Content -Path $FilePath -Value $cleaned -Encoding utf8
            Write-Host "  [-] Cleaned $FilePath (removed agent block, your other settings are untouched)" -ForegroundColor Yellow
        }
    }
}

# --------------------------------------------------------------------
# 4. Sync Canonical Skills & Rules into Project Root
# --------------------------------------------------------------------
function Sync-Agents-Folder {
    $targetAgents = Join-Path $targetDir ".agents"
    if ($targetDir -ne $toolkitDir) {
        Write-Host "[*] Syncing PHP modernization skills & agents into $targetAgents..."
        $destSkills = Join-Path $targetAgents "skills"
        $destRules = Join-Path $targetAgents "rules"
        $destAgents = Join-Path $targetAgents "agents"

        if (-not (Test-Path $destSkills)) { New-Item -ItemType Directory -Path $destSkills -Force | Out-Null }
        if (-not (Test-Path $destRules)) { New-Item -ItemType Directory -Path $destRules -Force | Out-Null }
        if (-not (Test-Path $destAgents)) { New-Item -ItemType Directory -Path $destAgents -Force | Out-Null }

        # Sync 6 isolated skills
        foreach ($skill in $toolkitSkills) {
            $srcSkill = Join-Path $toolkitDir ".agents\skills\$skill"
            $destSkill = Join-Path $destSkills $skill
            if (Test-Path $srcSkill) {
                Copy-Item -Path $srcSkill -Destination $destSkill -Recurse -Force
            }
        }

        # Sync agent definitions
        $srcAgents = Join-Path $toolkitDir ".agents\agents"
        if (Test-Path $srcAgents) {
            Copy-Item -Path "$srcAgents\*" -Destination $destAgents -Force
        }

        # Sync canonical rules safely
        $srcRule = Join-Path $toolkitDir ".agents\rules\AGENTS.md"
        $destRule = Join-Path $destRules "AGENTS.md"
        if (Test-Path $srcRule) {
            if (Test-Path $destRule) {
                $ruleContent = Get-Content $srcRule -Raw -Encoding utf8
                Safe-Merge-Content -FilePath $destRule -Content $ruleContent
            } else {
                Copy-Item -Path $srcRule -Destination $destRule -Force
            }
        }

        Write-Host "  [+] Specific PHP upgrade skills & agents synced to $targetAgents" -ForegroundColor Green
    }
}

# --------------------------------------------------------------------
# 5. Agent & Skill Setup Routines for Selected Providers
# --------------------------------------------------------------------
function Install-Copilot {
    Write-Host "[*] Configuring GitHub Copilot Agents & Skills ($targetDir\.github)..."
    
    # Ingest custom agent instructions
    $copilotContent = Get-Content (Join-Path $templateDir "copilot-instructions.md") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $targetDir ".github\copilot-instructions.md") -Content $copilotContent

    if ($targetDir -ne $toolkitDir) {
        # Deploy Copilot Agents (.github/agents/)
        $destAgents = Join-Path $targetDir ".github\agents"
        if (-not (Test-Path $destAgents)) { New-Item -ItemType Directory -Path $destAgents -Force | Out-Null }
        foreach ($agent in $toolkitAgents) {
            $src = Join-Path $toolkitDir ".github\agents\$agent"
            if (Test-Path $src) {
                Copy-Item -Path $src -Destination (Join-Path $destAgents $agent) -Force
            }
        }

        # Deploy Copilot Skills (.github/skills/)
        $destCopilotSkills = Join-Path $targetDir ".github\skills"
        if (-not (Test-Path $destCopilotSkills)) { New-Item -ItemType Directory -Path $destCopilotSkills -Force | Out-Null }
        foreach ($skill in $toolkitSkills) {
            $src = Join-Path $toolkitDir ".agents\skills\$skill"
            $dest = Join-Path $destCopilotSkills $skill
            if (Test-Path $src) {
                Copy-Item -Path $src -Destination $dest -Recurse -Force
            }
        }
    }

    Write-Host "  [+] Copilot Agents active in: $targetDir\.github\agents" -ForegroundColor Green
    Write-Host "  [+] Copilot Skills active in: $targetDir\.github\skills" -ForegroundColor Green
}

function Install-Claude {
    Write-Host "[*] Configuring Claude Code Skills & Agents ($targetDir\.claude)..."
    $claudeContent = Get-Content (Join-Path $templateDir "CLAUDE.md") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $targetDir "CLAUDE.md") -Content $claudeContent

    if ($targetDir -ne $toolkitDir) {
        # Deploy Claude Code Native Skills (.claude/skills/)
        $destClaudeSkills = Join-Path $targetDir ".claude\skills"
        if (-not (Test-Path $destClaudeSkills)) { New-Item -ItemType Directory -Path $destClaudeSkills -Force | Out-Null }
        foreach ($skill in $toolkitSkills) {
            $src = Join-Path $toolkitDir ".agents\skills\$skill"
            $dest = Join-Path $destClaudeSkills $skill
            if (Test-Path $src) {
                Copy-Item -Path $src -Destination $dest -Recurse -Force
            }
        }

        # Deploy Claude Slash Commands (.claude/commands/)
        $destCommands = Join-Path $targetDir ".claude\commands"
        if (-not (Test-Path $destCommands)) { New-Item -ItemType Directory -Path $destCommands -Force | Out-Null }
        foreach ($cmd in $toolkitClaudeCommands) {
            $src = Join-Path $toolkitDir ".claude\commands\$cmd"
            if (Test-Path $src) {
                Copy-Item -Path $src -Destination (Join-Path $destCommands $cmd) -Force
            }
        }

        # Deploy Claude Plugin Manifest (.claude-plugin/plugin.json)
        $srcPlugin = Join-Path $toolkitDir ".claude-plugin\plugin.json"
        $destPluginDir = Join-Path $targetDir ".claude-plugin"
        if (Test-Path $srcPlugin) {
            if (-not (Test-Path $destPluginDir)) { New-Item -ItemType Directory -Path $destPluginDir -Force | Out-Null }
            Copy-Item -Path $srcPlugin -Destination (Join-Path $destPluginDir "plugin.json") -Force
        }
    }

    Write-Host "  [+] Claude Skills active in: $targetDir\.claude\skills" -ForegroundColor Green
    Write-Host "  [+] Claude Slash Commands active in: $targetDir\.claude\commands" -ForegroundColor Green
}

function Install-Cursor {
    Write-Host "[*] Configuring Cursor Agent rules ($targetDir\.cursor)..."
    $cursorContent = Get-Content (Join-Path $templateDir "cursorrules") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $targetDir ".cursorrules") -Content $cursorContent
    $cursorRulesDir = Join-Path $targetDir ".cursor\rules"
    if (-not (Test-Path $cursorRulesDir)) { New-Item -ItemType Directory -Path $cursorRulesDir -Force | Out-Null }
    Safe-Merge-Content -FilePath (Join-Path $cursorRulesDir "php-upgrade.mdc") -Content $cursorContent
}

function Install-Windsurf {
    Write-Host "[*] Configuring Windsurf Agent rules ($targetDir\.windsurf)..."
    $windsurfContent = Get-Content (Join-Path $templateDir "windsurfrules") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $targetDir ".windsurfrules") -Content $windsurfContent
    $windsurfRulesDir = Join-Path $targetDir ".windsurf\rules"
    if (-not (Test-Path $windsurfRulesDir)) { New-Item -ItemType Directory -Path $windsurfRulesDir -Force | Out-Null }
    Safe-Merge-Content -FilePath (Join-Path $windsurfRulesDir "php-upgrade.md") -Content $windsurfContent
}

function Install-Gemini {
    Write-Host "[*] Configuring Gemini / Antigravity ($targetDir\GEMINI.md)..."
    $geminiContent = Get-Content (Join-Path $templateDir "GEMINI.md") -Raw -Encoding utf8
    Safe-Merge-Content -FilePath (Join-Path $targetDir "GEMINI.md") -Content $geminiContent
}

function Install-Codex {
    Write-Host "[*] Configuring OpenAI Codex / ChatGPT ($targetDir\.chatgpt)..."
    $codexContent = Get-Content (Join-Path $templateDir "codex-instructions.md") -Raw -Encoding utf8
    $chatgptDir = Join-Path $targetDir ".chatgpt"
    if (-not (Test-Path $chatgptDir)) { New-Item -ItemType Directory -Path $chatgptDir -Force | Out-Null }
    Safe-Merge-Content -FilePath (Join-Path $chatgptDir "instructions.md") -Content $codexContent
}

# --------------------------------------------------------------------
# 6. Removal Routines
# --------------------------------------------------------------------
function Remove-Copilot {
    Write-Host "[*] Removing GitHub Copilot Agents & Skills..."
    Remove-Merge-Content -FilePath (Join-Path $targetDir ".github\copilot-instructions.md")
    $agentsDir = Join-Path $targetDir ".github\agents"
    foreach ($agent in $toolkitAgents) {
        $p = Join-Path $agentsDir $agent
        if (Test-Path $p) { Remove-Item $p -Force }
    }
    $skillsDir = Join-Path $targetDir ".github\skills"
    foreach ($skill in $toolkitSkills) {
        $p = Join-Path $skillsDir $skill
        if (Test-Path $p) { Remove-Item $p -Recurse -Force }
    }
}

function Remove-Claude {
    Write-Host "[*] Removing Claude Code Skills & Commands..."
    Remove-Merge-Content -FilePath (Join-Path $targetDir "CLAUDE.md")
    $skillsDir = Join-Path $targetDir ".claude\skills"
    foreach ($skill in $toolkitSkills) {
        $p = Join-Path $skillsDir $skill
        if (Test-Path $p) { Remove-Item $p -Recurse -Force }
    }
    $cmdDir = Join-Path $targetDir ".claude\commands"
    foreach ($cmd in $toolkitClaudeCommands) {
        $p = Join-Path $cmdDir $cmd
        if (Test-Path $p) { Remove-Item $p -Force }
    }
}

function Remove-Cursor {
    Write-Host "[*] Removing Cursor Agent rules..."
    Remove-Merge-Content -FilePath (Join-Path $targetDir ".cursorrules")
    Remove-Merge-Content -FilePath (Join-Path $targetDir ".cursor\rules\php-upgrade.mdc")
}

function Remove-Windsurf {
    Write-Host "[*] Removing Windsurf Agent rules..."
    Remove-Merge-Content -FilePath (Join-Path $targetDir ".windsurfrules")
    Remove-Merge-Content -FilePath (Join-Path $targetDir ".windsurf\rules\php-upgrade.md")
}

function Remove-Gemini {
    Write-Host "[*] Removing Gemini Code Assist..."
    Remove-Merge-Content -FilePath (Join-Path $targetDir "GEMINI.md")
}

function Remove-Codex {
    Write-Host "[*] Removing OpenAI Codex / ChatGPT..."
    Remove-Merge-Content -FilePath (Join-Path $targetDir ".chatgpt\instructions.md")
}

# --------------------------------------------------------------------
# 7. Execute Action for All Selected LLMs
# --------------------------------------------------------------------
if ($Action -eq "install") {
    Sync-Agents-Folder

    foreach ($selected in $selectedLLMs) {
        switch ($selected) {
            "copilot"  { Install-Copilot }
            "claude"   { Install-Claude }
            "cursor"   { Install-Cursor }
            "windsurf" { Install-Windsurf }
            "gemini"   { Install-Gemini }
            "codex"    { Install-Codex }
        }
    }

    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host "   [+] AGENTS & SKILLS ACTIVE: Zero Code Modified, All Installed!   " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host "Project Root: $targetDir" -ForegroundColor Cyan
    Write-Host "Configured Assistants: " -NoNewline
    Write-Host ($selectedLLMs -join ", ").ToUpper() -ForegroundColor Green

    Write-Host "`nRECOMMENDED COMMANDS TO RUN (READ-ONLY / DRY-RUN FIRST):" -ForegroundColor Yellow
    Write-Host "--------------------------------------------------------------------"
    Write-Host "1. Scan for php2shell & RCE vulnerabilities:" -ForegroundColor White
    Write-Host "   php .agents/skills/php2shell-fixer/scripts/php2shell-audit.php --path=.`n" -ForegroundColor Cyan

    Write-Host "2. Scan for OWASP Top 10 security flaws:" -ForegroundColor White
    Write-Host "   php .agents/skills/php-security-hardener/scripts/security-audit.php .`n" -ForegroundColor Cyan

    Write-Host "3. Preview safe PHP Core AST modernization (Dry Run up to PHP 8.5+):" -ForegroundColor White
    Write-Host "   vendor/bin/rector process --dry-run --config=.agents/skills/php-core-upgrader/scripts/rector-php-upgrade.php`n" -ForegroundColor Cyan

    Write-Host "4. Preview Framework upgrade plan (Laravel 8 -> 12+ / Latest):" -ForegroundColor White
    Write-Host "   vendor/bin/rector process --dry-run --config=.agents/skills/laravel-upgrader/scripts/rector-laravel.php`n" -ForegroundColor Cyan

    Write-Host "5. Run static analysis deprecation audit:" -ForegroundColor White
    Write-Host "   vendor/bin/phpstan analyse -c .agents/skills/php-core-upgrader/scripts/phpstan.neon`n" -ForegroundColor Cyan

    Write-Host "OR INVOKE YOUR AGENTS DIRECTLY:" -ForegroundColor Yellow
    Write-Host '   Copilot: @php-upgrade-architect "Plan migration to PHP 8.5 and audit php2shell"' -ForegroundColor White
    Write-Host '   Claude:  /php-audit and /php-upgrade' -ForegroundColor White
    Write-Host '   Cursor/Gemini: "Audit this codebase for php2shell vulnerabilities"' -ForegroundColor White
    Write-Host "====================================================================`n" -ForegroundColor Cyan
} else {
    foreach ($selected in $selectedLLMs) {
        switch ($selected) {
            "copilot"  { Remove-Copilot }
            "claude"   { Remove-Claude }
            "cursor"   { Remove-Cursor }
            "windsurf" { Remove-Windsurf }
            "gemini"   { Remove-Gemini }
            "codex"    { Remove-Codex }
        }
    }

    Write-Host "`n====================================================================" -ForegroundColor Yellow
    Write-Host "   [-] UNINSTALL COMPLETE: Cleanly removed selected agent adapters! " -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Yellow
    Write-Host "Target: $targetDir" -ForegroundColor Cyan
    Write-Host "All your original configuration files, PHP code, and settings remain 100% intact.`n" -ForegroundColor Green
}

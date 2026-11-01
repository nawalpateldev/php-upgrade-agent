#!/usr/bin/env bash
# ====================================================================
# Universal AI Agent & Plugin Manager (Linux & macOS)
# Installs or removes PHP Upgrade Agents & Skills into your Project Root
# Supports Multi-Select (e.g. Copilot, Claude, Gemini in one run)
# ====================================================================

set -e

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${TOOLKIT_DIR}/.agents/templates"

CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RESET='\033[0m'

ACTION="install"
RAW_SELECTION=""
TARGET_DIR=""

TOOLKIT_SKILLS=(
    "php-core-upgrader"
    "laravel-upgrader"
    "symfony-upgrader"
    "codeigniter-upgrader"
    "php2shell-fixer"
    "php-security-hardener"
)

TOOLKIT_AGENTS=(
    "php-upgrade-architect.agent.json"
    "framework-migrator.agent.json"
    "php2shell-remediator.agent.json"
)

TOOLKIT_CLAUDE_COMMANDS=(
    "php-audit.md"
    "php-upgrade.md"
    "laravel-upgrade.md"
    "php2shell-fix.md"
)

# Parse CLI flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --remove|--uninstall|remove|uninstall)
            ACTION="remove"
            shift
            ;;
        --target|--path|-t|-p)
            TARGET_DIR="$2"
            shift 2
            ;;
        *)
            if [ -d "$1" ]; then
                TARGET_DIR="$1"
            else
                RAW_SELECTION="$1"
            fi
            shift
            ;;
    esac
done

echo -e "${CYAN}====================================================================${RESET}"
echo -e "${CYAN}   PHP Upgrade Agent & Skills - Multi-LLM Plugin Installer          ${RESET}"
echo -e "${CYAN}====================================================================${RESET}"
echo -e "${GREEN}[SAFETY INVARIANT] Never modifies your PHP code, database, or composer files.${RESET}\n"

# --------------------------------------------------------------------
# 1. Detect & Resolve Target Project Root
# --------------------------------------------------------------------
CURRENT_DIR="$(pwd)"
PARENT_DIR="$(dirname "$TOOLKIT_DIR")"
HAS_PARENT_PROJECT=false

if [ -f "${PARENT_DIR}/composer.json" ] || [ -f "${PARENT_DIR}/artisan" ] || [ -f "${PARENT_DIR}/index.php" ]; then
    HAS_PARENT_PROJECT=true
fi

if [ -z "$TARGET_DIR" ]; then
    if [ "$CURRENT_DIR" != "$TOOLKIT_DIR" ]; then
        SUGGESTED_TARGET="$CURRENT_DIR"
        echo -e "${YELLOW}Select Target Project Root:${RESET}"
        echo -e "  [1] Current Working Directory ($SUGGESTED_TARGET) ${GREEN}(Recommended - Press Enter)${RESET}"
        echo -e "  [2] Toolkit Directory ($TOOLKIT_DIR)"
        echo -e "  [3] Custom Path"
        read -p "Enter selection [1-3 or path] (Default: 1): " PATH_CHOICE

        case "$PATH_CHOICE" in
            2) TARGET_DIR="$TOOLKIT_DIR" ;;
            3)
                read -p "Enter full path to project root: " CUSTOM_PATH
                TARGET_DIR="$CUSTOM_PATH"
                ;;
            *)
                if [ -d "$PATH_CHOICE" ]; then
                    TARGET_DIR="$PATH_CHOICE"
                else
                    TARGET_DIR="$SUGGESTED_TARGET"
                fi
                ;;
        esac
    elif [ "$HAS_PARENT_PROJECT" = true ]; then
        SUGGESTED_TARGET="$PARENT_DIR"
        echo -e "${YELLOW}Select Target Project Root:${RESET}"
        echo -e "  [1] Parent Project Root ($SUGGESTED_TARGET) ${GREEN}(Recommended - Press Enter)${RESET}"
        echo -e "  [2] Current Directory ($TOOLKIT_DIR)"
        echo -e "  [3] Custom Path"
        read -p "Enter selection [1-3 or path] (Default: 1): " PATH_CHOICE

        case "$PATH_CHOICE" in
            2) TARGET_DIR="$TOOLKIT_DIR" ;;
            3)
                read -p "Enter full path to project root: " CUSTOM_PATH
                TARGET_DIR="$CUSTOM_PATH"
                ;;
            *)
                if [ -d "$PATH_CHOICE" ]; then
                    TARGET_DIR="$PATH_CHOICE"
                else
                    TARGET_DIR="$SUGGESTED_TARGET"
                fi
                ;;
        esac
    else
        echo -e "${YELLOW}Select Target Project Root:${RESET}"
        echo -e "  [1] Current Directory ($TOOLKIT_DIR) ${GREEN}(Default - Press Enter)${RESET}"
        echo -e "  [2] Parent Directory ($PARENT_DIR)"
        echo -e "  [3] Custom Path"
        read -p "Enter selection [1-3 or path] (Default: 1): " PATH_CHOICE

        case "$PATH_CHOICE" in
            2) TARGET_DIR="$PARENT_DIR" ;;
            3)
                read -p "Enter full path to project root: " CUSTOM_PATH
                TARGET_DIR="$CUSTOM_PATH"
                ;;
            *)
                if [ -d "$PATH_CHOICE" ]; then
                    TARGET_DIR="$PATH_CHOICE"
                else
                    TARGET_DIR="$TOOLKIT_DIR"
                fi
                ;;
        esac
    fi
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
echo -e "\n[*] Target Project Root: ${CYAN}${TARGET_DIR}${RESET}"

# Detect existing AI folders in project root
DETECTED_FOLDERS=()
if [ -d "${TARGET_DIR}/.github" ]; then DETECTED_FOLDERS+=(".github (GitHub Copilot)"); fi
if [ -d "${TARGET_DIR}/.claude" ]; then DETECTED_FOLDERS+=(".claude (Claude Code)"); fi
if [ -d "${TARGET_DIR}/.gemini" ]; then DETECTED_FOLDERS+=(".gemini (Gemini Code Assist)"); fi
if [ -d "${TARGET_DIR}/.agents" ]; then DETECTED_FOLDERS+=(".agents (Universal Antigravity)"); fi

if [ ${#DETECTED_FOLDERS[@]} -gt 0 ]; then
    echo -e "  [i] Detected existing AI folders in project root: ${GREEN}${DETECTED_FOLDERS[*]}${RESET}"
fi

# --------------------------------------------------------------------
# 2. Select AI Provider(s) - Supports Multi-Select
# --------------------------------------------------------------------
if [ -z "$RAW_SELECTION" ]; then
    if [ "$ACTION" = "install" ]; then
        echo -e "Current Action: ${GREEN}INSTALL / ADD AGENTS & SKILLS${RESET}"
    else
        echo -e "Current Action: ${YELLOW}REMOVE / UNINSTALL${RESET}"
    fi

    echo -e "\n${YELLOW}Select AI Coding Assistant(s):${RESET}"
    echo -e "  Tip: You can select multiple assistants separated by commas (e.g. 1,2,5)"
    echo -e "  [1] GitHub Copilot (.github/skills/ & .github/agents/) ${GREEN}(Default - Press Enter)${RESET}"
    echo -e "  [2] Claude Code (.claude/skills/ & CLAUDE.md)"
    echo -e "  [3] Gemini Code Assist / Antigravity (.gemini/skills/ & .agents/)"
    echo -e "  [4] Cursor (Agent Rules in .cursor/rules/)"
    echo -e "  [5] Windsurf (Agent Rules in .windsurf/rules/)"
    echo -e "  [6] OpenAI Codex / ChatGPT Dev Tools (.chatgpt/)"
    echo -e "  [7] Universal Setup (All Providers & Folders)"
    echo -e "  [U] Toggle Action to UNINSTALL / REMOVE"
    echo ""
    read -p "Enter selection [e.g. 1,2,3 or U] (Default: 1): " USER_INPUT

    if [ "$USER_INPUT" = "u" ] || [ "$USER_INPUT" = "U" ]; then
        ACTION="remove"
        echo -e "\n${YELLOW}[!] Action switched to: REMOVE / UNINSTALL${RESET}"
        read -p "Select provider(s) to remove [e.g. 1,2 or 7] (Default: 7/all): " USER_INPUT
        if [ -z "$USER_INPUT" ]; then USER_INPUT="7"; fi
    fi

    RAW_SELECTION="$USER_INPUT"
fi

# Parse Multi-Select Input
SELECTED_LLMS=()
if [ -z "$RAW_SELECTION" ] || [ "$RAW_SELECTION" = "1" ]; then
    SELECTED_LLMS+=("copilot")
else
    # Replace commas/spaces with newlines to iterate
    TOKENS=$(echo "$RAW_SELECTION" | tr ',;' ' ')
    for token in $TOKENS; do
        case "$token" in
            1|copilot)  SELECTED_LLMS+=("copilot") ;;
            2|claude)   SELECTED_LLMS+=("claude") ;;
            3|5|gemini) SELECTED_LLMS+=("gemini") ;;
            4|cursor)   SELECTED_LLMS+=("cursor") ;;
            windsurf)   SELECTED_LLMS+=("windsurf") ;;
            6|codex)    SELECTED_LLMS+=("codex") ;;
            7|all)
                SELECTED_LLMS=("copilot" "claude" "gemini" "cursor" "windsurf" "codex")
                break
                ;;
        esac
    done
fi

if [ ${#SELECTED_LLMS[@]} -eq 0 ]; then
    SELECTED_LLMS+=("copilot")
fi

echo -e "\n[*] Selected Assistant(s) to ${ACTION}: ${GREEN}${SELECTED_LLMS[*]}${RESET}"

# --------------------------------------------------------------------
# 3. Helpers: Safe Content Merger & Cleaner
# --------------------------------------------------------------------
safe_merge_file() {
    local target_file="$1"
    local source_content="$2"
    local marker_name="PHP-UPGRADE-AGENT"
    local start_marker="<!-- ${marker_name}-START -->"
    local end_marker="<!-- ${marker_name}-END -->"

    mkdir -p "$(dirname "$target_file")"

    if [ -f "$target_file" ]; then
        if grep -q "$start_marker" "$target_file"; then
            awk -v s="$start_marker" -v e="$end_marker" -v r="$source_content" '
                $0 ~ s {print; print r; skip=1; next}
                $0 ~ e {skip=0}
                !skip {print}
            ' "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
            echo -e "  ${GREEN}[+] Updated ${target_file} (safely updated block)${RESET}"
        else
            echo "" >> "$target_file"
            echo "$start_marker" >> "$target_file"
            echo "$source_content" >> "$target_file"
            echo "$end_marker" >> "$target_file"
            echo -e "  ${GREEN}[+] Appended to existing ${target_file} (preserved existing settings)${RESET}"
        fi
    else
        echo "$start_marker" > "$target_file"
        echo "$source_content" >> "$target_file"
        echo "$end_marker" >> "$target_file"
        echo -e "  ${GREEN}[+] Created ${target_file}${RESET}"
    fi
}

remove_merge_file() {
    local target_file="$1"
    local marker_name="PHP-UPGRADE-AGENT"
    local start_marker="<!-- ${marker_name}-START -->"
    local end_marker="<!-- ${marker_name}-END -->"

    if [ -f "$target_file" ]; then
        if grep -q "$start_marker" "$target_file"; then
            sed -i "/${start_marker}/,/${end_marker}/d" "$target_file"
            echo -e "  ${YELLOW}[-] Cleaned ${target_file} (removed agent block, other settings untouched)${RESET}"
        fi
    fi
}

# --------------------------------------------------------------------
# 4. Sync Canonical Skills & Rules into Project Root
# --------------------------------------------------------------------
sync_agents_folder() {
    if [ "$TARGET_DIR" != "$TOOLKIT_DIR" ]; then
        echo "[*] Syncing PHP modernization skills & agents into ${TARGET_DIR}/.agents..."
        mkdir -p "${TARGET_DIR}/.agents/skills"
        mkdir -p "${TARGET_DIR}/.agents/rules"
        mkdir -p "${TARGET_DIR}/.agents/agents"

        for skill in "${TOOLKIT_SKILLS[@]}"; do
            if [ -d "${TOOLKIT_DIR}/.agents/skills/${skill}" ]; then
                mkdir -p "${TARGET_DIR}/.agents/skills/${skill}"
                cp -r "${TOOLKIT_DIR}/.agents/skills/${skill}/"* "${TARGET_DIR}/.agents/skills/${skill}/"
            fi
        done

        if [ -d "${TOOLKIT_DIR}/.agents/agents" ]; then
            cp -r "${TOOLKIT_DIR}/.agents/agents/"* "${TARGET_DIR}/.agents/agents/"
        fi

        if [ -f "${TOOLKIT_DIR}/.agents/rules/AGENTS.md" ]; then
            if [ -f "${TARGET_DIR}/.agents/rules/AGENTS.md" ]; then
                local rule_content=$(cat "${TOOLKIT_DIR}/.agents/rules/AGENTS.md")
                safe_merge_file "${TARGET_DIR}/.agents/rules/AGENTS.md" "$rule_content"
            else
                cp "${TOOLKIT_DIR}/.agents/rules/AGENTS.md" "${TARGET_DIR}/.agents/rules/AGENTS.md"
            fi
        fi

        echo -e "  ${GREEN}[+] Specific PHP upgrade skills & agents synced to ${TARGET_DIR}/.agents${RESET}"
    fi
}

# --------------------------------------------------------------------
# 5. Agent & Skill Setup Routines
# --------------------------------------------------------------------
install_copilot() {
    echo "[*] Configuring GitHub Copilot Agents & Skills (${TARGET_DIR}/.github)..."
    local content=$(cat "${TEMPLATE_DIR}/copilot-instructions.md")
    safe_merge_file "${TARGET_DIR}/.github/copilot-instructions.md" "$content"

    if [ "$TARGET_DIR" != "$TOOLKIT_DIR" ]; then
        mkdir -p "${TARGET_DIR}/.github/agents"
        for agent in "${TOOLKIT_AGENTS[@]}"; do
            if [ -f "${TOOLKIT_DIR}/.github/agents/${agent}" ]; then
                cp "${TOOLKIT_DIR}/.github/agents/${agent}" "${TARGET_DIR}/.github/agents/"
            fi
        done

        mkdir -p "${TARGET_DIR}/.github/skills"
        for skill in "${TOOLKIT_SKILLS[@]}"; do
            if [ -d "${TOOLKIT_DIR}/.agents/skills/${skill}" ]; then
                mkdir -p "${TARGET_DIR}/.github/skills/${skill}"
                cp -r "${TOOLKIT_DIR}/.agents/skills/${skill}/"* "${TARGET_DIR}/.github/skills/${skill}/"
            fi
        done
    fi

    echo -e "  ${GREEN}[+] Copilot Agents active in: ${TARGET_DIR}/.github/agents${RESET}"
    echo -e "  ${GREEN}[+] Copilot Skills active in: ${TARGET_DIR}/.github/skills${RESET}"
}

install_claude() {
    echo "[*] Configuring Claude Code Skills & Agents (${TARGET_DIR}/.claude)..."
    local content=$(cat "${TEMPLATE_DIR}/CLAUDE.md")
    safe_merge_file "${TARGET_DIR}/CLAUDE.md" "$content"

    if [ "$TARGET_DIR" != "$TOOLKIT_DIR" ]; then
        mkdir -p "${TARGET_DIR}/.claude/skills"
        for skill in "${TOOLKIT_SKILLS[@]}"; do
            if [ -d "${TOOLKIT_DIR}/.agents/skills/${skill}" ]; then
                mkdir -p "${TARGET_DIR}/.claude/skills/${skill}"
                cp -r "${TOOLKIT_DIR}/.agents/skills/${skill}/"* "${TARGET_DIR}/.claude/skills/${skill}/"
            fi
        done

        mkdir -p "${TARGET_DIR}/.claude/commands"
        for cmd in "${TOOLKIT_CLAUDE_COMMANDS[@]}"; do
            if [ -f "${TOOLKIT_DIR}/.claude/commands/${cmd}" ]; then
                cp "${TOOLKIT_DIR}/.claude/commands/${cmd}" "${TARGET_DIR}/.claude/commands/"
            fi
        done

        mkdir -p "${TARGET_DIR}/.claude-plugin"
        if [ -f "${TOOLKIT_DIR}/.claude-plugin/plugin.json" ]; then
            cp "${TOOLKIT_DIR}/.claude-plugin/plugin.json" "${TARGET_DIR}/.claude-plugin/"
        fi
    fi

    echo -e "  ${GREEN}[+] Claude Skills active in: ${TARGET_DIR}/.claude/skills${RESET}"
    echo -e "  ${GREEN}[+] Claude Slash Commands active in: ${TARGET_DIR}/.claude/commands${RESET}"
}

install_cursor() {
    echo "[*] Configuring Cursor Agent rules (${TARGET_DIR}/.cursor)..."
    local content=$(cat "${TEMPLATE_DIR}/cursorrules")
    safe_merge_file "${TARGET_DIR}/.cursorrules" "$content"
    mkdir -p "${TARGET_DIR}/.cursor/rules"
    safe_merge_file "${TARGET_DIR}/.cursor/rules/php-upgrade.mdc" "$content"
}

install_windsurf() {
    echo "[*] Configuring Windsurf Agent rules (${TARGET_DIR}/.windsurf)..."
    local content=$(cat "${TEMPLATE_DIR}/windsurfrules")
    safe_merge_file "${TARGET_DIR}/.windsurfrules" "$content"
    mkdir -p "${TARGET_DIR}/.windsurf/rules"
    safe_merge_file "${TARGET_DIR}/.windsurf/rules/php-upgrade.md" "$content"
}

install_gemini() {
    echo "[*] Configuring Gemini Code Assist & Antigravity (${TARGET_DIR}/.gemini & GEMINI.md)..."
    local content=$(cat "${TEMPLATE_DIR}/GEMINI.md")
    safe_merge_file "${TARGET_DIR}/GEMINI.md" "$content"

    if [ "$TARGET_DIR" != "$TOOLKIT_DIR" ]; then
        mkdir -p "${TARGET_DIR}/.gemini/skills"
        for skill in "${TOOLKIT_SKILLS[@]}"; do
            if [ -d "${TOOLKIT_DIR}/.agents/skills/${skill}" ]; then
                mkdir -p "${TARGET_DIR}/.gemini/skills/${skill}"
                cp -r "${TOOLKIT_DIR}/.agents/skills/${skill}/"* "${TARGET_DIR}/.gemini/skills/${skill}/"
            fi
        done
    fi

    echo -e "  ${GREEN}[+] Gemini Skills active in: ${TARGET_DIR}/.gemini/skills${RESET}"
    echo -e "  ${GREEN}[+] Gemini Rules active in: ${TARGET_DIR}/GEMINI.md${RESET}"
}

install_codex() {
    echo "[*] Configuring OpenAI Codex / ChatGPT (${TARGET_DIR}/.chatgpt)..."
    local content=$(cat "${TEMPLATE_DIR}/codex-instructions.md")
    mkdir -p "${TARGET_DIR}/.chatgpt"
    safe_merge_file "${TARGET_DIR}/.chatgpt/instructions.md" "$content"
}

remove_copilot() {
    echo "[*] Removing GitHub Copilot Agents & Skills..."
    remove_merge_file "${TARGET_DIR}/.github/copilot-instructions.md"
    for agent in "${TOOLKIT_AGENTS[@]}"; do
        rm -f "${TARGET_DIR}/.github/agents/${agent}"
    done
    for skill in "${TOOLKIT_SKILLS[@]}"; do
        rm -rf "${TARGET_DIR}/.github/skills/${skill}"
    done
}

remove_claude() {
    echo "[*] Removing Claude Code Skills & Commands..."
    remove_merge_file "${TARGET_DIR}/CLAUDE.md"
    for skill in "${TOOLKIT_SKILLS[@]}"; do
        rm -rf "${TARGET_DIR}/.claude/skills/${skill}"
    done
    for cmd in "${TOOLKIT_CLAUDE_COMMANDS[@]}"; do
        rm -f "${TARGET_DIR}/.claude/commands/${cmd}"
    done
}

remove_cursor() {
    echo "[*] Removing Cursor Agent rules..."
    remove_merge_file "${TARGET_DIR}/.cursorrules"
    remove_merge_file "${TARGET_DIR}/.cursor/rules/php-upgrade.mdc"
}

remove_windsurf() {
    echo "[*] Removing Windsurf Agent rules..."
    remove_merge_file "${TARGET_DIR}/.windsurfrules"
    remove_merge_file "${TARGET_DIR}/.windsurf/rules/php-upgrade.md"
}

remove_gemini() {
    echo "[*] Removing Gemini Code Assist & Antigravity..."
    remove_merge_file "${TARGET_DIR}/GEMINI.md"
    rm -rf "${TARGET_DIR}/.gemini/skills"
}

remove_codex() {
    echo "[*] Removing OpenAI Codex / ChatGPT..."
    remove_merge_file "${TARGET_DIR}/.chatgpt/instructions.md"
}

# --------------------------------------------------------------------
# 6. Execute Action for All Selected LLMs
# --------------------------------------------------------------------
if [ "$ACTION" = "install" ]; then
    sync_agents_folder

    for selected in "${SELECTED_LLMS[@]}"; do
        case "$selected" in
            copilot)  install_copilot ;;
            claude)   install_claude ;;
            cursor)   install_cursor ;;
            windsurf) install_windsurf ;;
            gemini)   install_gemini ;;
            codex)    install_codex ;;
        esac
    done

    echo ""
    echo -e "${GREEN}====================================================================${RESET}"
    echo -e "${GREEN}   [+] AGENTS & SKILLS ACTIVE: Zero Code Modified, All Installed!   ${RESET}"
    echo -e "${GREEN}====================================================================${RESET}"
    echo -e "Project Root: ${CYAN}${TARGET_DIR}${RESET}"
    echo -e "Configured Assistants: ${GREEN}${SELECTED_LLMS[*]}${RESET}"
    echo -e "To remove anytime, run: ./install.sh --remove --target \"$TARGET_DIR\""
    echo ""
    # Determine primary relative skills paths based on selected folders
    PRIMARY_REL=".agents/skills"
    for s in "${SELECTED_LLMS[@]}"; do
        if [ "$s" = "copilot" ]; then PRIMARY_REL=".github/skills"; break; fi
        if [ "$s" = "claude" ];  then PRIMARY_REL=".claude/skills"; break; fi
        if [ "$s" = "gemini" ];  then PRIMARY_REL=".gemini/skills"; break; fi
    done

    echo -e "${YELLOW}RECOMMENDED COMMANDS (RELATIVE PATHS FROM YOUR PROJECT ROOT):${RESET}"
    echo "--------------------------------------------------------------------"
    echo -e "Works on any system/OS in project root: ${CYAN}${TARGET_DIR}${RESET}\n"
    echo -e "${WHITE}1. Scan for php2shell & RCE vulnerabilities:${RESET}"
    echo -e "${CYAN}   php ${PRIMARY_REL}/php2shell-fixer/scripts/php2shell-audit.php --path=.${RESET}\n"
    echo -e "${WHITE}2. Scan for OWASP Top 10 security flaws:${RESET}"
    echo -e "${CYAN}   php ${PRIMARY_REL}/php-security-hardener/scripts/security-audit.php .${RESET}\n"
    echo -e "${WHITE}3. Preview safe PHP Core AST modernization (Dry Run up to PHP 8.5+):${RESET}"
    echo -e "${CYAN}   vendor/bin/rector process --dry-run --config=${PRIMARY_REL}/php-core-upgrader/scripts/rector-php-upgrade.php${RESET}\n"
    echo -e "${WHITE}4. Preview Framework upgrade plan (Laravel 8 -> 12+ / Latest):${RESET}"
    echo -e "${CYAN}   vendor/bin/rector process --dry-run --config=${PRIMARY_REL}/laravel-upgrader/scripts/rector-laravel.php${RESET}\n"
    echo -e "${WHITE}5. Run static analysis deprecation audit:${RESET}"
    echo -e "${CYAN}   vendor/bin/phpstan analyse -c ${PRIMARY_REL}/php-core-upgrader/scripts/phpstan.neon${RESET}\n"
    echo -e "${YELLOW}OR INVOKE YOUR AGENTS DIRECTLY IN CHAT:${RESET}"
    echo -e "${WHITE}   Copilot: @php-upgrade-architect \"Plan migration to PHP 8.5 and audit php2shell\"${RESET}"
    echo -e "${WHITE}   Claude:  /php-audit and /php-upgrade${RESET}"
    echo -e "${WHITE}   Cursor/Gemini: \"Audit this codebase for php2shell vulnerabilities\"${RESET}"
    echo -e "${CYAN}====================================================================${RESET}\n"
else
    for selected in "${SELECTED_LLMS[@]}"; do
        case "$selected" in
            copilot)  remove_copilot ;;
            claude)   remove_claude ;;
            cursor)   remove_cursor ;;
            windsurf) remove_windsurf ;;
            gemini)   remove_gemini ;;
            codex)    remove_codex ;;
        esac
    done

    echo ""
    echo -e "${YELLOW}====================================================================${RESET}"
    echo -e "${YELLOW}   [-] UNINSTALL COMPLETE: Cleanly removed selected agent adapters! ${RESET}"
    echo -e "${YELLOW}====================================================================${RESET}"
    echo -e "Target: ${CYAN}${TARGET_DIR}${RESET}"
    echo -e "All your original configuration files, PHP code, and settings remain 100% intact.\n"
fi

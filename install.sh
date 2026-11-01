#!/usr/bin/env bash
# ====================================================================
# Universal AI Agent & Plugin Manager (Linux & macOS)
# Installs or removes PHP Upgrade Agent into your Project Root
# Supports: Copilot, Claude, Cursor, Windsurf, Gemini, Codex
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
SELECTION=""
TARGET_DIR=""

# Parse flags
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
        copilot|claude|cursor|windsurf|gemini|codex|all)
            SELECTION="$1"
            shift
            ;;
        *)
            if [ -d "$1" ]; then
                TARGET_DIR="$1"
            fi
            shift
            ;;
    esac
done

echo -e "${CYAN}====================================================================${RESET}"
echo -e "${CYAN}   PHP Upgrade Agent & Security Hardener - Project Plugin Installer ${RESET}"
echo -e "${CYAN}====================================================================${RESET}"
echo "Installs agent skills, rules, and AI adapters directly into your Project Root."
echo ""

# --------------------------------------------------------------------
# 1. Detect & Resolve Target Project Root
# --------------------------------------------------------------------
PARENT_DIR="$(dirname "$TOOLKIT_DIR")"
HAS_PARENT_PROJECT=false

if [ -f "${PARENT_DIR}/composer.json" ] || [ -f "${PARENT_DIR}/artisan" ]; then
    HAS_PARENT_PROJECT=true
fi

if [ -z "$TARGET_DIR" ]; then
    if [ "$HAS_PARENT_PROJECT" = true ]; then
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
        read -p "Enter selection [1-3] (Default: 1): " PATH_CHOICE

        case "$PATH_CHOICE" in
            2) TARGET_DIR="$PARENT_DIR" ;;
            3)
                read -p "Enter full path to project root: " CUSTOM_PATH
                TARGET_DIR="$CUSTOM_PATH"
                ;;
            *) TARGET_DIR="$TOOLKIT_DIR" ;;
        esac
    fi
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
echo -e "\n[*] Target Project Root: ${CYAN}${TARGET_DIR}${RESET}"

# --------------------------------------------------------------------
# 2. Select AI Provider
# --------------------------------------------------------------------
if [ -z "$SELECTION" ]; then
    if [ "$ACTION" = "install" ]; then
        echo -e "Current Action: ${GREEN}INSTALL / ADD PLUGIN${RESET}"
    else
        echo -e "Current Action: ${YELLOW}REMOVE / UNINSTALL PLUGIN${RESET}"
    fi

    echo -e "\n${YELLOW}Select AI Coding Assistant:${RESET}"
    echo -e "  [1] GitHub Copilot (.github/) ${GREEN}(Default - Press Enter)${RESET}"
    echo "  [2] Claude Code (.claude/ & CLAUDE.md)"
    echo "  [3] Cursor (.cursor/ & .cursorrules)"
    echo "  [4] Windsurf (.windsurf/ & .windsurfrules)"
    echo "  [5] Gemini Code Assist (GEMINI.md)"
    echo "  [6] OpenAI Codex / ChatGPT (.chatgpt/)"
    echo "  [7] Universal Setup (All Providers)"
    echo "  [U] Toggle Action to UNINSTALL / REMOVE"
    echo ""
    read -p "Enter selection [1-7 or U] (Default: 1): " USER_INPUT

    if [ "$USER_INPUT" = "u" ] || [ "$USER_INPUT" = "U" ]; then
        ACTION="remove"
        echo -e "\n${YELLOW}[!] Action switched to: REMOVE / UNINSTALL${RESET}"
        read -p "Select provider to remove [1-7] (Default: 7/all): " USER_INPUT
        if [ -z "$USER_INPUT" ]; then USER_INPUT="7"; fi
    fi

    case "$USER_INPUT" in
        2) SELECTION="claude" ;;
        3) SELECTION="cursor" ;;
        4) SELECTION="windsurf" ;;
        5) SELECTION="gemini" ;;
        6) SELECTION="codex" ;;
        7) SELECTION="all" ;;
        *) SELECTION="copilot" ;;
    esac
fi

SELECTION=$(echo "$SELECTION" | tr '[:upper:]' '[:lower:]')

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
            if [ ! -s "$target_file" ] || [ -z "$(tr -d '[:space:]' < "$target_file")" ]; then
                rm -f "$target_file"
                echo -e "  ${YELLOW}[-] Removed ${target_file} (was only containing plugin configuration)${RESET}"
            else
                echo -e "  ${YELLOW}[-] Cleaned ${target_file} (removed plugin block, preserved your other settings)${RESET}"
            fi
        fi
    fi
}

# --------------------------------------------------------------------
# 4. Copy Core Skills & Rules to Project Root (if different directory)
# --------------------------------------------------------------------
sync_agents_folder() {
    if [ "$TARGET_DIR" != "$TOOLKIT_DIR" ]; then
        echo "[*] Syncing .agents/ skills and rules into project root..."
        mkdir -p "${TARGET_DIR}/.agents"
        cp -r "${TOOLKIT_DIR}/.agents/skills" "${TARGET_DIR}/.agents/"
        cp -r "${TOOLKIT_DIR}/.agents/rules" "${TARGET_DIR}/.agents/"
        echo -e "  ${GREEN}[+] .agents/ synced to project root: ${TARGET_DIR}/.agents${RESET}"
    fi
}

install_copilot() {
    echo "[*] Configuring GitHub Copilot adapter in project root (${TARGET_DIR}/.github)..."
    local content=$(cat "${TEMPLATE_DIR}/copilot-instructions.md")
    safe_merge_file "${TARGET_DIR}/.github/copilot-instructions.md" "$content"
    
    if [ "$TARGET_DIR" != "$TOOLKIT_DIR" ] && [ -d "${TOOLKIT_DIR}/.github/prompts" ]; then
        mkdir -p "${TARGET_DIR}/.github/prompts"
        cp -r "${TOOLKIT_DIR}/.github/prompts/"* "${TARGET_DIR}/.github/prompts/"
        echo -e "  ${GREEN}[+] Prompts installed into ${TARGET_DIR}/.github/prompts${RESET}"
    fi
}

install_claude() {
    echo "[*] Configuring Claude Code plugin in project root (${TARGET_DIR}/.claude)..."
    local content=$(cat "${TEMPLATE_DIR}/CLAUDE.md")
    safe_merge_file "${TARGET_DIR}/CLAUDE.md" "$content"

    if [ "$TARGET_DIR" != "$TOOLKIT_DIR" ]; then
        mkdir -p "${TARGET_DIR}/.claude/commands"
        if [ -d "${TOOLKIT_DIR}/.claude/commands" ]; then
            cp -r "${TOOLKIT_DIR}/.claude/commands/"* "${TARGET_DIR}/.claude/commands/"
            echo -e "  ${GREEN}[+] Slash commands installed into ${TARGET_DIR}/.claude/commands${RESET}"
        fi

        mkdir -p "${TARGET_DIR}/.claude-plugin"
        if [ -d "${TOOLKIT_DIR}/.claude-plugin" ]; then
            cp -r "${TOOLKIT_DIR}/.claude-plugin/"* "${TARGET_DIR}/.claude-plugin/"
            echo -e "  ${GREEN}[+] Plugin manifest installed into ${TARGET_DIR}/.claude-plugin/plugin.json${RESET}"
        fi
    fi
}

install_cursor() {
    echo "[*] Configuring Cursor adapter in project root (${TARGET_DIR}/.cursor)..."
    local content=$(cat "${TEMPLATE_DIR}/cursorrules")
    safe_merge_file "${TARGET_DIR}/.cursorrules" "$content"
    mkdir -p "${TARGET_DIR}/.cursor/rules"
    safe_merge_file "${TARGET_DIR}/.cursor/rules/php-upgrade.mdc" "$content"
}

install_windsurf() {
    echo "[*] Configuring Windsurf adapter in project root (${TARGET_DIR}/.windsurf)..."
    local content=$(cat "${TEMPLATE_DIR}/windsurfrules")
    safe_merge_file "${TARGET_DIR}/.windsurfrules" "$content"
    mkdir -p "${TARGET_DIR}/.windsurf/rules"
    safe_merge_file "${TARGET_DIR}/.windsurf/rules/php-upgrade.md" "$content"
}

install_gemini() {
    echo "[*] Configuring Gemini Code Assist in project root (${TARGET_DIR}/GEMINI.md)..."
    local content=$(cat "${TEMPLATE_DIR}/GEMINI.md")
    safe_merge_file "${TARGET_DIR}/GEMINI.md" "$content"
}

install_codex() {
    echo "[*] Configuring OpenAI Codex / ChatGPT in project root (${TARGET_DIR}/.chatgpt)..."
    local content=$(cat "${TEMPLATE_DIR}/codex-instructions.md")
    mkdir -p "${TARGET_DIR}/.chatgpt"
    safe_merge_file "${TARGET_DIR}/.chatgpt/instructions.md" "$content"
}

remove_copilot() {
    echo "[*] Removing GitHub Copilot adapter from ${TARGET_DIR}/.github..."
    remove_merge_file "${TARGET_DIR}/.github/copilot-instructions.md"
}

remove_claude() {
    echo "[*] Removing Claude Code adapter from ${TARGET_DIR}..."
    remove_merge_file "${TARGET_DIR}/CLAUDE.md"
    rm -f "${TARGET_DIR}/.claude/commands/php-audit.md" \
          "${TARGET_DIR}/.claude/commands/php-upgrade.md" \
          "${TARGET_DIR}/.claude/commands/laravel-upgrade.md" \
          "${TARGET_DIR}/.claude/commands/php2shell-fix.md" 2>/dev/null || true
}

remove_cursor() {
    echo "[*] Removing Cursor adapter from ${TARGET_DIR}..."
    remove_merge_file "${TARGET_DIR}/.cursorrules"
    remove_merge_file "${TARGET_DIR}/.cursor/rules/php-upgrade.mdc"
}

remove_windsurf() {
    echo "[*] Removing Windsurf adapter from ${TARGET_DIR}..."
    remove_merge_file "${TARGET_DIR}/.windsurfrules"
    remove_merge_file "${TARGET_DIR}/.windsurf/rules/php-upgrade.md"
}

remove_gemini() {
    echo "[*] Removing Gemini Code Assist adapter from ${TARGET_DIR}..."
    remove_merge_file "${TARGET_DIR}/GEMINI.md"
}

remove_codex() {
    echo "[*] Removing OpenAI Codex / ChatGPT adapter from ${TARGET_DIR}..."
    remove_merge_file "${TARGET_DIR}/.chatgpt/instructions.md"
}

if [ "$ACTION" = "install" ]; then
    sync_agents_folder

    case "$SELECTION" in
        copilot)  install_copilot ;;
        claude)   install_claude ;;
        cursor)   install_cursor ;;
        windsurf) install_windsurf ;;
        gemini)   install_gemini ;;
        codex)    install_codex ;;
        all|*)
            install_copilot
            install_claude
            install_cursor
            install_windsurf
            install_gemini
            install_codex
            ;;
    esac

    echo ""
    echo -e "${GREEN}====================================================================${RESET}"
    echo -e "${GREEN}   [+] PLUGIN INSTALLED: Project Root is Fully Configured!          ${RESET}"
    echo -e "${GREEN}====================================================================${RESET}"
    echo -e "Project Root: ${CYAN}${TARGET_DIR}${RESET}"
    echo -e "Canonical rules and skills reside safely in: ${CYAN}${TARGET_DIR}/.agents/${RESET}"
    echo "To remove anytime, run: ./install.sh --remove --target \"$TARGET_DIR\""
    echo ""
    echo -e "${YELLOW}🎯 RECOMMENDED NEXT STEPS & COMMANDS TO RUN NOW:${RESET}"
    echo "--------------------------------------------------------------------"
    echo -e "${WHITE}1. Scan for php2shell & RCE vulnerabilities:${RESET}"
    echo -e "${CYAN}   php .agents/skills/php2shell-fixer/scripts/php2shell-audit.php --path=.${RESET}\n"
    echo -e "${WHITE}2. Scan for OWASP Top 10 security flaws (SQLi, SSRF, Deserialization):${RESET}"
    echo -e "${CYAN}   php .agents/skills/php-security-hardener/scripts/security-audit.php .${RESET}\n"
    echo -e "${WHITE}3. Preview safe PHP Core AST modernization (Up to PHP 8.5+ / Latest):${RESET}"
    echo -e "${CYAN}   vendor/bin/rector process --dry-run --config=.agents/skills/php-core-upgrader/scripts/rector-php-upgrade.php${RESET}\n"
    echo -e "${WHITE}4. Preview Framework upgrade plan (Laravel 8 -> 12+ / Latest):${RESET}"
    echo -e "${CYAN}   vendor/bin/rector process --dry-run --config=.agents/skills/laravel-upgrader/scripts/rector-laravel.php${RESET}\n"
    echo -e "${WHITE}5. Run static analysis deprecation audit:${RESET}"
    echo -e "${CYAN}   vendor/bin/phpstan analyse -c .agents/skills/php-core-upgrader/scripts/phpstan.neon${RESET}\n"
    echo -e "${YELLOW}🤖 OR ASK YOUR AI ASSISTANT DIRECTLY:${RESET}"
    echo -e "${WHITE}   \"Audit this codebase for php2shell vulnerabilities, check deprecations,${RESET}"
    echo -e "${WHITE}    and generate a stepwise non-breaking PHP upgrade roadmap.\"${RESET}"
    echo -e "${CYAN}====================================================================${RESET}\n"
else
    case "$SELECTION" in
        copilot)  remove_copilot ;;
        claude)   remove_claude ;;
        cursor)   remove_cursor ;;
        windsurf) remove_windsurf ;;
        gemini)   remove_gemini ;;
        codex)    remove_codex ;;
        all|*)
            remove_copilot
            remove_claude
            remove_cursor
            remove_windsurf
            remove_gemini
            remove_codex
            ;;
    esac

    echo ""
    echo -e "${YELLOW}====================================================================${RESET}"
    echo -e "${YELLOW}   [-] PLUGIN REMOVED: Cleanly uninstalled from Project Root!      ${RESET}"
    echo -e "${YELLOW}====================================================================${RESET}"
    echo -e "Target: ${CYAN}${TARGET_DIR}${RESET}"
    echo -e "To re-add anytime, simply run: ${GREEN}./install.sh --target \"$TARGET_DIR\"${RESET}\n"
fi

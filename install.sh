#!/usr/bin/env bash
# ====================================================================
# Universal AI Agent & Plugin Manager (Linux & macOS)
# Adds or removes PHP Upgrade Agent for Copilot, Claude, Cursor, Windsurf, Gemini, Codex
# ====================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${SCRIPT_DIR}/.agents/templates"

CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RESET='\033[0m'

ACTION="install"
SELECTION=""

# Parse flags
for arg in "$@"; do
    case "$arg" in
        --remove|--uninstall|remove|uninstall)
            ACTION="remove"
            ;;
        copilot|claude|cursor|windsurf|gemini|codex|all)
            SELECTION="$arg"
            ;;
    esac
done

echo -e "${CYAN}====================================================================${RESET}"
echo -e "${CYAN}   PHP Upgrade Agent and Security Hardener - Plugin Manager         ${RESET}"
echo -e "${CYAN}====================================================================${RESET}"
echo "Easily add or remove AI plugins, skills, and modernization adapters."
echo ""

if [ -z "$SELECTION" ]; then
    if [ "$ACTION" = "install" ]; then
        echo -e "Current Action: ${GREEN}INSTALL / ADD PLUGIN${RESET}"
    else
        echo -e "Current Action: ${YELLOW}REMOVE / UNINSTALL PLUGIN${RESET}"
    fi

    echo -e "\n${YELLOW}Select AI Coding Assistant:${RESET}"
    echo -e "  [1] GitHub Copilot ${GREEN}(Default - Press Enter)${RESET}"
    echo "  [2] Claude Code (Plugin & Slash Commands)"
    echo "  [3] Cursor"
    echo "  [4] Windsurf"
    echo "  [5] Gemini Code Assist / Antigravity"
    echo "  [6] OpenAI Codex / ChatGPT Dev Tools"
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
# Safe Content Merger & Cleaner
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

install_copilot() {
    echo "[*] Adding GitHub Copilot plugin adapter..."
    local content=$(cat "${TEMPLATE_DIR}/copilot-instructions.md")
    safe_merge_file "${SCRIPT_DIR}/.github/copilot-instructions.md" "$content"
    mkdir -p "${SCRIPT_DIR}/.github/prompts"
}

install_claude() {
    echo "[*] Adding Claude Code plugin & slash commands..."
    local content=$(cat "${TEMPLATE_DIR}/CLAUDE.md")
    safe_merge_file "${SCRIPT_DIR}/CLAUDE.md" "$content"
    echo -e "  ${GREEN}[+] Claude Code plugin manifest active in .claude-plugin/plugin.json${RESET}"
    echo -e "  ${GREEN}[+] Slash commands active: /php-audit, /php-upgrade, /laravel-upgrade, /php2shell-fix${RESET}"
}

install_cursor() {
    echo "[*] Adding Cursor plugin adapter..."
    local content=$(cat "${TEMPLATE_DIR}/cursorrules")
    safe_merge_file "${SCRIPT_DIR}/.cursorrules" "$content"
    mkdir -p "${SCRIPT_DIR}/.cursor/rules"
    safe_merge_file "${SCRIPT_DIR}/.cursor/rules/php-upgrade.mdc" "$content"
}

install_windsurf() {
    echo "[*] Adding Windsurf plugin adapter..."
    local content=$(cat "${TEMPLATE_DIR}/windsurfrules")
    safe_merge_file "${SCRIPT_DIR}/.windsurfrules" "$content"
    mkdir -p "${SCRIPT_DIR}/.windsurf/rules"
    safe_merge_file "${SCRIPT_DIR}/.windsurf/rules/php-upgrade.md" "$content"
}

install_gemini() {
    echo "[*] Adding Gemini Code Assist / Antigravity plugin adapter..."
    local content=$(cat "${TEMPLATE_DIR}/GEMINI.md")
    safe_merge_file "${SCRIPT_DIR}/GEMINI.md" "$content"
}

install_codex() {
    echo "[*] Adding OpenAI Codex / ChatGPT plugin adapter..."
    local content=$(cat "${TEMPLATE_DIR}/codex-instructions.md")
    mkdir -p "${SCRIPT_DIR}/.chatgpt"
    safe_merge_file "${SCRIPT_DIR}/.chatgpt/instructions.md" "$content"
}

remove_copilot() {
    echo "[*] Removing GitHub Copilot adapter..."
    remove_merge_file "${SCRIPT_DIR}/.github/copilot-instructions.md"
}

remove_claude() {
    echo "[*] Removing Claude Code adapter..."
    remove_merge_file "${SCRIPT_DIR}/CLAUDE.md"
}

remove_cursor() {
    echo "[*] Removing Cursor adapter..."
    remove_merge_file "${SCRIPT_DIR}/.cursorrules"
    remove_merge_file "${SCRIPT_DIR}/.cursor/rules/php-upgrade.mdc"
}

remove_windsurf() {
    echo "[*] Removing Windsurf adapter..."
    remove_merge_file "${SCRIPT_DIR}/.windsurfrules"
    remove_merge_file "${SCRIPT_DIR}/.windsurf/rules/php-upgrade.md"
}

remove_gemini() {
    echo "[*] Removing Gemini Code Assist adapter..."
    remove_merge_file "${SCRIPT_DIR}/GEMINI.md"
}

remove_codex() {
    echo "[*] Removing OpenAI Codex / ChatGPT adapter..."
    remove_merge_file "${SCRIPT_DIR}/.chatgpt/instructions.md"
}

if [ "$ACTION" = "install" ]; then
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
    echo -e "${GREEN}   [+] PLUGIN INSTALLED: All Skills and Adapters Are Active!       ${RESET}"
    echo -e "${GREEN}====================================================================${RESET}"
    echo "Canonical rules and skills reside safely in: .agents/"
    echo "To remove anytime, run: ./install.sh --remove"
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
    echo -e "${YELLOW}   [-] PLUGIN REMOVED: Cleanly uninstalled selected adapters!      ${RESET}"
    echo -e "${YELLOW}====================================================================${RESET}"
    echo -e "To re-add anytime, simply run: ${GREEN}./install.sh${RESET}\n"
fi

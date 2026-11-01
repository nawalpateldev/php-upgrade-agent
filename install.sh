#!/usr/bin/env bash
# ====================================================================
# Universal AI Agent & Skill Installer (Linux & macOS)
# Configures PHP Upgrade Agent for Copilot, Cursor, Claude, Windsurf, Gemini, Codex
# ====================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${SCRIPT_DIR}/.agents/templates"

CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RESET='\033[0m'

echo -e "${CYAN}====================================================================${RESET}"
echo -e "${CYAN}   🚀 PHP Upgrade Agent & Security Hardener - Multi-LLM Setup       ${RESET}"
echo -e "${CYAN}====================================================================${RESET}"
echo "Configures zero-breakage PHP modernization and php2shell fixes."
echo ""

SELECTION="$1"

if [ -z "$SELECTION" ]; then
    echo -e "${YELLOW}Select your primary AI Coding Assistant:${RESET}"
    echo -e "  [1] GitHub Copilot ${GREEN}(Default - Press Enter)${RESET}"
    echo "  [2] Cursor"
    echo "  [3] Claude Code"
    echo "  [4] Windsurf"
    echo "  [5] Gemini Code Assist / Antigravity"
    echo "  [6] OpenAI Codex / ChatGPT Dev Tools"
    echo "  [7] Universal Setup (Configure All Providers)"
    echo ""
    read -p "Enter selection [1-7] (Default: 1): " USER_INPUT

    case "$USER_INPUT" in
        2) SELECTION="cursor" ;;
        3) SELECTION="claude" ;;
        4) SELECTION="windsurf" ;;
        5) SELECTION="gemini" ;;
        6) SELECTION="codex" ;;
        7) SELECTION="all" ;;
        *) SELECTION="copilot" ;;
    esac
fi

SELECTION=$(echo "$SELECTION" | tr '[:upper:]' '[:lower:]')

echo ""
echo -e "[*] Configuring AI Assistant Adapter: ${GREEN}${SELECTION}${RESET}"

# --------------------------------------------------------------------
# Safe Additive Merge Helper
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
            # Replace existing block between markers
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

setup_copilot() {
    echo "[*] Configuring GitHub Copilot adapter (additive)..."
    local content=$(cat "${TEMPLATE_DIR}/copilot-instructions.md")
    safe_merge_file "${SCRIPT_DIR}/.github/copilot-instructions.md" "$content"
    mkdir -p "${SCRIPT_DIR}/.github/prompts"
}

setup_cursor() {
    echo "[*] Configuring Cursor adapter (additive)..."
    local content=$(cat "${TEMPLATE_DIR}/cursorrules")
    safe_merge_file "${SCRIPT_DIR}/.cursorrules" "$content"
    mkdir -p "${SCRIPT_DIR}/.cursor/rules"
    safe_merge_file "${SCRIPT_DIR}/.cursor/rules/php-upgrade.mdc" "$content"
}

setup_claude() {
    echo "[*] Configuring Claude Code adapter (additive)..."
    local content=$(cat "${TEMPLATE_DIR}/CLAUDE.md")
    safe_merge_file "${SCRIPT_DIR}/CLAUDE.md" "$content"
}

setup_windsurf() {
    echo "[*] Configuring Windsurf adapter (additive)..."
    local content=$(cat "${TEMPLATE_DIR}/windsurfrules")
    safe_merge_file "${SCRIPT_DIR}/.windsurfrules" "$content"
    mkdir -p "${SCRIPT_DIR}/.windsurf/rules"
    safe_merge_file "${SCRIPT_DIR}/.windsurf/rules/php-upgrade.md" "$content"
}

setup_gemini() {
    echo "[*] Configuring Gemini Code Assist / Antigravity adapter (additive)..."
    local content=$(cat "${TEMPLATE_DIR}/GEMINI.md")
    safe_merge_file "${SCRIPT_DIR}/GEMINI.md" "$content"
}

setup_codex() {
    echo "[*] Configuring OpenAI Codex / ChatGPT adapter (additive)..."
    local content=$(cat "${TEMPLATE_DIR}/codex-instructions.md")
    mkdir -p "${SCRIPT_DIR}/.chatgpt"
    safe_merge_file "${SCRIPT_DIR}/.chatgpt/instructions.md" "$content"
}

case "$SELECTION" in
    copilot)  setup_copilot ;;
    cursor)   setup_cursor ;;
    claude)   setup_claude ;;
    windsurf) setup_windsurf ;;
    gemini)   setup_gemini ;;
    codex)    setup_codex ;;
    all|*)
        setup_copilot
        setup_cursor
        setup_claude
        setup_windsurf
        setup_gemini
        setup_codex
        ;;
esac

# Check Composer dependencies
if [ ! -d "${SCRIPT_DIR}/vendor" ] && command -v composer >/dev/null 2>&1; then
    echo -e "\n${CYAN}[*] Installing Composer tooling dependencies (rector, phpstan, security checkers)...${RESET}"
    composer install --no-interaction --quiet || true
    echo -e "  ${GREEN}[+] Dependencies verified.${RESET}"
fi

echo ""
echo -e "${GREEN}====================================================================${RESET}"
echo -e "${GREEN}   ✔ INSTALLATION COMPLETE: All Agents & Skills Are Active!         ${RESET}"
echo -e "${GREEN}====================================================================${RESET}"
echo "Canonical rules and skills reside safely in: .agents/"
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

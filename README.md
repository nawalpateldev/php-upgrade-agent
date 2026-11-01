<div align="center">

# 🚀 PHP Upgrade Agent & Security Hardener
### Automated Zero-Breakage PHP Upgrades, Framework Migrations & php2shell Security Fixes

[![PHP Version](https://img.shields.io/badge/PHP-8.2%20%7C%208.5%2B%20%7C%20Latest-blue.svg)](https://www.php.net/)
[![Laravel](https://img.shields.io/badge/Laravel-8%20%E2%86%92%2012%2B%20%7C%20Latest-red.svg)](https://laravel.com/)
[![Symfony](https://img.shields.io/badge/Symfony-4.4%2F5.4%20%E2%86%92%206.4%2F7.x-black.svg)](https://symfony.com/)
[![CodeIgniter](https://img.shields.io/badge/CodeIgniter-3%20%E2%86%92%204%2B-orange.svg)](https://codeigniter.com/)
[![Security](https://img.shields.io/badge/php2shell-Remediated-brightgreen.svg)](#-php2shell-fix-october-2026--rce-defense)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**The all-in-one AI-driven modernization toolkit to upgrade legacy PHP applications to PHP 8.5+ (including PHP 8.5.12 and upcoming latest versions) without breaking core business logic, migrate frameworks (Laravel 8 to 12+, Symfony 4/5 to 7, CodeIgniter 3 to 4), fix critical PHP vulnerabilities, and neutralize October 2026 php2shell RCE exploits.**

[Quick Start](#-quick-start--multi-llm-setup) • [PHP Core Upgrade](#-php-core-upgrade-56--85--latest) • [Framework Migrations](#-framework-upgrade-suite) • [php2shell Fix](#-php2shell-fix-october-2026--rce-defense) • [PHP Vulnerabilities Fix](#-php-vulnerabilities-fix-owasp-top-10) • [FAQ](#-frequently-asked-questions-seo-faq)

</div>

---

## 🔍 Why This Toolkit?

Upgrading legacy PHP or executing major framework leaps (like Laravel 8 to 12) often causes runtime breakages, fatal type errors, deprecation crashes, and security regressions. 

**PHP Upgrade Agent** solves this through **Deterministic AST Refactoring, Strict Static Analysis, and Defensive Security Engineering**:
* **Zero Core Logic Breakage**: Refactors code using Abstract Syntax Trees (AST) while preserving 100% behavioral parity.
* **Safe Stepwise Jumps**: Bridges major versions incrementally (`PHP 5.6 -> 7.4 -> 8.0 -> 8.2 -> 8.3 -> 8.4`).
* **Deep Framework Modernization**: Automates breaking changes across Laravel (Flysystem 3, Symfony Mailer, `bootstrap/app.php`), Symfony (Attributes, unified Authenticator), and CodeIgniter (PSR-4 namespacing).
* **Automated Security Fixes**: Native SAST scanners detect and remediate OWASP Top 10 flaws and Remote Code Execution (RCE).
* **Comprehensive php2shell Neutralization**: Complete defense-in-depth patch against CGI argument injection (CVE-2024-4577 & 2026 Unicode bypasses), stream filter chains (`php://filter`), and webshell drops.

---

## 🛡️ php2shell Fix (October 2026 & RCE Defense)

The **`php2shell-fixer`** skill provides automated detection and remediation for PHP-to-shell Remote Code Execution attack surfaces:

### 1. CGI Argument Injection (CVE-2024-4577 & 2026 Unicode Bypasses)
* **Threat**: Exploitation of Windows Best-Fit mapping and soft hyphens (`%ad%64`, `%u00ad`) passing command switches like `-d allow_url_include=1 -d auto_prepend_file=php://input` to `php-cgi`.
* **Fix Applied**: Perimeter Nginx and Apache rewrite rules blocking argument switches and Unicode bypasses, coupled with runtime argument normalization.

### 2. Stream Filter Chain RCE (`php://filter`)
* **Threat**: Maliciously crafted iconv sequence filters (`convert.iconv.*`) in dynamic `include`/`require` triggering memory manipulation and arbitrary shell creation.
* **Fix Applied**: AST-based static path whitelisting and setting `allow_url_include = Off` in [php-hardened.ini](.agents/skills/php2shell-fixer/scripts/php-hardened.ini).

### 3. Shell Execution Primitives Replacement
* **Threat**: Direct calls to `exec()`, `passthru()`, `shell_exec()`, `system()`, `proc_open()`, or backticks with unsanitized parameters.
* **Fix Applied**: Automated conversion to parameterized `Symfony\Component\Process\Process` commands with strict argument arrays and whitelisting.

### 4. Webshell Upload Hardening
* **Threat**: Direct upload of `.php`, `.phtml`, `.phar`, `.htaccess`, or `.user.ini` files.
* **Fix Applied**: Files stored outside webroot (`/var/app_storage/uploads`), randomized UUID naming, MIME & magic-byte verification with `finfo`, and server execution denial.

#### Run the php2shell Scanner:
```bash
# Native PHP scanner (instant execution):
php .agents/skills/php2shell-fixer/scripts/php2shell-audit.php --path=.

# Or Python SAST scanner:
python .agents/skills/php2shell-fixer/scripts/php2shell-audit.py --path=.
```

---

## 🔒 PHP Vulnerabilities Fix (OWASP Top 10)

The **`php-security-hardener`** skill provides automated identification and repair for common PHP security vulnerabilities:

| Vulnerability | Automated Fix Pattern | Skill Reference |
|---|---|---|
| **SQL Injection (SQLi)** | Parameterized PDO statements & strict ORM query bindings (no raw string interpolation) | [SQLi Remediation](.agents/skills/php-security-hardener/SKILL.md#step-2-sql-injection-remediation) |
| **Server-Side Request Forgery (SSRF)** | IP address validation blocking private/reserved ranges (`FILTER_FLAG_NO_PRIV_RANGE`, metadata `169.254.169.254`) | [SSRF Hardening](.agents/skills/php-security-hardener/SKILL.md#step-3-server-side-request-forgery-ssrf-hardening) |
| **Insecure Deserialization** | Replaces `unserialize()` with `json_decode()` or cryptographically signed HMAC payloads | [Deserialization Guide](.agents/skills/php2shell-fixer/references/oct-2026-php2shell-cves.md#3-deserialization-pop-gadgets-to-shell) |
| **Weak Cryptography** | Migrates legacy `md5()` / `sha1()` passwords to `PASSWORD_ARGON2ID` and pseudo-random numbers to `random_bytes()` | [Crypto Guide](.agents/skills/php-security-hardener/SKILL.md#step-4-cryptography--password-hashing) |
| **Vulnerable Dependencies** | Automated Composer advisory scanner via `composer audit` and `roave/security-advisories` | [Composer Audit](.agents/skills/php-security-hardener/SKILL.md#step-1-composer-dependency-audit) |

#### Run the Security Audit:
```bash
php .agents/skills/php-security-hardener/scripts/security-audit.php .
```

---

## ⚡ PHP Core Upgrade (5.6 → 8.5+ & Latest)

The **`php-core-upgrader`** skill handles all major breaking changes across modern PHP engines with dynamic target detection up to **PHP 8.5.12+ and upcoming releases**:

* **PHP 8.0**:
  * Undefined array key warnings converted to null-coalescing (`$arr['key'] ?? null`).
  * Non-strict string/number comparisons corrected.
* **PHP 8.1**:
  * Passing `null` to non-nullable internal functions sanitized (`strlen((string)$str)`).
  * Implements `#[\ReturnTypeWillChange]` on `Iterator`, `ArrayAccess`, and `JsonSerializable`.
* **PHP 8.2**:
  * Dynamic property deprecation mitigated with `#[\AllowDynamicProperties]` or typed properties.
  * `${var}` string interpolation upgraded to `{$var}`.
* **PHP 8.3 & 8.4**:
  * Typed class constants and dynamic class constant fetches.
  * Implicit nullable parameter types (`string $param = null`) refactored to explicit `?string $param = null`.
* **PHP 8.5+ & Latest**:
  * Dynamic properties escalate to fatal errors; safely bridged or typed.
  * Enforces `#[Override]` attributes to safeguard subclass methods against signature drift.
  * Dynamically aligns with host runtime version (`PHP_VERSION_ID`).

#### Run Rector AST PHP Upgrade:
```bash
# Preview changes safely (targets PHP 8.5+ / Latest)
vendor/bin/rector process --dry-run --config=.agents/skills/php-core-upgrader/scripts/rector-php-upgrade.php

# Apply changes
vendor/bin/rector process --config=.agents/skills/php-core-upgrader/scripts/rector-php-upgrade.php

# Validate with strict static analysis
vendor/bin/phpstan analyse -c .agents/skills/php-core-upgrader/scripts/phpstan.neon
```

---

## 📦 Framework Upgrade Suite

```
[Laravel 8.x]  ──►  [Laravel 9.x]  ──►  [Laravel 10.x] ──►  [Laravel 11.x] ──►  [Laravel 12.x+]
[Symfony 4.4]  ──►  [Symfony 5.4]  ──►  [Symfony 6.4 LTS] ──────────────────►  [Symfony 7.x]
[CodeIgniter 3.x Monolith] ──────────►  [CodeIgniter 4.x PSR-4 Namespaced]
```

### 1. Laravel 8 to Laravel 12+ & Latest ([Guide](.agents/skills/laravel-upgrader/SKILL.md))
- **Laravel 8 to 9**: Flysystem 1 -> 3 migration (`Storage::missing()`, `UnableToWriteFile`), SwiftMailer -> Symfony Mailer, anonymous migrations.
- **Laravel 9 to 10**: `$dates` array -> `$casts`, native return type declarations in userland classes.
- **Laravel 10 to 11**: Streamlined skeleton (`bootstrap/app.php`), kernel/route-provider consolidation, model `casts()` method.
- **Laravel 11 to 12+**: Concurrency API, strict attribute casts, modern package compatibility, dynamic set resolution.
```bash
vendor/bin/rector process --dry-run --config=.agents/skills/laravel-upgrader/scripts/rector-laravel.php
```

### 2. Symfony 4.4 / 5.4 to 6.4 & 7.x+ ([Guide](.agents/skills/symfony-upgrader/SKILL.md))
- Doctrine `@ORM` & routing `@Route` annotations converted to native PHP 8 attributes (`#[ORM\Column]`, `#[Route]`).
- Replaces legacy Guard authenticators (`GuardAuthenticatorInterface`) with the unified `AuthenticatorInterface` and `Passport` system.
```bash
vendor/bin/rector process --config=.agents/skills/symfony-upgrader/scripts/rector-symfony.php
```

### 3. CodeIgniter 3 to 4+ ([Guide](.agents/skills/codeigniter-upgrader/SKILL.md))
- Automated migration from CI3 global super-objects (`$this->load`, `$this->input`, `$this->db`) to CI4 PSR-4 namespaced architecture (`App\Controllers`, `App\Models`, `Services::request()`).
- Document root isolation to `public/index.php`.
```bash
php .agents/skills/codeigniter-upgrader/scripts/ci3-to-ci4-migrator.php --src=legacy_ci3/application --dest=modern_ci4/app
```

---

## 🤖 Autonomous Subagents

This repository integrates 3 Antigravity subagents ready to handle your workflows:

1. **`php-upgrade-architect`**: Orchestrates pre-flight audits, compatibility checks, Rector AST transformations, and static analysis pipelines.
2. **`framework-migrator`**: Specializes in major framework leaps (Laravel 8-12, Symfony 4-7, CodeIgniter 3-4).
3. **`php2shell-remediator`**: Specializes in RCE detection, php2shell neutralizing, and server runtime hardening.

---

## 🔌 Plugin & Multi-LLM Manager (Easy Add & Remove)

The toolkit is packaged as a **standardized AI Plugin and Agents Suite** compatible with **GitHub Copilot**, **Claude Code**, **Cursor**, **Windsurf**, **Gemini Code Assist**, and **OpenAI Codex**.

### 🛡️ Safety & Non-Destructive Invariants
1. **Zero Code Touch**: Never touches, alters, or refactors your PHP source files (`*.php`), application configs, or databases during installation.
2. **Zero Project File Deletion**: Never deletes any project files or directories.
3. **Additive & Demarcated**: In shared instruction files (e.g. `copilot-instructions.md`, `CLAUDE.md`, `.cursorrules`), all additions are safely isolated between `<!-- PHP-UPGRADE-AGENT-START -->` and `<!-- PHP-UPGRADE-AGENT-END -->`. All existing project instructions are 100% preserved.
4. **Native Agents & Skills**: Installs specialized subagents (`.github/agents/`) and native skills (`.github/skills/`, `.claude/skills/`, `.agents/skills/`), rather than basic prompt wrappers.

---

### 1. Clone the Repository
```bash
git clone git@github.com:nawalpateldev/php-upgrade-agent.git
cd php-upgrade-agent
```

### 2. Add / Install Plugin Adapters (Supports Multi-Select)

You can select **single or multiple assistants** simultaneously (e.g. `copilot,claude,gemini` or entering `1,2,5` in the interactive prompt):

#### On Windows (PowerShell or Command Prompt):
```powershell
# Interactive menu (Auto-detects project root; multi-select like 1,2,5):
.\install.ps1

# Multi-select installation into target project root:
.\install.ps1 install "copilot,claude,gemini" -TargetPath "..\my-php-project"

# Or install for a specific assistant:
.\install.ps1 install copilot     # GitHub Copilot (Default)
.\install.ps1 install claude      # Claude Code (Skills, Commands, Plugin)
.\install.ps1 install cursor      # Cursor AI
.\install.ps1 install windsurf    # Windsurf
.\install.ps1 install gemini      # Gemini Code Assist / Antigravity
.\install.ps1 install codex       # OpenAI Codex / ChatGPT Dev Tools
.\install.ps1 install all         # Universal Setup (All Providers)
```
*(You can also double-click `install.bat`)*

#### On Linux & macOS (Bash):
```bash
chmod +x install.sh

# Interactive menu (Multi-select like 1,2,5):
./install.sh

# Multi-select installation into target project root:
./install.sh "copilot,claude,gemini" --target "../my-php-project"

# Or install for a specific assistant:
./install.sh copilot      # GitHub Copilot (Default)
./install.sh claude       # Claude Code
./install.sh cursor       # Cursor AI
./install.sh windsurf     # Windsurf
./install.sh gemini       # Gemini Code Assist
./install.sh codex        # OpenAI Codex / ChatGPT
./install.sh all          # Universal Setup (All Providers)
```

---

### 3. Remove / Uninstall Plugin (Clean Teardown Anytime)

If you ever wish to remove the plugin adapters, run the uninstaller. It strips out the added directives while **preserving all your other custom settings**:

```powershell
# On Windows:
.\install.ps1 -Uninstall
# Or remove for a specific assistant:
.\install.ps1 remove claude
.\install.ps1 remove copilot
.\install.ps1 remove all

# On Linux & macOS:
./install.sh --remove
# Or remove for a specific assistant:
./install.sh remove claude
./install.sh remove copilot
./install.sh remove all
```

---

### 4. Claude Code Plugin & Slash Commands

When Claude Code is selected, the plugin manifest (`.claude-plugin/plugin.json`) enables built-in slash commands directly inside your Claude terminal:

* `/php-audit` — Scan codebase for October 2026 php2shell and OWASP vulnerabilities.
* `/php-upgrade` — Dry-run AST refactoring for PHP 8.5+ without breaking logic.
* `/laravel-upgrade` — Preview Laravel 8 -> 12+ framework migration plan.
* `/php2shell-fix` — Apply automated security patches for RCE vectors.

---

### 5. Immediate Recommended Commands After Installation

Once the installer finishes, it automatically outputs ready-to-run commands for your project:

```bash
# 1. Scan for php2shell & RCE vulnerabilities:
php .agents/skills/php2shell-fixer/scripts/php2shell-audit.php --path=.

# 2. Scan for OWASP Top 10 security flaws (SQLi, SSRF, Deserialization):
php .agents/skills/php-security-hardener/scripts/security-audit.php .

# 3. Preview safe PHP Core AST modernization (Up to PHP 8.4):
vendor/bin/rector process --dry-run --config=.agents/skills/php-core-upgrader/scripts/rector-php-upgrade.php

# 4. Preview Framework upgrade plan (Laravel 8 -> 12):
vendor/bin/rector process --dry-run --config=.agents/skills/laravel-upgrader/scripts/rector-laravel.php

# 5. Run static analysis deprecation audit:
vendor/bin/phpstan analyse -c .agents/skills/php-core-upgrader/scripts/phpstan.neon
```

# Check Composer security advisories
composer audit
```

### 4. Apply Safe PHP Upgrades (Dry Run)
```bash
vendor/bin/rector process --dry-run --config=.agents/skills/php-core-upgrader/scripts/rector-php-upgrade.php
```

---

## ❓ Frequently Asked Questions (SEO FAQ)

<details>
<summary><b>How do I upgrade PHP legacy without breaking core business logic?</b></summary>
Never jump across multiple major versions in one step. Use our <code>php-core-upgrader</code> to migrate step-by-step (e.g. 7.4 -> 8.0 -> 8.2 -> 8.4). Run baseline unit tests before refactoring, execute Rector AST rules, and enforce static analysis via PHPStan to verify type safety.
</details>

<details>
<summary><b>What is the October 2026 php2shell vulnerability and how do I fix it?</b></summary>
The October 2026 php2shell vulnerabilities encompass advanced CGI argument injection bypasses (soft-hyphen / Unicode best-fit mapping on <code>php-cgi</code> like <code>%ad%64</code>), iconv stream filter chain memory corruption in <code>php://filter</code>, and arbitrary webshell file uploads. This toolkit fixes it through web server perimeter blocking in <code>webserver-hardened.conf</code>, runtime restriction in <code>php-hardened.ini</code>, and source code remediation.
</details>

<details>
<summary><b>Can I upgrade Laravel 8 directly to Laravel 12?</b></summary>
Direct jumps risk breaking Flysystem storage drivers, email transports, and application kernels. Follow our staged Laravel guide (8 -> 9 -> 10 -> 11 -> 12) using the pre-configured <code>rector-laravel.php</code> to automate syntax adjustments and preserve database and auth integrity.
</details>

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) - see the [LICENSE](LICENSE) file for details.

Developed with ❤️ by **[Nawal Patel](https://github.com/nawalpateldev)**.

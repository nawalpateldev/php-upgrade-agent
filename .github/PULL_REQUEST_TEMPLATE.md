## 🚀 Summary of Changes

This Pull Request enhances the **Multi-LLM PHP Upgrade & Modernization Agent Toolkit** by enforcing **strictly relative path execution** across all supported AI assistants, preventing directory nesting during installation, and introducing dynamic candidate path discovery for heterogeneous PHP projects (Laravel, Symfony, CodeIgniter, WordPress, and custom legacy architectures).

---

### 🔑 Key Highlights & Improvements

#### 1. 📁 100% Relative Path Execution (Zero Hardcoded Paths)
- **Eliminated absolute path dependencies**: Commands now execute with clean relative paths from the target project root across Windows, Linux, and macOS without hardcoding host drive letters or paths.
- **Provider-Aware Relative Commands**: The installer dynamically inspects which AI assistant folders are active in the target project root and prints exact relative run commands:
  - **GitHub Copilot**: `php .github/skills/php2shell-fixer/scripts/php2shell-audit.php --path=.`
  - **Claude Code**: `php .claude/skills/php2shell-fixer/scripts/php2shell-audit.php --path=.`
  - **Gemini Code Assist / Antigravity**: `php .gemini/skills/php2shell-fixer/scripts/php2shell-audit.php --path=.` or `php .agents/skills/...`
  - **Universal Shared Engine**: `php .agents/skills/php2shell-fixer/scripts/php2shell-audit.php --path=.`

#### 2. 🔍 Project Root & Existing AI Folder Auto-Detection
- Automatically detects if the current working directory (`$PWD`) is the target PHP application.
- Auto-detects existing `.github`, `.claude`, `.gemini`, and `.agents` folders in the target root.
- Added full `.gemini/skills/` synchronization alongside `.agents/skills/` when configuring Gemini / Antigravity.

#### 3. 🛡️ Robust File Syncing & Anti-Nesting Guards
- Fixed `Copy-Item` and `cp` recursion logic in `install.ps1` and `install.sh` to prevent accidental folder nesting (e.g., `.agents/skills/skills/...`).
- Added self-copy safety checks (`$targetDir -ne $toolkitDir`) to prevent overwriting source files when running in-place.
- Ensured non-existent target directories are automatically provisioned before copying.

#### 4. 🧠 Dynamic Candidate Path Resolution in Modernization Tools
- **Rector Configurations** (`rector-php-upgrade.php`, `rector-laravel.php`, `rector-symfony.php`): Dynamically resolves existing source code directories (`app`, `src`, `application`, `system`, `routes`, `config`, etc.) using `is_dir()` checks to support CodeIgniter, Laravel, Symfony, and custom skeletons seamlessly without throwing path-not-found errors.
- **Security Scanners** (`security-audit.php` & `php2shell-audit.php`): Default to current directory (`.`) and automatically skip vendor directories, test fixtures, `.git`, and AI adapter directories (`.agents`, `.github`, `.claude`, `.gemini`).

---

### 🧪 Verification & Testing

- [x] **Windows PowerShell**: Verified clean installation and uninstallation on isolated target project directory via `install.ps1`.
- [x] **Relative Command Execution**: Tested `php2shell-audit.php` and `security-audit.php` using relative path `--path=.`.
- [x] **Safety Guarantees**: Confirmed zero application PHP files, Composer dependencies, or existing git files are touched or modified.
- [x] **Anti-Nesting**: Verified multiple consecutive runs do not create nested duplicate folders.

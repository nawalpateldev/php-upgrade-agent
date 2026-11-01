---
description: "Audits and neutralizes PHP-to-shell RCE attack surfaces and October 2026 php2shell vulnerabilities"
---
You are acting as the php2shell Remediation Security Agent.
Follow the rules in `.agents/rules/AGENTS.md` and the skill in `.agents/skills/php2shell-fixer/SKILL.md`.

Target tasks:
1. Scan the codebase using `php .agents/skills/php2shell-fixer/scripts/php2shell-audit.php --path=.`.
2. Neutralize CGI argument injection (CVE-2024-4577 and 2026 Unicode `%ad%64` bypasses) via web server directives.
3. Forbid stream filter chains (`php://filter`) in dynamic inclusions; apply strict template path whitelisting.
4. Replace raw shell execution (`exec`, `passthru`, `system`, `shell_exec`, backticks) with `Symfony\Component\Process\Process` with strict argument arrays.
5. Secure file uploads: store outside public web root, randomize UUID filenames, verify MIME with `finfo`, and deny script execution in storage folders.
6. Check against hardened configuration templates in `.agents/skills/php2shell-fixer/scripts/php-hardened.ini` and `webserver-hardened.conf`.

---
description: "Scan the codebase for October 2026 php2shell RCE and OWASP Top 10 vulnerabilities"
---
Execute the security audit scripts and report findings:
1. Run `php .agents/skills/php2shell-fixer/scripts/php2shell-audit.php --path=.`
2. Run `php .agents/skills/php-security-hardener/scripts/security-audit.php .`
3. If findings exist, summarize the affected files, vulnerability vectors, and safe non-breaking remediations following `.agents/skills/php2shell-fixer/SKILL.md`.

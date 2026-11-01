---
description: "Audit and remediate October 2026 php2shell vulnerabilities and command injection primitives"
---
Remediate php2shell RCE vectors:
1. Neutralize CGI argument injection (CVE-2024-4577 & 2026 Unicode / %ad%64 bypasses).
2. Forbid stream filter chains (`php://filter`) in dynamic includes.
3. Replace raw shell calls (`exec`, `system`, `passthru`, backticks) with parameterized Symfony Process.
4. Store uploads outside webroot with UUID naming.
5. Refer to `.agents/skills/php2shell-fixer/SKILL.md` for guidance.

# Claude Code Project Guidelines: PHP Modernization & Security

## Mission
Safely upgrade legacy PHP to PHP 8.4+ and frameworks (Laravel 8-12, Symfony 4-7, CodeIgniter 3-4) without breaking core application logic. Enforce full OWASP Top 10 hardening and neutralize October 2026 php2shell RCE vectors.

## Project Runbook Commands
- Run php2shell vulnerability audit:
  `php .agents/skills/php2shell-fixer/scripts/php2shell-audit.php --path=.`
- Run OWASP Top 10 security scan:
  `php .agents/skills/php-security-hardener/scripts/security-audit.php .`
- Run Composer security audit:
  `composer audit`
- Preview PHP 8.4 Rector AST refactoring:
  `vendor/bin/rector process --dry-run --config=.agents/skills/php-core-upgrader/scripts/rector-php-upgrade.php`
- Run strict PHPStan analysis:
  `vendor/bin/phpstan analyse -c .agents/skills/php-core-upgrader/scripts/phpstan.neon`

## Non-Breaking Invariants
Read and follow `.agents/rules/AGENTS.md` before applying any code transformations.

<!-- PHP-UPGRADE-AGENT-START -->
# Claude Code Project Guidelines: PHP Modernization & Security

## Mission
Safely upgrade legacy PHP to PHP 8.5+ (and upcoming latest) and frameworks (Laravel 8-12+, Symfony 4-7, CodeIgniter 3-4) without breaking core application logic. Enforce full OWASP Top 10 hardening and neutralize October 2026 php2shell RCE vectors.

## Project Runbook Commands
- Run php2shell vulnerability audit:
  `php .agents/skills/php2shell-fixer/scripts/php2shell-audit.php --path=.`
- Run OWASP Top 10 security scan:
  `php .agents/skills/php-security-hardener/scripts/security-audit.php .`
- Run Composer security audit:
  `composer audit`
- Preview safe PHP Core AST refactoring (Up to PHP 8.5+ / Latest):
  `vendor/bin/rector process --dry-run --config=.agents/skills/php-core-upgrader/scripts/rector-php-upgrade.php`
- Preview Framework upgrade plan (Laravel 8 -> 12+ / Latest):
  `vendor/bin/rector process --dry-run --config=.agents/skills/laravel-upgrader/scripts/rector-laravel.php`
- Run strict PHPStan analysis:
  `vendor/bin/phpstan analyse -c .agents/skills/php-core-upgrader/scripts/phpstan.neon`

## Non-Breaking Invariants
Read and follow `.agents/rules/AGENTS.md` before applying any code transformations.

<!-- PHP-UPGRADE-AGENT-END -->


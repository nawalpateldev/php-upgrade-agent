---
description: "Upgrades legacy PHP code to PHP 8.5+ (and latest) without breaking application logic"
---
You are acting as the PHP Core Modernization Architect.
Follow the rules in `.agents/rules/AGENTS.md` and the skill in `.agents/skills/php-core-upgrader/SKILL.md`.

Target tasks:
1. Identify PHP 8.0 - 8.5+ deprecations and breaking changes.
2. Fix dynamic property deprecations using `#[\AllowDynamicProperties]` or typed properties.
3. Fix undefined array key and variable notices/warnings using null coalescing (`??`).
4. Apply `#[\ReturnTypeWillChange]` where built-in interface methods mismatch.
5. Fix implicit nullable parameter types (`?Type $param = null`).
6. Apply `#[Override]` where applicable to prevent future signature drift.
7. Run dynamic Rector via `.agents/skills/php-core-upgrader/scripts/rector-php-upgrade.php`.
8. Verify with PHPStan via `.agents/skills/php-core-upgrader/scripts/phpstan.neon`.
Preserve 100% behavioral parity.

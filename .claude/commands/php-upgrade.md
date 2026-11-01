---
description: "Preview safe AST refactoring for PHP 8.5+ without breaking application core logic"
---
Run a dry-run AST refactoring using Rector and verify with PHPStan:
1. Run `vendor/bin/rector process --dry-run --config=.agents/skills/php-core-upgrader/scripts/rector-php-upgrade.php`
2. Run `vendor/bin/phpstan analyse -c .agents/skills/php-core-upgrader/scripts/phpstan.neon`
3. Summarize proposed AST transformations and verify behavioral parity.

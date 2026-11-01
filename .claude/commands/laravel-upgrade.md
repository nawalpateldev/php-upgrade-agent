---
description: "Preview stepwise migration plan for Laravel 8 to Laravel 12+ and latest"
---
Preview Laravel framework migration:
1. Run `vendor/bin/rector process --dry-run --config=.agents/skills/laravel-upgrader/scripts/rector-laravel.php`
2. Inspect models, storage (Flysystem 3), mailers, and `bootstrap/app.php` skeleton modernization.
3. Verify routes with `php artisan route:list` and run test suite.

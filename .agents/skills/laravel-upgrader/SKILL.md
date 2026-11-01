---
name: laravel-upgrader
description: >-
  Guides step-by-step upgrades of Laravel applications from version 8 up to version 12
  (and latest) without breaking application core logic, database persistence, routing,
  or authentication. Handles Flysystem 3, Symfony Mailer, Kernels, and skeleton transitions.
---

# Laravel Upgrader Skill (Laravel 8 -> 12+)

This skill manages the major architectural and dependency jumps required to migrate a Laravel 8 application to Laravel 9, 10, 11, and 12+.

---

## Upgrade Strategy: Strict Sequential Progression

Never leap directly from Laravel 8 to 12. Each major version introduces distinct breaking changes across core subsystems:

```
[Laravel 8.x] 
      │ (PHP 8.0+, Flysystem 3, Symfony Mailer)
      ▼
[Laravel 9.x]
      │ (PHP 8.1+, Strict PHP Return Types, $casts over $dates)
      ▼
[Laravel 10.x]
      │ (PHP 8.2+, Streamlined bootstrap/app.php, RouteServiceProvider removal)
      ▼
[Laravel 11.x]
      │ (PHP 8.2/8.3+, Concurrency API, Strict Type Bindings)
      ▼
[Laravel 12.x / Latest]
```

---

## Phase 1: Laravel 8 to Laravel 9

### 1. Dependency Bump (`composer.json`)
```json
"require": {
    "php": "^8.0.2",
    "laravel/framework": "^9.0",
    "nunomaduro/collision": "^6.1"
}
```

### 2. Flysystem 3 Migration
Laravel 9 upgraded from Flysystem 1.x to 3.x.
- `Storage::getDriver()` now returns `League\Flysystem\FilesystemOperator` instead of `Flysystem\FilesystemInterface`.
- File existence checking: `Storage::missing($path)` is preferred over manual `!Storage::exists($path)`.
- Write/Put operations: Flysystem 3 throws exceptions on write failures instead of returning `false`. Guard disk write operations with `try { ... } catch (UnableToWriteFile $e) { ... }`.

### 3. SwiftMailer to Symfony Mailer
- SwiftMailer was abandoned; Laravel 9 adopted Symfony Mailer.
- In `composer.json`, replace `"swiftmailer/swiftmailer"` with `"symfony/mailer"`.
- Custom transport plugins must be migrated to Symfony Mailer transport factories.

---

## Phase 2: Laravel 9 to Laravel 10

### 1. Dependency Bump (`composer.json`)
```json
"require": {
    "php": "^8.1.0",
    "laravel/framework": "^10.0"
}
```

### 2. Model `$dates` Deprecation
- The `$dates` property on Eloquent models is deprecated.
- **Migration**: Move all custom date fields into the `$casts` property:
  ```php
  // Before (Laravel 9):
  protected $dates = ['published_at'];

  // After (Laravel 10):
  protected $casts = [
      'published_at' => 'datetime',
  ];
  ```

### 3. Native PHP Type Declarations
Laravel 10 introduced native return types and argument types across all userland skeleton methods (Service Providers, Controllers, FormRequests).

---

## Phase 3: Laravel 10 to Laravel 11

### 1. Dependency Bump (`composer.json`)
```json
"require": {
    "php": "^8.2.0",
    "laravel/framework": "^11.0"
}
```

### 2. Streamlined Application Skeleton (`bootstrap/app.php`)
Laravel 11 removed `app/Http/Kernel.php`, `app/Console/Kernel.php`, and `app/Providers/RouteServiceProvider.php`. Routing and middleware are now configured directly in `bootstrap/app.php`:

```php
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        // Register custom global middleware or alias middleware here
        $middleware->alias([
            'admin' => \App\Http\Middleware\EnsureUserIsAdmin::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        // Exception reporting & rendering customizations
    })->create();
```

> [!NOTE]
> Existing Laravel 10 application kernels (`Kernel.php`) will still execute in Laravel 11 if not deleted. You can retain them during an initial transitional phase and refactor to `bootstrap/app.php` once verified.

### 3. Model Casts Method Modernization
Laravel 11 introduced `casts()` method alongside `$casts` array:
```php
protected function casts(): array
{
    return [
        'is_active' => 'boolean',
        'options' => 'array',
    ];
}
```

---

## Phase 4: Laravel 11 to Laravel 12 (Latest)

### 1. Dependency Bump (`composer.json`)
```json
"require": {
    "php": "^8.2.0|^8.3.0|^8.4.0",
    "laravel/framework": "^12.0"
}
```

### 2. Verification Steps
1. Run Rector for automated framework migration:
   ```bash
   vendor/bin/rector process --config=.agents/skills/laravel-upgrader/scripts/rector-laravel.php
   ```
2. Execute tests:
   ```bash
   php artisan test
   ```
3. Clear and rebuild application caches:
   ```bash
   php artisan optimize:clear
   php artisan route:list
   ```

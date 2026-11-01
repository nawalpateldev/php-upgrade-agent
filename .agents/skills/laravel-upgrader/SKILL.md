---
name: laravel-upgrader
description: >-
  Guides step-by-step upgrades of Laravel applications from version 8 up to version 12
  (and latest) without breaking application core logic, database persistence, routing,
  or authentication. Handles Flysystem 3, Symfony Mailer, Kernels, and skeleton transitions.
---

# Laravel Upgrader Skill (Laravel 8 -> 12+ & Latest)

This skill manages the major architectural and dependency jumps required to migrate a Laravel 8 application to Laravel 9, 10, 11, 12+, and upcoming framework releases without becoming obsolete over time.

---

## Upgrade Strategy: Strict Sequential Progression

Never leap directly across multiple versions. Each major version introduces distinct breaking changes across core subsystems:

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
      │ (PHP 8.2/8.3/8.5+, Concurrency API, Strict Type Bindings)
      ▼
[Laravel 12.x & Latest]
```

---

## Phase 1: Laravel 8 to Laravel 9

### 1. Dependency Bump (`composer.json`)
```json
"require": {
    "php": "^8.0.2|^8.1|^8.2|^8.3|^8.4|^8.5",
    "laravel/framework": "^9.0",
    "nunomaduro/collision": "^6.1"
}
```

### 2. Flysystem 3 Migration
Laravel 9 upgraded from Flysystem 1.x to 3.x.
- `Storage::getDriver()` returns `League\Flysystem\FilesystemOperator`.
- File existence checking: `Storage::missing($path)` is preferred over manual `!Storage::exists($path)`.
- Write/Put operations: Guard disk write operations with `try { ... } catch (UnableToWriteFile $e) { ... }`.

### 3. SwiftMailer to Symfony Mailer
- Replace `"swiftmailer/swiftmailer"` with `"symfony/mailer"`.
- Migrate custom transport plugins to Symfony Mailer transport factories.

---

## Phase 2: Laravel 9 to Laravel 10

### 1. Dependency Bump (`composer.json`)
```json
"require": {
    "php": "^8.1.0|^8.2|^8.3|^8.4|^8.5",
    "laravel/framework": "^10.0"
}
```

### 2. Model `$dates` Deprecation
- Move all custom date fields into the `$casts` property:
  ```php
  protected $casts = [
      'published_at' => 'datetime',
  ];
  ```

---

## Phase 3: Laravel 10 to Laravel 11

### 1. Dependency Bump (`composer.json`)
```json
"require": {
    "php": "^8.2.0|^8.3|^8.4|^8.5",
    "laravel/framework": "^11.0"
}
```

### 2. Streamlined Application Skeleton (`bootstrap/app.php`)
Routing and middleware are configured directly in `bootstrap/app.php`:

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
        $middleware->alias([
            'admin' => \App\Http\Middleware\EnsureUserIsAdmin::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        // ...
    })->create();
```

---

## Phase 4: Laravel 11 to Laravel 12 & Latest

### 1. Dependency Bump (`composer.json`)
```json
"require": {
    "php": ">=8.2.0",
    "laravel/framework": "^12.0"
}
```

### 2. Continuous Anti-Obsolescence Execution
1. Run Rector with dynamic target detection:
   ```bash
   vendor/bin/rector process --config=.agents/skills/laravel-upgrader/scripts/rector-laravel.php
   ```
2. Verify application routes and tests:
   ```bash
   php artisan test
   php artisan optimize:clear
   php artisan route:list
   ```

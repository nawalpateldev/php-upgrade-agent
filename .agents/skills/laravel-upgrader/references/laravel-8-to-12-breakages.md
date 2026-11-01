# Laravel 8 -> 12 Comprehensive Breaking Changes & Fix Catalog

This catalog details breaking changes encountered across each major jump from Laravel 8 to Laravel 12.

---

## 1. Database & Eloquent Breakages

### Model `$dates` Array Deprecated (Laravel 10)
- **Problem**: Any model declaring `protected $dates = ['created_at', 'expires_at'];` triggers deprecation notices.
- **Fix**: Move all fields to `protected $casts = ['expires_at' => 'datetime'];`.

### Model `casts()` Method (Laravel 11+)
- **Modern syntax**: Using a method allows calls to static enum methods and object initializers:
```php
protected function casts(): array
{
    return [
        'status' => OrderStatus::class,
        'options' => 'json',
    ];
}
```

---

## 2. Storage & Flysystem Breakages (Laravel 9+)

- **File missing vs exists**:
```php
// Old (Flysystem 1):
if (!Storage::disk('s3')->exists($path)) { ... }

// Modern (Flysystem 3):
if (Storage::disk('s3')->missing($path)) { ... }
```
- **Stream resource writes**:
In Flysystem 3, passing an invalid stream or encountering upload permissions throws `League\Flysystem\UnableToWriteFile` rather than returning `false`. Wrap in try/catch if custom fallback logic is required.

---

## 3. Configuration & Bootstrap Simplification (Laravel 11 & 12)

- Default configs (`config/app.php`, `config/database.php`, etc.) are now merged from the framework vendor defaults. Only customized keys need to remain in userland `config/`.
- `Http/Kernel.php` and `Console/Kernel.php` are deprecated; configuration moves to `bootstrap/app.php`.
- Middleware registration:
```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->web(append: [
        \App\Http\Middleware\MyCustomMiddleware::class,
    ]);
})
```

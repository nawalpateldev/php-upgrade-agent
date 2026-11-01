# PHP Breaking Changes & Safe Remediation Reference (PHP 7.0 -> 8.5+)

This reference documents breaking changes when modernizing legacy PHP applications up to **PHP 8.5.12+ and upcoming releases**, along with safe code transformations that ensure behavioral parity and long-term anti-obsolescence.

---

## 1. PHP 8.0: Strict Type Checking on Internal Functions & Undefined Array Keys

### Issue: Undefined Array Keys / Variables
In PHP 7.x, accessing an undefined array key or variable emitted `E_NOTICE`. In PHP 8.0+, it emits `E_WARNING`. Modern framework error handlers convert warnings to fatal `ErrorException`.

#### Unsafe Legacy Code:
```php
$timeout = $config['timeout']; // Throws Warning if 'timeout' is missing
```

#### Safe Modern Code:
```php
$timeout = $config['timeout'] ?? 30;
```

---

### Issue: String to Number Comparisons
In PHP 7.x, `"0" == "0e123"` was true, and `0 == "foobar"` was true.
In PHP 8.0+, non-numeric strings are compared as strings. Thus:
`0 == "foobar"` evaluates to `false` in PHP 8+, but was `true` in PHP 7.

#### Safe Modern Code:
```php
if ((string)$status === 'active') { ... }
```

---

## 2. PHP 8.1: Null Arguments to Built-in Functions & Interface Return Types

### Issue: Deprecated Passing `null` to Non-Nullable Internal Functions
```php
strlen(null); // Deprecated in 8.1, TypeError in 8.5+
str_replace('a', 'b', null);
```

#### Safe Modern Code:
```php
strlen((string)$str);
str_replace('a', 'b', (string)$text);
```

---

### Issue: Interface Return Types (`ReturnTypeWillChange`)
Internal PHP interfaces (`ArrayAccess`, `Iterator`, `Countable`, `JsonSerializable`) declare strict return types.

#### Safe Modern Code:
```php
class LegacyCollection implements \JsonSerializable {
    #[\ReturnTypeWillChange] // Dual compatibility bridge
    public function jsonSerialize(): mixed {
        return $this->items;
    }
}
```

---

## 3. PHP 8.2: Dynamic Properties Deprecation

### Issue: Creating Undefined Class Properties
Assigning values to undeclared properties on classes is deprecated in PHP 8.2 and escalates to a fatal `Error` in subsequent releases.

#### Safe Modern Code:
Option A (Safe bridge for legacy classes):
```php
#[\AllowDynamicProperties]
class LegacyService {
    // Dynamic property assignment permitted without warnings
}
```

Option B (Strict type declaration):
```php
class LegacyService {
    public ?string $cachedData = null;
}
```

---

## 4. PHP 8.4: Implicit Nullable Types Deprecation

### Issue: `function test(string $param = null)`
Declaring a parameter with a default of `null` without marking the type nullable is deprecated in PHP 8.4.

#### Safe Modern Code:
```php
function test(?string $param = null): void {
    // ...
}
```

---

## 5. PHP 8.5+ & Forward Compatibility (PHP 9.0 Prep)

### Strict Override Enforcement (`#[Override]`)
PHP 8.3+ introduced the `#[Override]` attribute. In PHP 8.5+, adopting `#[Override]` on subclass methods prevents silent API breakage if parent method names or signatures are modified during framework upgrades.

#### Safe Modern Code:
```php
class CustomRepository extends BaseRepository {
    #[\Override]
    public function findById(int $id): ?object {
        return parent::findById($id);
    }
}
```

### Complete Deprecation of Obsolete Serialization Handlers
Custom object serialization via `Serializable` interface is removed in favor of `__serialize()` and `__unserialize()`.

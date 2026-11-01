# PHP Breaking Changes & Safe Remediation Reference (PHP 7.0 -> 8.4)

This reference documents the most hazardous breaking changes when modernizing legacy PHP applications, along with safe code transformations that ensure behavioral parity.

---

## 1. PHP 8.0: Strict Type Checking on Internal Functions & Undefined Array Keys

### Issue: Undefined Array Keys / Variables
In PHP 7.x, accessing an undefined array key or variable emitted `E_NOTICE`. In PHP 8.0+, it emits `E_WARNING`. Framework error handlers (like Laravel or Symfony) convert warnings to fatal `ErrorException`.

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
// Explicitly cast or compare strictly:
if ((string)$status === 'active') { ... }
```

---

## 2. PHP 8.1: Null Arguments to Built-in Functions & Interface Return Types

### Issue: Deprecated Passing `null` to Non-Nullable Internal Functions
```php
// PHP 7: Returns 0
// PHP 8.1+: Deprecated warning / TypeError in PHP 9
strlen(null);
str_replace('a', 'b', null);
```

#### Safe Modern Code:
```php
strlen((string)$str);
str_replace('a', 'b', (string)$text);
```

---

### Issue: Interface Return Types (`ReturnTypeWillChange`)
Internal PHP interfaces (`ArrayAccess`, `Iterator`, `Countable`, `JsonSerializable`) now declare return types.

#### Legacy:
```php
class LegacyCollection implements \JsonSerializable {
    public function jsonSerialize() {
        return $this->items;
    }
}
```

#### Safe Modern Code:
```php
class LegacyCollection implements \JsonSerializable {
    #[\ReturnTypeWillChange] // Safe bridge for dual PHP 7/8 compatibility
    public function jsonSerialize(): mixed {
        return $this->items;
    }
}
```

---

## 3. PHP 8.2: Dynamic Properties Deprecation

### Issue: Creating Undefined Class Properties
Assigning values to non-existent properties on classes is deprecated in PHP 8.2 and fatal in PHP 9.0.

#### Safe Modern Code:
Option A (Fastest non-breaking bridge):
```php
#[\AllowDynamicProperties]
class LegacyService {
    // Dynamic property assignment won't throw deprecation warning
}
```

Option B (Clean refactoring):
Declare the property explicitly on the class:
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

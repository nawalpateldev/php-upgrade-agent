# PHP Upgrade & Modernization Agent Rules (AGENTS.md)

These rules govern all PHP modernization, framework migration, and security auditing tasks within this repository. All agents and subagents must strictly adhere to these principles.

---

## 1. Zero Business Logic Breakage Invariant

- **Behavioral Parity Over Refactoring Perfection**: Never refactor code purely for aesthetic reasons during a version migration. Code changes must preserve 100% of the input/output behavioral parity of existing services, APIs, and models.
- **Incremental Leaps Only**:
  - Never attempt a direct jump across multiple major versions in one unverified step (e.g., PHP 5.6 directly to 8.4 or Laravel 8 directly to 12).
  - Always execute step-by-step:
    - PHP: `5.6 -> 7.4 -> 8.0 -> 8.1 -> 8.2 -> 8.3 -> 8.4`
    - Laravel: `8.x -> 9.x -> 10.x -> 11.x -> 12.x`
    - Symfony: `4.4/5.4 -> 6.4 LTS -> 7.x`
    - CodeIgniter: `3.x -> 4.x bridge / PSR-4 modernization`
- **Baseline Test Suite Verification**:
  - Before making any code modifications, verify or create characterization/regression tests for critical paths.
  - Run the test suite after each incremental minor/major bump.

---

## 2. PHP Core Type & Deprecation Safety

- **Dynamic Properties**:
  - In PHP 8.2+, dynamic properties are deprecated and throw fatal `Error` in PHP 9.0.
  - Add `#[\AllowDynamicProperties]` as a temporary safe bridge to legacy classes, or properly declare typed properties.
- **Undefined Array Keys & Variables**:
  - In PHP 8.0+, accessing undefined array keys or variables triggers `E_WARNING` (often converted to exceptions in modern framework error handlers).
  - Use null-coalescing (`$arr['key'] ?? null`) or explicit `array_key_exists()` checks. Never silence with `@` operator.
- **Strict Return Types & Param Types**:
  - When implementing framework or core interfaces (e.g., `Iterator`, `ArrayAccess`, `JsonSerializable`), ensure exact signature compatibility (including `#[ReturnTypeWillChange]` where legacy signatures must be retained temporarily).

---

## 3. Security Hardening & php2shell Remediation

- **Mandatory Threat Neutralization**:
  - Any discovery of remote code execution (RCE) or PHP-to-shell primitives (`system`, `exec`, `passthru`, `shell_exec`, `proc_open`, `popen`, `pcntl_exec`, eval, dynamic assert) must immediately be flagged and remediated.
  - Mitigate Oct 2026 php2shell vulnerability vectors:
    - **CGI Argument Injection (CVE-2024-4577 & 2026 Unicode/Bypass Variants)**: Block query string injection on PHP-CGI environments via web server directives and runtime sanitizers.
    - **Stream Filter Chains / `php://filter` RCE**: Enforce strict validation on dynamic file inclusion; forbid arbitrary stream wrappers.
    - **Multipart Parser & File Upload Bypasses**: Prevent executable extensions, MIME-type spoofing, `.htaccess` / `.user.ini` overwrites, and webroot uploads.
    - **Deserialization Gadgets**: Disallow `unserialize()` on untrusted input; replace with JSON or signed payloads. Disallow unvetted `phar://` stream paths.
- **Secure by Default**:
  - Always apply prepared statements for SQL (PDO / ORM).
  - Always sanitize shell arguments using `escapeshellarg()` / `escapeshellcmd()` or replace shell executions with native PHP libraries (e.g., `symfony/process` with strict argument arrays).

---

## 4. Framework Upgrade Standards

- **Laravel (8 -> 12)**:
  - Migrate Flysystem v1 to v3 (`Storage::getDriver()` changes, file existence checks).
  - Migrate SwiftMailer to Symfony Mailer.
  - Upgrade Eloquent attribute accessors/mutators to `Attribute::make()`.
  - Transition configuration and routing to Laravel 11/12 streamlined structure (`bootstrap/app.php`).
- **Symfony (4/5 -> 6/7)**:
  - Migrate Doctrine annotations to native PHP 8 attributes.
  - Migrate legacy Guard authenticators to Symfony's unified Security Authenticator system.
  - Ensure compatibility with strict scalar and return type declarations in Symfony contracts.
- **CodeIgniter (3 -> 4)**:
  - Isolate business logic from CI3 `$this->load` into reusable PSR-4 service layers.
  - Migrate CI3 database queries to CI4 Query Builder or Entity Models.

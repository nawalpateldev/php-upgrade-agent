# OWASP Top 10 for PHP: Modern Hardening Checklist

### 1. Broken Access Control (BAC)
- [ ] Ensure every controller endpoint validates authenticated user permissions using Policies / Gates (Laravel) or Voters (Symfony).
- [ ] Prevent Insecure Direct Object References (IDOR) by checking tenant ownership: `User::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id)`.

### 2. Cryptographic Failures
- [ ] Enforce HTTPS only (`Strict-Transport-Security` header).
- [ ] Migrate all password hashes to `PASSWORD_ARGON2ID` or `PASSWORD_BCRYPT`.
- [ ] Store sensitive credentials in environment variables (`.env`), never committed to git.

### 3. Injection
- [ ] Neutralize SQLi: Use PDO prepared statements or ORM binding without raw concatenation.
- [ ] Neutralize Command Injection: Avoid `exec()`, `system()`, and backticks. Use Symfony Process with strict argument arrays.

### 4. Insecure Design
- [ ] Implement rate limiting on authentication routes (login, registration, password reset).
- [ ] Enforce account lockout or captcha after 5 consecutive failed login attempts.

### 5. Security Misconfiguration
- [ ] Set `display_errors = Off` in production.
- [ ] Set `expose_php = Off` in `php.ini`.
- [ ] Remove debug tools (`laravel-debugbar`, Symfony profiler) from production environments.

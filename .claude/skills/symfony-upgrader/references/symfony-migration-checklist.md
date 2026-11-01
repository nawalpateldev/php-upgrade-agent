# Symfony 4.4 / 5.4 -> 6.4 -> 7.x Checklist

### Pre-requisites
- [ ] Upgrade runtime to PHP 8.2 or 8.3.
- [ ] Ensure all Composer packages have 6.4/7.x compatible versions.
- [ ] Fix all deprecation notices logged in `var/log/dev.deprecations.log`.

### Configuration & Security
- [ ] Replace `security.yaml` `guard:` configs with unified `custom_authenticators`.
- [ ] Enable password hashing via `Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface`.
- [ ] Convert XML/YAML routing to PHP attributes where appropriate.

### Services & DI
- [ ] Ensure all controllers extend `Symfony\Bundle\FrameworkBundle\Controller\AbstractController` instead of `Controller`.
- [ ] Replace `$this->get('service_name')` with constructor dependency injection.
- [ ] Run `php bin/console lint:yaml config` and `php bin/console lint:container`.

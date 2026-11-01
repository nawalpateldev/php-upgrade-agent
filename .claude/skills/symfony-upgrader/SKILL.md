---
name: symfony-upgrader
description: >-
  Guides migration of Symfony applications from legacy 4.4 / 5.4 LTS versions
  to Symfony 6.4 LTS and Symfony 7.x+ without breaking business services,
  doctrine mappings, security authentication, or routing contracts.
---

# Symfony Upgrader Skill (Symfony 4.4 / 5.4 -> 6.4 LTS -> 7.x)

This skill provides step-by-step procedures, automated Rector sets, and checklists to safely upgrade Symfony applications.

---

## Upgrade Path: The Two-Stage Migration

```
[Symfony 4.4 / 5.4] 
      │ 
      ▼ (Resolve deprecations, transition to PHP 8 attributes & new Authenticator)
[Symfony 6.4 LTS] 
      │ 
      ▼ (Remove legacy dead code, upgrade to PHP 8.2+, adopt strict contracts)
[Symfony 7.x / Latest]
```

---

## Phase 1: Annotations to Native PHP 8 Attributes

Symfony 6.4 and 7 completely phase out Doctrine/Sensio annotations in favor of native PHP 8 attributes.

### Routes Migration
```php
// Before (DocBlock Annotation):
/**
 * @Route("/api/users", name="api_users_list", methods={"GET"})
 */
public function list(): JsonResponse { ... }

// After (PHP 8 Attribute):
#[Route('/api/users', name: 'api_users_list', methods: ['GET'])]
public function list(): JsonResponse { ... }
```

### Doctrine Entity Mapping Migration
```php
// Before:
/**
 * @ORM\Entity(repositoryClass=UserRepository::class)
 * @ORM\Table(name="users")
 */
class User {
    /**
     * @ORM\Id
     * @ORM\GeneratedValue
     * @ORM\Column(type="integer")
     */
    private $id;
}

// After:
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: UserRepository::class)]
#[ORM\Table(name: 'users')]
class User {
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;
}
```

---

## Phase 2: Security System Migration (Guard to Authenticator)

The legacy `Guard` authentication system (`GuardAuthenticatorInterface`) was removed in Symfony 6. Migrate to the unified `AuthenticatorInterface`:

```php
use Symfony\Component\Security\Http\Authenticator\AbstractAuthenticator;
use Symfony\Component\Security\Http\Authenticator\Passport\Passport;
use Symfony\Component\Security\Http\Authenticator\Passport\Badge\UserBadge;
use Symfony\Component\Security\Http\Authenticator\Passport\Credentials\PasswordCredentials;

class CustomFormAuthenticator extends AbstractAuthenticator
{
    public function supports(Request $request): ?bool
    {
        return $request->attributes->get('_route') === 'app_login' && $request->isMethod('POST');
    }

    public function authenticate(Request $request): Passport
    {
        $email = $request->request->get('email', '');
        $password = $request->request->get('password', '');

        return new Passport(
            new UserBadge($email),
            new PasswordCredentials($password)
        );
    }
}
```

---

## Phase 3: Automated Migration with Rector

Run the automated [Symfony Rector Script](./scripts/rector-symfony.php):

```bash
# Dry run
vendor/bin/rector process --dry-run --config=.agents/skills/symfony-upgrader/scripts/rector-symfony.php

# Apply transformations
vendor/bin/rector process --config=.agents/skills/symfony-upgrader/scripts/rector-symfony.php
```

---

## Phase 4: Container & Deprecation Checks

1. Inspect container compilation:
   ```bash
   php bin/console lint:container
   ```
2. Validate routing definitions:
   ```bash
   php bin/console debug:router
   ```
3. Run test suite:
   ```bash
   vendor/bin/phpunit
   ```

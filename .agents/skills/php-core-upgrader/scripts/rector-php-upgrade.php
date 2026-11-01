<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;
use Rector\Php80\Rector\Class_\ClassPropertyAssignToConstructorPromotionRector;
use Rector\Php81\Rector\ClassMethod\NewInInitializerRector;
use Rector\Php82\Rector\Class_\ReadOnlyClassRector;

/**
 * Production-ready Rector configuration for safe, incremental PHP core upgrades.
 * Target: Up to PHP 8.4
 */
return static function (RectorConfig $rectorConfig): void {
    // Configure paths to scan (adjust according to your project structure)
    $rectorConfig->paths([
        __DIR__ . '/../../../../app',
        __DIR__ . '/../../../../src',
    ]);

    // Skip third-party dependencies, test fixtures, and vendor directories
    $rectorConfig->skip([
        '*/vendor/*',
        '*/tests/Fixtures/*',
        '*/storage/*',
        '*/cache/*',
    ]);

    // Apply incremental level sets for PHP 8.0, 8.1, 8.2, 8.3, and 8.4
    // Uncomment or adjust based on your current starting baseline
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_84,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::EARLY_RETURN,
    ]);

    // Conservative skips to ensure zero disruption of existing behavior:
    // Skip overly aggressive transformations on legacy models
    $rectorConfig->skip([
        // Avoid auto-converting legacy classes to readonly classes if they might be extended
        ReadOnlyClassRector::class,
    ]);
};

<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use RectorLaravel\Set\LaravelLevelSetList;
use RectorLaravel\Set\LaravelSetList;

/**
 * Rector configuration for automated Laravel 8 -> 12 upgrades.
 * Utilizes driftingly/rector-laravel rulesets.
 */
return static function (RectorConfig $rectorConfig): void {
    $rectorConfig->paths([
        __DIR__ . '/../../../../app',
        __DIR__ . '/../../../../routes',
        __DIR__ . '/../../../../database',
        __DIR__ . '/../../../../config',
    ]);

    $rectorConfig->skip([
        '*/storage/*',
        '*/bootstrap/cache/*',
        '*/vendor/*',
    ]);

    // Apply incremental Laravel sets
    $rectorConfig->sets([
        LaravelLevelSetList::UP_TO_LARAVEL_110,
        LaravelSetList::LARAVEL_CODE_QUALITY,
        LaravelSetList::ARRAY_STR_FUNCTIONS_TO_STATIC_CALL,
    ]);
};

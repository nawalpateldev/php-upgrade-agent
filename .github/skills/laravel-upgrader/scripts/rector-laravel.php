<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use RectorLaravel\Set\LaravelLevelSetList;
use RectorLaravel\Set\LaravelSetList;

/**
 * Dynamic, Future-Proof Rector configuration for Laravel upgrades.
 * Supports legacy Laravel (8.x, 9.x, 10.x, 11.x) to Laravel 12+ and latest versions.
 * Automatically resolves the highest available Laravel level set to prevent obsolescence.
 */
return static function (RectorConfig $rectorConfig): void {
    $projectRoot = dirname(__DIR__, 4);
    $candidatePaths = [
        $projectRoot . '/app',
        $projectRoot . '/routes',
        $projectRoot . '/database',
        $projectRoot . '/config',
    ];
    $paths = array_values(array_filter($candidatePaths, 'is_dir'));
    if (empty($paths)) {
        $paths = [$projectRoot];
    }
    $rectorConfig->paths($paths);

    $rectorConfig->skip([
        '*/storage/*',
        '*/bootstrap/cache/*',
        '*/vendor/*',
    ]);

    $sets = [
        LaravelSetList::LARAVEL_CODE_QUALITY,
        LaravelSetList::ARRAY_STR_FUNCTIONS_TO_STATIC_CALL,
    ];

    // Dynamically apply highest available Laravel level set (Laravel 12, 11, or 10)
    if (defined('RectorLaravel\Set\LaravelLevelSetList::UP_TO_LARAVEL_120')) {
        $sets[] = constant('RectorLaravel\Set\LaravelLevelSetList::UP_TO_LARAVEL_120');
    } elseif (defined('RectorLaravel\Set\LaravelLevelSetList::UP_TO_LARAVEL_110')) {
        $sets[] = LaravelLevelSetList::UP_TO_LARAVEL_110;
    } else {
        $sets[] = LaravelLevelSetList::UP_TO_LARAVEL_100;
    }

    $rectorConfig->sets($sets);
};

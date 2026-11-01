<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;
use Rector\ValueObject\PhpVersion;
use Rector\Php82\Rector\Class_\ReadOnlyClassRector;

/**
 * Future-Proof Rector configuration for safe, incremental PHP core upgrades.
 * Supports legacy PHP (5.6, 7.x, 8.0-8.2) up to PHP 8.5+ and future PHP 8.x/9.x releases.
 * Automatically aligns with the host runtime version (e.g. PHP 8.5.12) to prevent obsolescence.
 */
return static function (RectorConfig $rectorConfig): void {
    // 1. Dynamic target PHP version detection
    // Detects host PHP runtime (e.g., PHP 8.5.12) or falls back to latest supported
    $currentPhpVersionId = PHP_VERSION_ID;
    
    // Set target PHP version dynamically
    $rectorConfig->phpVersion($currentPhpVersionId);

    // 2. Paths to process (dynamically detect existing application code directories)
    $projectRoot = dirname(__DIR__, 4);
    $candidatePaths = [
        $projectRoot . '/app',
        $projectRoot . '/src',
        $projectRoot . '/application',
        $projectRoot . '/system',
    ];
    $paths = array_values(array_filter($candidatePaths, 'is_dir'));
    if (empty($paths)) {
        $paths = [$projectRoot];
    }
    $rectorConfig->paths($paths);

    // 3. Excluded vendor, storage, and test fixtures
    $rectorConfig->skip([
        '*/vendor/*',
        '*/tests/Fixtures/*',
        '*/storage/*',
        '*/cache/*',
        // Avoid auto-converting legacy classes to readonly classes if they might be dynamically inherited
        ReadOnlyClassRector::class,
    ]);

    // 4. Staged Sets: Apply base modernization sets
    $sets = [
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::EARLY_RETURN,
    ];

    // Dynamically apply highest available PHP level set
    if (defined('Rector\Set\ValueObject\LevelSetList::UP_TO_PHP_85')) {
        $sets[] = constant('Rector\Set\ValueObject\LevelSetList::UP_TO_PHP_85');
    } elseif (defined('Rector\Set\ValueObject\LevelSetList::UP_TO_PHP_84')) {
        $sets[] = LevelSetList::UP_TO_PHP_84;
    } else {
        $sets[] = LevelSetList::UP_TO_PHP_83;
    }

    $rectorConfig->sets($sets);
};

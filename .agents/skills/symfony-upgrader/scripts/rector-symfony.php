<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Symfony\Set\SymfonyLevelSetList;
use Rector\Symfony\Set\SymfonySetList;
use Rector\Doctrine\Set\DoctrineSetList;

/**
 * Rector configuration for automated Symfony 5.4 -> 6.4 -> 7.x upgrades.
 */
return static function (RectorConfig $rectorConfig): void {
    $projectRoot = dirname(__DIR__, 4);
    $candidatePaths = [
        $projectRoot . '/src',
        $projectRoot . '/config',
    ];
    $paths = array_values(array_filter($candidatePaths, 'is_dir'));
    if (empty($paths)) {
        $paths = [$projectRoot];
    }
    $rectorConfig->paths($paths);

    $rectorConfig->skip([
        '*/var/*',
        '*/vendor/*',
    ]);

    // Sets for Symfony and Doctrine attributes
    $rectorConfig->sets([
        SymfonyLevelSetList::UP_TO_SYMFONY_64,
        SymfonySetList::SYMFONY_CODE_QUALITY,
        SymfonySetList::ANNOTATIONS_TO_ATTRIBUTES,
        DoctrineSetList::ANNOTATIONS_TO_ATTRIBUTES,
    ]);
};

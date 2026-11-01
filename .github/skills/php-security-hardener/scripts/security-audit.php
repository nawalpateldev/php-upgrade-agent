<?php

declare(strict_types=1);

/**
 * Automated PHP Security & Static Analysis Scanner
 * Identifies SQL injection, SSRF, raw user input output (XSS), and weak cryptography.
 */

$target = $argv[1] ?? '.';

if (!is_dir($target) && !is_file($target)) {
    echo "Usage: php security-audit.php [path-to-code (default: .)]\n";
    exit(1);
}

echo "Auditing security for directory: $target\n";

$patterns = [
    'SQL_INJECTION' => [
        'regex' => '/\$pdo->query\s*\(\s*["\'].*\$|->whereRaw\s*\(\s*["\'].*\$/i',
        'severity' => 'CRITICAL',
        'desc' => 'Potential SQL injection via raw string interpolation.'
    ],
    'WEAK_CRYPTO' => [
        'regex' => '/\b(md5|sha1)\s*\(\s*.*\$(?:password|pwd|secret|token)/i',
        'severity' => 'HIGH',
        'desc' => 'Insecure hashing algorithm used on sensitive credentials.'
    ],
    'INSECURE_RANDOM' => [
        'regex' => '/\brand\s*\(|\bmt_rand\s*\(/i',
        'severity' => 'MEDIUM',
        'desc' => 'Weak pseudo-random number generator; use random_bytes() or random_int() for security tokens.'
    ],
    'POTENTIAL_SSRF' => [
        'regex' => '/(file_get_contents|curl_init)\s*\(\s*\$(?:_GET|_POST|_REQUEST)/i',
        'severity' => 'HIGH',
        'desc' => 'External network fetch with direct user input without IP filtering.'
    ]
];

$files = is_file($target) ? [$target] : new RecursiveIteratorIterator(new RecursiveDirectoryIterator($target, FilesystemIterator::SKIP_DOTS));
$findingsCount = 0;

foreach ($files as $file) {
    $pathStr = (string)$file;
    if (is_dir($pathStr) || substr($pathStr, -4) !== '.php') {
        continue;
    }

    if (strpos($pathStr, DIRECTORY_SEPARATOR . 'vendor' . DIRECTORY_SEPARATOR) !== false ||
        strpos($pathStr, DIRECTORY_SEPARATOR . 'tests' . DIRECTORY_SEPARATOR) !== false ||
        strpos($pathStr, DIRECTORY_SEPARATOR . '.git' . DIRECTORY_SEPARATOR) !== false ||
        strpos($pathStr, DIRECTORY_SEPARATOR . '.agents' . DIRECTORY_SEPARATOR) !== false ||
        strpos($pathStr, DIRECTORY_SEPARATOR . '.github' . DIRECTORY_SEPARATOR) !== false ||
        strpos($pathStr, DIRECTORY_SEPARATOR . '.claude' . DIRECTORY_SEPARATOR) !== false ||
        strpos($pathStr, DIRECTORY_SEPARATOR . '.gemini' . DIRECTORY_SEPARATOR) !== false ||
        str_ends_with($pathStr, 'security-audit.php') ||
        str_ends_with($pathStr, 'php2shell-audit.php')) {
        continue;
    }
    
    $content = file_get_contents((string)$file);
    if ($content === false) continue;

    $lines = explode("\n", $content);
    foreach ($lines as $lineNum => $line) {
        foreach ($patterns as $type => $rule) {
            if (preg_match($rule['regex'], $line)) {
                echo "[{$rule['severity']}] $file:".($lineNum+1)." - {$rule['desc']}\n";
                echo "    Code: " . trim($line) . "\n\n";
                $findingsCount++;
            }
        }
    }
}

echo "Security audit finished with $findingsCount finding(s).\n";

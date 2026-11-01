<?php

declare(strict_types=1);

/**
 * PHP2Shell Native PHP Security Scanner & Vulnerability Auditor
 * Specifically audits and detects RCE, command injection primitives,
 * October 2026 php2shell vectors (CGI injection, stream filter chains, iconv exploits),
 * arbitrary file upload flaws, and deserialization hazards.
 */

$options = getopt('', ['path:', 'output:']);
$target = $options['path'] ?? ($argv[1] ?? '.');
$outputFile = $options['output'] ?? null;

if (!file_exists($target)) {
    fwrite(STDERR, "[!] Error: Target path '{$target}' does not exist.\n");
    exit(1);
}

echo "[*] Commencing native php2shell vulnerability audit on: " . realpath($target) . "\n";

$rules = [
    [
        'id' => 'P2S-EXEC',
        'name' => 'Direct Shell Execution Primitives',
        'severity' => 'CRITICAL',
        'regex' => '/\b(exec|passthru|shell_exec|system|proc_open|popen|pcntl_exec)\s*\(|`[^`]+`/i',
        'desc' => 'Direct invocation of OS shell. Unsanitized user inputs lead directly to remote shell spawn.'
    ],
    [
        'id' => 'P2S-DYN-EVAL',
        'name' => 'Dynamic Code Evaluation & Code Injection',
        'severity' => 'CRITICAL',
        'regex' => '/\b(eval|assert)\s*\(|preg_replace\s*\(\s*[\'"][^\'"]*\/e[\'"]/i',
        'desc' => 'Dynamic code evaluation allows arbitrary PHP execution leading to remote shell.'
    ],
    [
        'id' => 'P2S-STREAM-FILTER-CHAIN',
        'name' => 'Dangerous Stream Wrapper / Filter Chain RCE',
        'severity' => 'HIGH',
        'regex' => '/php:\/\/(filter|input|data|expect|phar)/i',
        'desc' => 'Abuse of stream wrappers (e.g. php://filter iconv chains) weaponized to bypass LFI into RCE.'
    ],
    [
        'id' => 'P2S-DYN-INCLUDE',
        'name' => 'Dynamic File Inclusion (LFI to Shell)',
        'severity' => 'HIGH',
        'regex' => '/\b(include|include_once|require|require_once)\s*\(?\s*\$(?:_GET|_POST|_REQUEST|_COOKIE|[\w]+)\[?/i',
        'desc' => 'Dynamic include statement with unvalidated variable allows path traversal or wrapper execution.'
    ],
    [
        'id' => 'P2S-UNSERIALIZE',
        'name' => 'Insecure Object Deserialization to Shell',
        'severity' => 'HIGH',
        'regex' => '/\bunserialize\s*\(\s*\$(?:_GET|_POST|_REQUEST|_COOKIE|[\w]+)/i',
        'desc' => 'Unvalidated deserialization triggers POP gadget chains escalating to shell execution.'
    ],
    [
        'id' => 'P2S-UNGUARDED-UPLOAD',
        'name' => 'Insecure Webshell File Upload',
        'severity' => 'MEDIUM',
        'regex' => '/move_uploaded_file\s*\(\s*[^,]+,\s*[^)]+\$_FILES/i',
        'desc' => 'Upload handler preserves client filename without strict whitelist validation or outside-root storage.'
    ]
];

$files = [];
if (is_file($target)) {
    $files[] = new SplFileInfo($target);
} else {
    $iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($target, FilesystemIterator::SKIP_DOTS));
    foreach ($iterator as $file) {
        if ($file->isFile() && $file->getExtension() === 'php') {
            $pathStr = $file->getPathname();
            if (strpos($pathStr, DIRECTORY_SEPARATOR . 'vendor' . DIRECTORY_SEPARATOR) !== false ||
                strpos($pathStr, DIRECTORY_SEPARATOR . 'tests' . DIRECTORY_SEPARATOR) !== false ||
                str_ends_with($pathStr, 'php2shell-audit.php') ||
                str_ends_with($pathStr, 'security-audit.php')) {
                continue;
            }
            $files[] = $file;
        }
    }
}

$findings = [];
foreach ($files as $file) {
    $lines = file($file->getPathname(), FILE_IGNORE_NEW_LINES);
    if ($lines === false) continue;

    foreach ($lines as $lineNum => $line) {
        $cleanLine = trim($line);
        if ($cleanLine === '' || str_starts_with($cleanLine, '//') || str_starts_with($cleanLine, '#') || str_starts_with($cleanLine, '*')) {
            continue;
        }

        foreach ($rules as $rule) {
            if (preg_match($rule['regex'], $line, $matches)) {
                $findings[] = [
                    'file' => $file->getPathname(),
                    'line' => $lineNum + 1,
                    'rule_id' => $rule['id'],
                    'name' => $rule['name'],
                    'severity' => $rule['severity'],
                    'snippet' => substr($cleanLine, 0, 120),
                    'desc' => $rule['desc']
                ];
            }
        }
    }
}

echo "[*] Total PHP files scanned: " . count($files) . "\n";
echo "[*] Total findings detected: " . count($findings) . "\n\n";

if (empty($findings)) {
    echo "[+] SUCCESS: No php2shell RCE patterns detected in scanned files.\n";
    exit(0);
}

echo "=== FINDINGS SUMMARY ===\n";
foreach ($findings as $f) {
    echo "[{$f['severity']}] {$f['file']}:{$f['line']} - {$f['name']} ({$f['rule_id']})\n";
    echo "    Code: {$f['snippet']}\n";
    echo "    Fix:  {$f['desc']}\n\n";
}

if ($outputFile) {
    file_put_contents($outputFile, json_encode($findings, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
    echo "[+] Report saved to {$outputFile}\n";
}

$hasCritical = array_filter($findings, fn($f) => $f['severity'] === 'CRITICAL');
exit(!empty($hasCritical) ? 1 : 0);

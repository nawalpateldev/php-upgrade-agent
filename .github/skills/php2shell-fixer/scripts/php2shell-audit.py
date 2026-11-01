#!/usr/bin/env python3
"""
PHP2Shell SAST Security Scanner & Vulnerability Auditor
Detects RCE, command injection, stream filter chains, CGI argument injection vectors,
and arbitrary file upload flaws in PHP applications.
"""

import os
import re
import sys
import argparse
from pathlib import Path

# High-risk patterns
RULES = [
    {
        "id": "P2S-EXEC",
        "name": "Direct Shell Execution Primitives",
        "severity": "CRITICAL",
        "regex": re.compile(r'\b(exec|passthru|shell_exec|system|proc_open|popen|pcntl_exec)\s*\(|`[^`]+`', re.IGNORECASE),
        "desc": "Direct invocation of OS command execution function. Unsanitized parameters enable immediate shell access."
    },
    {
        "id": "P2S-DYN-EVAL",
        "name": "Dynamic Code Evaluation",
        "severity": "CRITICAL",
        "regex": re.compile(r'\b(eval|assert)\s*\(|preg_replace\s*\(\s*[\'"][^\'"]*\/e[\'"]', re.IGNORECASE),
        "desc": "Dynamic execution of code strings allows arbitrary PHP code injection leading to shell."
    },
    {
        "id": "P2S-STREAM-WRAPPER",
        "name": "Dangerous Stream Wrapper / Filter Chain Exposure",
        "severity": "HIGH",
        "regex": re.compile(r'php:\/\/(filter|input|data|expect|phar)', re.IGNORECASE),
        "desc": "Explicit reference to internal stream wrappers often weaponized in filter chain RCE attacks."
    },
    {
        "id": "P2S-DYN-INCLUDE",
        "name": "Dynamic File Inclusion (LFI/RFI to Shell)",
        "severity": "HIGH",
        "regex": re.compile(r'\b(include|include_once|require|require_once)\s*\(?\s*\$(?:_GET|_POST|_REQUEST|_COOKIE|[\w]+)\[?', re.IGNORECASE),
        "desc": "Dynamic include statement taking user-controllable input; can be leveraged with filter chains or upload files to gain shell."
    },
    {
        "id": "P2S-UNSERIALIZE",
        "name": "Insecure Object Deserialization",
        "severity": "HIGH",
        "regex": re.compile(r'\bunserialize\s*\(\s*\$(?:_GET|_POST|_REQUEST|_COOKIE|[\w]+)', re.IGNORECASE),
        "desc": "Unchecked deserialization of untrusted input allows POP gadget chains to escalate to RCE."
    },
    {
        "id": "P2S-UNGUARDED-UPLOAD",
        "name": "Potentially Insecure File Upload Handling",
        "severity": "MEDIUM",
        "regex": re.compile(r'move_uploaded_file\s*\(\s*[^,]+,\s*[^)]+\$_FILES', re.IGNORECASE),
        "desc": "File upload preserving client-supplied filename without strict whitelist validation may allow webshell drop."
    }
]

def scan_file(filepath: Path):
    findings = []
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
            for line_idx, line in enumerate(lines, start=1):
                clean_line = line.strip()
                if clean_line.startswith('//') or clean_line.startswith('*') or clean_line.startswith('#'):
                    continue
                for rule in RULES:
                    match = rule["regex"].search(line)
                    if match:
                        findings.append({
                            "file": str(filepath),
                            "line": line_idx,
                            "rule_id": rule["id"],
                            "name": rule["name"],
                            "severity": rule["severity"],
                            "desc": rule["desc"],
                            "snippet": line.strip()[:120]
                        })
    except Exception as e:
        pass
    return findings

def main():
    parser = argparse.ArgumentParser(description="PHP2Shell SAST Security Scanner")
    parser.add_argument("--path", required=True, help="Directory or file path to scan")
    parser.add_argument("--output", help="Optional report file destination")
    args = parser.parse_args()

    target_path = Path(args.path)
    if not target_path.exists():
        print(f"[!] Path does not exist: {target_path}", file=sys.stderr)
        sys.exit(1)

    print(f"[*] Commencing php2shell security audit on: {target_path.resolve()}")
    all_findings = []

    if target_path.is_file():
        files = [target_path]
    else:
        files = [
            p for p in target_path.rglob("*.php") 
            if "vendor" not in p.parts and "tests" not in p.parts 
            and not p.name.endswith("php2shell-audit.py")
            and not p.name.endswith("php2shell-audit.php")
            and not p.name.endswith("security-audit.php")
        ]

    for f in files:
        results = scan_file(f)
        all_findings.extend(results)

    print(f"[*] Files scanned: {len(files)}")
    print(f"[*] Findings detected: {len(all_findings)}")

    if not all_findings:
        print("[+] SUCCESS: No php2shell RCE patterns identified.")
        sys.exit(0)

    print("\n--- FINDINGS SUMMARY ---")
    for item in all_findings:
        print(f"[{item['severity']}] {item['file']}:{item['line']} - {item['name']} ({item['rule_id']})")
        print(f"    Code: {item['snippet']}")
        print(f"    Remediation: {item['desc']}\n")

    if args.output:
        import json
        with open(args.output, 'w', encoding='utf-8') as out:
            json.dump(all_findings, out, indent=2)
        print(f"[+] Detailed report exported to {args.output}")

    sys.exit(1 if any(f['severity'] == 'CRITICAL' for f in all_findings) else 0)

if __name__ == "__main__":
    main()

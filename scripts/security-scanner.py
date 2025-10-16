#!/usr/bin/env python3
"""
StarkPay Security Scanner - BON-013 Compliance Tool
Comprehensive security audit script to detect exposed secrets, keys, and credentials
"""

import os
import re
import json
import hashlib
import datetime
from pathlib import Path
from typing import List, Dict, Set, Any
import subprocess

class SecurityScanner:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.findings = []
        self.scan_timestamp = datetime.datetime.now().isoformat()
        
        # Comprehensive patterns for detecting secrets
        self.secret_patterns = {
            'api_key': [
                r'["\']?api[_-]?key["\']?\s*[:=]\s*["\']?([a-zA-Z0-9_\-]{20,})["\']?',
                r'["\']?apikey["\']?\s*[:=]\s*["\']?([a-zA-Z0-9_\-]{20,})["\']?',
                r'API[_-]?KEY\s*[:=]\s*["\']?([a-zA-Z0-9_\-]{20,})["\']?'
            ],
            'secret_key': [
                r'["\']?secret[_-]?key["\']?\s*[:=]\s*["\']?([a-zA-Z0-9_\-]{20,})["\']?',
                r'["\']?secretkey["\']?\s*[:=]\s*["\']?([a-zA-Z0-9_\-]{20,})["\']?',
                r'SECRET[_-]?KEY\s*[:=]\s*["\']?([a-zA-Z0-9_\-]{20,})["\']?'
            ],
            'password': [
                r'["\']?password["\']?\s*[:=]\s*["\']?([^"\'\s]{8,})["\']?',
                r'["\']?passwd["\']?\s*[:=]\s*["\']?([^"\'\s]{8,})["\']?',
                r'PASSWORD\s*[:=]\s*["\']?([^"\'\s]{8,})["\']?'
            ],
            'token': [
                r'["\']?token["\']?\s*[:=]\s*["\']?([a-zA-Z0-9_\-\.]{20,})["\']?',
                r'["\']?auth[_-]?token["\']?\s*[:=]\s*["\']?([a-zA-Z0-9_\-\.]{20,})["\']?',
                r'TOKEN\s*[:=]\s*["\']?([a-zA-Z0-9_\-\.]{20,})["\']?'
            ],
            'private_key': [
                r'-----BEGIN\s+(?:RSA\s+)?PRIVATE\s+KEY-----',
                r'["\']?private[_-]?key["\']?\s*[:=]\s*["\']?([a-zA-Z0-9_\-\.]{40,})["\']?'
            ],
            'aws_key': [
                r'AKIA[0-9A-Z]{16}',
                r'aws[_-]?access[_-]?key[_-]?id\s*[:=]\s*["\']?(AKIA[0-9A-Z]{16})["\']?'
            ],
            'database_url': [
                r'["\']?database[_-]?url["\']?\s*[:=]\s*["\']?(.*://.*)["\']?',
                r'["\']?db[_-]?url["\']?\s*[:=]\s*["\']?(.*://.*)["\']?'
            ],
            'webhook_url': [
                r'https://hooks\.slack\.com/services/[A-Z0-9/]+',
                r'https://discord\.com/api/webhooks/[0-9]+/[a-zA-Z0-9_\-]+'
            ],
            'crypto_private_key': [
                r'["\']?private[_-]?key["\']?\s*[:=]\s*["\']?0x[a-fA-F0-9]{64}["\']?',
                r'["\']?privkey["\']?\s*[:=]\s*["\']?0x[a-fA-F0-9]{64}["\']?'
            ],
            'mnemonic': [
                r'["\']?mnemonic["\']?\s*[:=]\s*["\']?([a-z]+\s+){11,23}[a-z]+["\']?',
                r'["\']?seed[_-]?phrase["\']?\s*[:=]\s*["\']?([a-z]+\s+){11,23}[a-z]+["\']?'
            ]
        }
        
        # File extensions to scan
        self.scan_extensions = {'.swift', '.m', '.h', '.plist', '.json', '.xml', '.txt', 
                               '.md', '.yml', '.yaml', '.sh', '.py', '.js', '.ts'}
        
        # Files to always exclude
        self.exclude_patterns = {
            r'\.git/',
            r'\.DS_Store',
            r'\.xcuserdata/',
            r'\.xcassets/',
            r'DerivedData/',
            r'Pods/',
            r'node_modules/',
            r'\.build/',
            r'coverage/',
            r'__pycache__/',
            r'\.pyc$'
        }

    def should_scan_file(self, file_path: Path) -> bool:
        """Determine if a file should be scanned"""
        # Check file extension
        if file_path.suffix not in self.scan_extensions:
            return False
            
        # Check exclude patterns
        relative_path = file_path.relative_to(self.project_root)
        for pattern in self.exclude_patterns:
            if re.search(pattern, str(relative_path)):
                return False
                
        # Check file size (skip very large files)
        try:
            if file_path.stat().st_size > 10 * 1024 * 1024:  # 10MB
                return False
        except OSError:
            return False
            
        return True

    def scan_file(self, file_path: Path) -> List[Dict[str, Any]]:
        """Scan a single file for secrets"""
        findings = []
        
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                lines = content.split('\n')
                
            for line_num, line in enumerate(lines, 1):
                for category, patterns in self.secret_patterns.items():
                    for pattern in patterns:
                        matches = re.finditer(pattern, line, re.IGNORECASE)
                        for match in matches:
                            finding = {
                                'file': str(file_path.relative_to(self.project_root)),
                                'line': line_num,
                                'category': category,
                                'pattern': pattern,
                                'match': match.group(0),
                                'context': line.strip(),
                                'severity': self.get_severity(category),
                                'confidence': self.get_confidence(category, match.group(0))
                            }
                            findings.append(finding)
                            
        except Exception as e:
            print(f"Error scanning {file_path}: {e}")
            
        return findings

    def get_severity(self, category: str) -> str:
        """Get severity level for a category"""
        high_severity = {'private_key', 'secret_key', 'aws_key', 'crypto_private_key', 'mnemonic'}
        medium_severity = {'api_key', 'token', 'database_url', 'webhook_url'}
        
        if category in high_severity:
            return 'HIGH'
        elif category in medium_severity:
            return 'MEDIUM'
        else:
            return 'LOW'

    def get_confidence(self, category: str, match: str) -> str:
        """Get confidence level for a match"""
        # Check for common test/dummy values
        dummy_values = {
            'test', 'dummy', 'fake', 'mock', 'example', 'placeholder',
            'your_key_here', 'insert_key_here', 'replace_me'
        }
        
        if any(dummy in match.lower() for dummy in dummy_values):
            return 'LOW'
        
        # Check length and complexity
        if len(match) < 10:
            return 'LOW'
        elif len(match) > 40 and any(c.isdigit() for c in match) and any(c.isalpha() for c in match):
            return 'HIGH'
        else:
            return 'MEDIUM'

    def scan_project(self) -> None:
        """Scan the entire project"""
        print(f"🔍 Starting security scan of: {self.project_root}")
        print(f"📅 Scan timestamp: {self.scan_timestamp}")
        
        scanned_files = 0
        
        for root, dirs, files in os.walk(self.project_root):
            # Remove excluded directories from dirs to avoid walking into them
            dirs[:] = [d for d in dirs if not any(re.search(pattern, d) for pattern in self.exclude_patterns)]
            
            for file in files:
                file_path = Path(root) / file
                
                if self.should_scan_file(file_path):
                    scanned_files += 1
                    file_findings = self.scan_file(file_path)
                    self.findings.extend(file_findings)
        
        print(f"📁 Scanned {scanned_files} files")
        print(f"🚨 Found {len(self.findings)} potential security issues")

    def generate_report(self) -> Dict[str, Any]:
        """Generate a comprehensive security report"""
        # Categorize findings
        by_severity = {'HIGH': [], 'MEDIUM': [], 'LOW': []}
        by_category = {}
        by_file = {}
        
        for finding in self.findings:
            # By severity
            by_severity[finding['severity']].append(finding)
            
            # By category
            if finding['category'] not in by_category:
                by_category[finding['category']] = []
            by_category[finding['category']].append(finding)
            
            # By file
            if finding['file'] not in by_file:
                by_file[finding['file']] = []
            by_file[finding['file']].append(finding)
        
        report = {
            'scan_info': {
                'timestamp': self.scan_timestamp,
                'project_root': str(self.project_root),
                'total_findings': len(self.findings)
            },
            'summary': {
                'high_severity': len(by_severity['HIGH']),
                'medium_severity': len(by_severity['MEDIUM']),
                'low_severity': len(by_severity['LOW'])
            },
            'findings_by_severity': by_severity,
            'findings_by_category': by_category,
            'findings_by_file': by_file,
            'detailed_findings': self.findings
        }
        
        return report

    def save_report(self, output_path: str) -> None:
        """Save the security report to a file"""
        report = self.generate_report()
        
        with open(output_path, 'w') as f:
            json.dump(report, f, indent=2, default=str)
        
        print(f"💾 Security report saved to: {output_path}")

    def print_summary(self) -> None:
        """Print a summary of findings"""
        report = self.generate_report()
        
        print("\n" + "="*80)
        print("🔒 STARKPAY SECURITY AUDIT SUMMARY")
        print("="*80)
        print(f"📊 Total findings: {report['scan_info']['total_findings']}")
        print(f"🚨 High severity: {report['summary']['high_severity']}")
        print(f"⚠️  Medium severity: {report['summary']['medium_severity']}")
        print(f"ℹ️  Low severity: {report['summary']['low_severity']}")
        
        if report['summary']['high_severity'] > 0:
            print(f"\n🚨 HIGH SEVERITY ISSUES:")
            for finding in report['findings_by_severity']['HIGH']:
                print(f"  - {finding['file']}:{finding['line']} - {finding['category']}")
        
        if report['summary']['medium_severity'] > 0:
            print(f"\n⚠️  MEDIUM SEVERITY ISSUES:")
            for finding in report['findings_by_severity']['MEDIUM']:
                print(f"  - {finding['file']}:{finding['line']} - {finding['category']}")
        
        print("="*80)

def main():
    import sys
    
    if len(sys.argv) > 1:
        project_root = sys.argv[1]
    else:
        project_root = os.getcwd()
    
    scanner = SecurityScanner(project_root)
    scanner.scan_project()
    scanner.print_summary()
    
    # Save detailed report
    report_path = os.path.join(project_root, 'security-audit-report.json')
    scanner.save_report(report_path)

if __name__ == '__main__':
    main()
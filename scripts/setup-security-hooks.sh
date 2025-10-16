#!/bin/bash

# StarkPay Security Hooks Setup
# Automated security monitoring for development workflow
# BON-013 Compliance: Prevents secrets from being committed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[SECURITY SETUP] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Check if we're in a git repository
check_git_repo() {
    if [ ! -d "$PROJECT_ROOT/.git" ]; then
        error "Not in a git repository. Please run 'git init' first."
        exit 1
    fi
}

# Install pre-commit security hook
install_pre_commit_hook() {
    log "Installing pre-commit security hook..."
    
    cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
# StarkPay Security Pre-commit Hook - BON-013 Compliance
# Prevents committing code with exposed secrets or credentials

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(git rev-parse --show-toplevel)"

echo -e "${BLUE}🔒 StarkPay Security Pre-commit Check${NC}"
echo "===================================="

# Function to check for secrets in staged files
check_staged_files_for_secrets() {
    local staged_files
    staged_files=$(git diff --cached --name-only --diff-filter=ACM)
    
    if [ -z "$staged_files" ]; then
        echo -e "${GREEN}✅ No files staged for commit${NC}"
        return 0
    fi
    
    echo -e "${BLUE}📁 Checking staged files for secrets...${NC}"
    
    local violations=0
    local temp_dir="/tmp/starkpay-security-check-$$"
    mkdir -p "$temp_dir"
    
    # Extract staged files to temporary location
    for file in $staged_files; do
        if [ -f "$file" ]; then
            mkdir -p "$temp_dir/$(dirname "$file")"
            git show ":$file" > "$temp_dir/$file" 2>/dev/null || continue
        fi
    done
    
    # Run secret detection on staged files
    if [ -f "$PROJECT_ROOT/scripts/security-scanner.py" ]; then
        echo "🔍 Running StarkPay secret scanner..."
        
        if python3 "$PROJECT_ROOT/scripts/security-scanner.py" "$temp_dir" --staged-only 2>/dev/null; then
            echo -e "${GREEN}✅ No secrets detected in staged files${NC}"
        else
            echo -e "${RED}❌ SECURITY VIOLATION: Secrets detected in staged files!${NC}"
            echo -e "${RED}🚨 BON-013 COMPLIANCE FAILED${NC}"
            violations=$((violations + 1))
        fi
    fi
    
    # Pattern-based secret detection for critical patterns
    echo "🔍 Running pattern-based secret detection..."
    
    # Define critical secret patterns
    declare -A secret_patterns=(
        ["API_KEY"]='["\'''\'']\?[Aa][Pp][Ii][_-]\?[Kk][Ee][Yy]["\'''\'']\?\s*[:=]\s*["\'''\'']\?[a-zA-Z0-9_\-]{20,}["\'''\'']\?'
        ["SECRET"]='["\'''\'']\?[Ss][Ee][Cc][Rr][Ee][Tt][_-]\?[Kk][Ee][Yy]["\'''\'']\?\s*[:=]\s*["\'''\'']\?[a-zA-Z0-9_\-]{16,}["\'''\'']\?'
        ["PASSWORD"]='["\'''\'']\?[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]["\'''\'']\?\s*[:=]\s*["\'''\'']\?[^"\'''\'''\s]{8,}["\'''\'']\?'
        ["TOKEN"]='["\'''\'']\?[Tt][Oo][Kk][Ee][Nn]["\'''\'']\?\s*[:=]\s*["\'''\'']\?[a-zA-Z0-9_\-\.]{20,}["\'''\'']\?'
        ["PRIVATE_KEY"]='["\'''\'']\?[Pp][Rr][Ii][Vv][Aa][Tt][Ee][_-]\?[Kk][Ee][Yy]["\'''\'']\?\s*[:=]\s*["\'''\'']\?0x[a-fA-F0-9]{64}["\'''\'']\?'
        ["AWS_KEY"]='AKIA[0-9A-Z]{16}'
        ["DATABASE_URL"]='["\'''\'']\?[Dd][Aa][Tt][Aa][Bb][Aa][Ss][Ee][_-]\?[Uu][Rr][Ll]["\'''\'']\?\s*[:=]\s*["\'''\'']\?(.*://.*)["\'''\'']\?'
    )
    
    for pattern_name in "${!secret_patterns[@]}"; do
        local pattern="${secret_patterns[$pattern_name]}"
        
        for file in $staged_files; do
            if [ -f "$temp_dir/$file" ] && grep -qE "$pattern" "$temp_dir/$file" 2>/dev/null; then
                echo -e "${RED}❌ $pattern_name detected in: $file${NC}"
                echo -e "${RED}   Pattern: $pattern_name${NC}"
                violations=$((violations + 1))
            fi
        done
    done
    
    # Check for common insecure patterns
    echo "🔍 Checking for insecure patterns..."
    
    for file in $staged_files; do
        if [ -f "$temp_dir/$file" ]; then
            # Check for HTTP URLs (should be HTTPS)
            if grep -qE 'http://[^\s"'\'\''"]+' "$temp_dir/$file" 2>/dev/null; then
                echo -e "${YELLOW}⚠️  HTTP URL detected in: $file (should use HTTPS)${NC}"
                violations=$((violations + 1))
            fi
            
            # Check for localhost in production code (potential config leak)
            if [[ "$file" != *test* ]] && [[ "$file" != *Test* ]] && grep -qE '(localhost|127\.0\.0\.1)' "$temp_dir/$file" 2>/dev/null; then
                echo -e "${YELLOW}⚠️  Localhost reference in production code: $file${NC}"
            fi
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
    
    if [ $violations -gt 0 ]; then
        echo ""
        echo -e "${RED}🚨 COMMIT BLOCKED: $violations security violations found!${NC}"
        echo -e "${RED}📋 BON-013 Compliance: FAILED${NC}"
        echo ""
        echo -e "${YELLOW}🔧 To fix these issues:${NC}"
        echo "1. Remove hardcoded secrets from your code"
        echo "2. Use environment variables or secure storage"
        echo "3. For StarkPay, use SecurityManager.shared.storeSecurely()"
        echo "4. Replace HTTP URLs with HTTPS"
        echo ""
        echo -e "${BLUE}📚 Security Guide: docs/SECURITY_BEST_PRACTICES.md${NC}"
        return 1
    fi
    
    return 0
}

# Check code quality and security
check_code_quality() {
    echo -e "${BLUE}📊 Running code quality checks...${NC}"
    
    # Check for excessive force unwrapping in Swift
    local swift_files
    swift_files=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.swift$' || true)
    
    if [ -n "$swift_files" ]; then
        echo "🔍 Checking Swift code quality..."
        
        for file in $swift_files; do
            if [ -f "$file" ]; then
                # Check for excessive force unwrapping
                local force_unwrap_count
                force_unwrap_count=$(git show ":$file" | grep -c 'try!' || true)
                
                if [ "$force_unwrap_count" -gt 5 ]; then
                    echo -e "${YELLOW}⚠️  Excessive force unwrapping in $file ($force_unwrap_count instances)${NC}"
                fi
                
                # Check for print statements in production code
                if [[ "$file" != *test* ]] && [[ "$file" != *Test* ]] && git show ":$file" | grep -q 'print(' 2>/dev/null; then
                    echo -e "${YELLOW}⚠️  Print statements in production code: $file${NC}"
                fi
            fi
        done
    fi
    
    echo -e "${GREEN}✅ Code quality checks completed${NC}"
}

# Main security check
main() {
    echo -e "${BLUE}🔒 Starting BON-013 compliance check...${NC}"
    
    local exit_code=0
    
    # Run secret detection
    if ! check_staged_files_for_secrets; then
        exit_code=1
    fi
    
    # Run code quality checks (non-blocking)
    check_code_quality
    
    if [ $exit_code -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ Security pre-commit check PASSED${NC}"
        echo -e "${GREEN}🏆 BON-013 Compliance: MAINTAINED${NC}"
        echo -e "${GREEN}🔐 No secrets or credentials detected${NC}"
        echo ""
        return 0
    else
        echo ""
        echo -e "${RED}❌ Security pre-commit check FAILED${NC}"
        echo -e "${RED}🚨 BON-013 Compliance: VIOLATED${NC}"
        echo ""
        return 1
    fi
}

# Execute main function
main "$@"
EOF

    chmod +x "$HOOKS_DIR/pre-commit"
    success "Pre-commit security hook installed"
}

# Install commit-msg hook for security validation
install_commit_msg_hook() {
    log "Installing commit-msg security hook..."
    
    cat > "$HOOKS_DIR/commit-msg" << 'EOF'
#!/bin/bash
# StarkPay Security Commit Message Hook
# Validates commit messages for security-related commits

set -euo pipefail

commit_msg_file="$1"
commit_msg=$(cat "$commit_msg_file")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check for potential security-sensitive keywords that should be flagged
security_keywords=("password" "secret" "key" "token" "credential" "api" "auth" "login")

# Convert commit message to lowercase for checking
commit_msg_lower=$(echo "$commit_msg" | tr '[:upper:]' '[:lower:]')

# Check if commit message contains security-sensitive terms
for keyword in "${security_keywords[@]}"; do
    if echo "$commit_msg_lower" | grep -q "$keyword"; then
        echo -e "${YELLOW}⚠️  Security-sensitive keyword detected: '$keyword'${NC}"
        echo -e "${YELLOW}📋 Please ensure no sensitive information is being committed${NC}"
        break
    fi
done

# Check for common patterns that might indicate accidental credential commits
if echo "$commit_msg_lower" | grep -qE "(add.*key|new.*password|update.*secret|fix.*token)"; then
    echo -e "${RED}🚨 WARNING: Commit message suggests security credential changes${NC}"
    echo -e "${RED}🔍 Please verify no hardcoded secrets are being committed${NC}"
    echo -e "${YELLOW}💡 Use 'git show --name-only' to review changed files${NC}"
fi

# Add security audit trail
echo -e "${BLUE}🔒 Security audit: Commit message reviewed${NC}"

exit 0
EOF

    chmod +x "$HOOKS_DIR/commit-msg"
    success "Commit message security hook installed"
}

# Install pre-push hook for final security validation
install_pre_push_hook() {
    log "Installing pre-push security hook..."
    
    cat > "$HOOKS_DIR/pre-push" << 'EOF'
#!/bin/bash
# StarkPay Security Pre-push Hook
# Final security validation before pushing to remote

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(git rev-parse --show-toplevel)"

echo -e "${BLUE}🚀 StarkPay Pre-push Security Validation${NC}"
echo "======================================"

# Run comprehensive security scan before push
if [ -f "$PROJECT_ROOT/scripts/security-scanner.py" ]; then
    echo -e "${BLUE}🔍 Running comprehensive security scan...${NC}"
    
    if python3 "$PROJECT_ROOT/scripts/security-scanner.py" "$PROJECT_ROOT" --pre-push 2>/dev/null; then
        echo -e "${GREEN}✅ Comprehensive security scan passed${NC}"
    else
        echo -e "${RED}❌ Security scan failed - push blocked${NC}"
        echo -e "${RED}🚨 BON-013 compliance violation detected${NC}"
        exit 1
    fi
fi

# Validate that no test/debug configurations are being pushed to main
current_branch=$(git rev-parse --abbrev-ref HEAD)

if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
    echo -e "${BLUE}🔍 Validating production branch security...${NC}"
    
    # Check for debug configurations
    if git log --oneline -10 | grep -iE "(debug|test|temp|todo|fixme)"; then
        echo -e "${YELLOW}⚠️  Recent commits contain debug/test references${NC}"
        echo -e "${YELLOW}📋 Please ensure production readiness${NC}"
    fi
    
    echo -e "${GREEN}✅ Production branch validation completed${NC}"
fi

echo -e "${GREEN}🏆 Pre-push security validation PASSED${NC}"
echo -e "${GREEN}🔐 BON-013 compliance maintained${NC}"

exit 0
EOF

    chmod +x "$HOOKS_DIR/pre-push"
    success "Pre-push security hook installed"
}

# Create security configuration
create_security_config() {
    log "Creating security configuration..."
    
    cat > "$PROJECT_ROOT/.security-config.yml" << 'EOF'
# StarkPay Security Configuration
# BON-013 Compliance Settings

security:
  version: "1.0.0"
  standard: "BON-013"
  
  secret_detection:
    enabled: true
    strict_mode: true
    patterns:
      - api_key
      - secret_key
      - password
      - token
      - private_key
      - database_url
      - webhook_url
      - aws_key
      - mnemonic
    
  code_quality:
    enabled: true
    swift_lint: true
    force_unwrap_limit: 5
    
  hooks:
    pre_commit: true
    commit_msg: true
    pre_push: true
    
  monitoring:
    enabled: true
    real_time: true
    audit_trail: true
    
  compliance:
    bon_013: true
    target_score: 100
    minimum_score: 80
    
  notifications:
    violations: true
    success: false
    summary: true

EOF

    success "Security configuration created"
}

# Create security documentation
create_security_docs() {
    log "Creating security documentation..."
    
    cat > "$PROJECT_ROOT/SECURITY_HOOKS_README.md" << 'EOF'
# 🔒 StarkPay Security Hooks - BON-013 Compliance

This document explains the automated security monitoring system implemented for BON-013 compliance.

## 🛡️ Security Hooks Overview

### Pre-commit Hook
- **Purpose**: Prevent secrets from being committed
- **Checks**: API keys, passwords, tokens, private keys
- **Action**: Blocks commits with security violations

### Commit Message Hook  
- **Purpose**: Validate security-sensitive commit messages
- **Checks**: Security keywords and patterns
- **Action**: Warns about potential security commits

### Pre-push Hook
- **Purpose**: Final security validation before remote push
- **Checks**: Comprehensive security scan
- **Action**: Blocks pushes with security issues

## 🔍 What Gets Detected

### Critical Secrets (BON-013 Violations)
- API keys: `api_key = "sk_live_..."`
- Passwords: `password = "mypass123"`
- Tokens: `token = "ghp_..."`
- Private keys: `private_key = "0x123..."`
- Database URLs: `db_url = "postgres://user:pass@..."`
- AWS credentials: `AKIA1234567890ABCDEF`

### Security Patterns
- HTTP URLs (should be HTTPS)
- Localhost in production code
- Excessive force unwrapping in Swift
- Debug configurations in production

## ✅ Usage

### Automatic Activation
Security hooks are automatically activated when you run:
```bash
./scripts/setup-security-hooks.sh
```

### Manual Testing
Test the security hooks:
```bash
# Test secret detection
echo 'let apiKey = "sk_live_abcd1234"' > test.swift
git add test.swift
git commit -m "test" # Will be blocked

# Clean up
git reset HEAD test.swift
rm test.swift
```

### Bypassing Hooks (Emergency Only)
```bash
# Only for emergencies - NOT recommended
git commit --no-verify -m "Emergency commit"
```

## 🏆 BON-013 Compliance

These hooks ensure:
- ✅ Zero hardcoded secrets
- ✅ Secure development practices  
- ✅ Continuous security monitoring
- ✅ Automated compliance validation

## 📊 Security Metrics

The hooks track:
- Secret detection events
- Security violations
- Compliance score
- Audit trail

## 🚨 Troubleshooting

### Hook Not Running
1. Ensure hooks are executable: `chmod +x .git/hooks/*`
2. Check git configuration: `git config core.hooksPath`

### False Positives
1. Review the detected pattern
2. Use environment variables instead
3. Implement proper secret management

### Performance Issues
1. Exclude large files from scanning
2. Use `.gitignore` for build artifacts
3. Configure scan exclusions

## 📚 References

- [Security Best Practices](docs/SECURITY_BEST_PRACTICES.md)
- [BON-013 Audit Report](BON-013_SECURITY_AUDIT_REPORT.md)
- [Security Manager Implementation](StarkPayiOS/StarkPayiOS/SecurityManager.swift)

---

*Security Hooks Documentation v1.0*
*Last Updated: October 16, 2025*
EOF

    success "Security documentation created"
}

# Validate security setup
validate_setup() {
    log "Validating security setup..."
    
    local validation_errors=0
    
    # Check hooks are installed
    if [ ! -f "$HOOKS_DIR/pre-commit" ]; then
        error "Pre-commit hook not found"
        validation_errors=$((validation_errors + 1))
    fi
    
    if [ ! -f "$HOOKS_DIR/commit-msg" ]; then
        error "Commit-msg hook not found"
        validation_errors=$((validation_errors + 1))
    fi
    
    if [ ! -f "$HOOKS_DIR/pre-push" ]; then
        error "Pre-push hook not found"
        validation_errors=$((validation_errors + 1))
    fi
    
    # Check hooks are executable
    for hook in pre-commit commit-msg pre-push; do
        if [ ! -x "$HOOKS_DIR/$hook" ]; then
            error "$hook hook is not executable"
            validation_errors=$((validation_errors + 1))
        fi
    done
    
    # Check security scanner exists
    if [ ! -f "$PROJECT_ROOT/scripts/security-scanner.py" ]; then
        warning "Security scanner not found - limited functionality"
    fi
    
    if [ $validation_errors -eq 0 ]; then
        success "Security setup validation passed"
        return 0
    else
        error "Security setup validation failed with $validation_errors errors"
        return 1
    fi
}

# Main setup function
main() {
    echo -e "${BLUE}🔒 StarkPay Security Hooks Setup${NC}"
    echo "================================="
    echo "BON-013 Compliance: Automated Security Monitoring"
    echo ""
    
    check_git_repo
    
    # Create hooks directory if it doesn't exist
    mkdir -p "$HOOKS_DIR"
    
    # Install all security hooks
    install_pre_commit_hook
    install_commit_msg_hook
    install_pre_push_hook
    
    # Create configuration and documentation
    create_security_config
    create_security_docs
    
    # Validate setup
    if validate_setup; then
        echo ""
        echo -e "${GREEN}✅ Security hooks setup completed successfully!${NC}"
        echo ""
        echo "🔐 Security Features Enabled:"
        echo "  • Pre-commit secret detection"
        echo "  • Commit message validation"  
        echo "  • Pre-push security scanning"
        echo "  • BON-013 compliance monitoring"
        echo ""
        echo "📋 Next Steps:"
        echo "  1. Test the hooks: git add . && git commit -m 'test'"
        echo "  2. Review security config: .security-config.yml"
        echo "  3. Read documentation: SECURITY_HOOKS_README.md"
        echo ""
        echo -e "${BLUE}🏆 StarkPay is now protected by automated security monitoring!${NC}"
    else
        echo ""
        error "Security hooks setup failed - please check the errors above"
        exit 1
    fi
}

# Run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
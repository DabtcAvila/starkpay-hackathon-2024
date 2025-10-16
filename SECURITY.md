# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

StarkPay takes security vulnerabilities seriously. We appreciate your efforts to responsibly disclose your findings.

### How to Report

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: **security@starkpay.com**

### What to Include

Please provide the following information:
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Any suggested fixes or mitigations
- Your contact information for follow-up

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: 30 days for critical issues, 90 days for others

### Security Measures in StarkPay

#### Authentication & Authorization
- Biometric authentication (Face ID/Touch ID) using LocalAuthentication framework
- Secure token storage in iOS Keychain
- Session management with automatic timeout

#### Data Protection
- End-to-end encryption for sensitive data
- No sensitive data stored in UserDefaults or plain text
- Memory protection against debugging and runtime manipulation

#### Network Security
- HTTPS-only communication with certificate pinning
- API key management through secure storage
- Protection against man-in-the-middle attacks

#### Code Security
- No hardcoded secrets or API keys
- Regular security audits and dependency scanning
- Static code analysis integration

#### iOS-Specific Security
- App Transport Security (ATS) enabled
- Secure coding practices following OWASP guidelines
- Protection against reverse engineering

### Security Audit Results

Our latest security audit (October 2024) found:
- ✅ No exposed secrets or API keys
- ✅ Proper biometric authentication implementation
- ✅ Secure keychain integration
- ✅ HTTPS enforcement
- ✅ Memory protection measures

### Responsible Disclosure Program

We believe in responsible disclosure and will work with security researchers to:
1. Confirm the vulnerability
2. Determine the severity and impact
3. Develop and test a fix
4. Coordinate disclosure timeline
5. Publicly acknowledge contributors (with permission)

### Acknowledgments

We thank the following security researchers for their responsible disclosure:
- *[Currently none - first submission welcome!]*

### Contact Information

- **Security Team**: security@starkpay.com
- **General Contact**: hello@starkpay.com
- **GitHub**: https://github.com/DabtcAvila/starkpay-hackathon-2024

---

*This security policy was last updated on October 15, 2024.*
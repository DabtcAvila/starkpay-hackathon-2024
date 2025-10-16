# StarkPay iOS - Testing Documentation

## Overview

This document provides comprehensive information about the testing framework implemented for the StarkPay iOS application. Our testing strategy ensures code quality, security, and performance through multiple layers of testing.

## Testing Architecture

### Test Structure

```
StarkPayiOS/
├── StarkPayiOSTests/          # Unit Tests
│   ├── Unit Tests/
│   │   ├── BiometricAuthManagerTests.swift
│   │   ├── StarkPayViewModelTests.swift
│   │   └── HapticManagerTests.swift
│   ├── Mocks/
│   │   └── MockDataFramework.swift
│   └── Helpers/
│       └── TestHelpers.swift
├── StarkPayiOSUITests/        # UI and Integration Tests
│   ├── Authentication/
│   │   └── AuthenticationFlowTests.swift
│   ├── Payment Flows/
│   │   └── PaymentFlowTests.swift
│   ├── Performance/
│   │   └── PerformanceTests.swift
│   └── Security/
│       └── SecurityTests.swift
├── Scripts/
│   └── run-tests.sh           # Automated test runner
└── Documentation/
    └── TESTING.md             # This document
```

## Test Categories

### 1. Unit Tests (`StarkPayiOSTests`)

#### BiometricAuthManagerTests
- **Coverage**: Authentication logic, biometric types, error handling
- **Key Tests**:
  - Face ID/Touch ID/Optic ID authentication flows
  - Biometric availability detection
  - Error handling (lockout, cancellation, failure)
  - Settings persistence
  - Thread safety and performance

#### StarkPayViewModelTests
- **Coverage**: Business logic, data management, state transitions
- **Key Tests**:
  - Payment processing and validation
  - Transaction history management
  - Balance calculations
  - State management and observers
  - Data integrity and edge cases

#### HapticManagerTests
- **Coverage**: Haptic feedback system
- **Key Tests**:
  - All haptic feedback types
  - Performance and memory usage
  - Concurrent access patterns
  - Device compatibility

### 2. UI Tests (`StarkPayiOSUITests`)

#### AuthenticationFlowTests
- **Coverage**: User authentication experience
- **Key Tests**:
  - Splash to authentication transition
  - Biometric authentication UI
  - Passcode fallback flows
  - Error display and recovery
  - Accessibility compliance
  - Responsive design (portrait/landscape)

#### PaymentFlowTests
- **Coverage**: Payment processing user experience
- **Key Tests**:
  - Send payment form validation
  - Request payment functionality
  - Transaction history display
  - Input validation and error handling
  - Performance of payment operations

#### PerformanceTests
- **Coverage**: App performance and responsiveness
- **Key Tests**:
  - App launch time
  - Animation frame rates
  - Memory usage patterns
  - UI responsiveness
  - Network operation performance
  - Stress testing scenarios

#### SecurityTests
- **Coverage**: Security posture and attack resistance
- **Key Tests**:
  - App backgrounding security
  - Authentication bypass attempts
  - Memory security (sensitive data protection)
  - Screen recording/screenshot protection
  - Input validation security
  - Session management security

### 3. Mock Framework

#### MockDataFramework
- **Purpose**: Consistent, realistic test data generation
- **Components**:
  - `MockDataFactory`: Transaction and user data generation
  - `MockLAContext`: Biometric authentication simulation
  - `MockUserDefaults`: Settings persistence testing
  - `MockHapticFeedbackGenerator`: Haptic feedback verification
  - `MockNetworkLayer`: Network operation simulation

#### TestHelpers
- **Purpose**: Common testing utilities and environment setup
- **Features**:
  - Async testing utilities
  - SwiftUI testing helpers
  - Performance measurement tools
  - Memory leak detection
  - Error simulation

## Running Tests

### Command Line (Recommended)

```bash
# Run all tests
./Scripts/run-tests.sh

# Run specific test types
./Scripts/run-tests.sh --unit-only          # Unit tests only
./Scripts/run-tests.sh --ui-only            # UI tests only
./Scripts/run-tests.sh --performance-only   # Performance tests only
./Scripts/run-tests.sh --security-only      # Security tests only

# Custom device and options
./Scripts/run-tests.sh --device "iPhone 14 Pro" --no-coverage
```

### Xcode

1. **Unit Tests**: `Cmd+U` or Product → Test
2. **Individual Test Classes**: Right-click test class → Run
3. **Single Test Methods**: Click diamond icon next to test method

### Continuous Integration

Tests are automatically executed on:
- Push to `main` or `develop` branches
- Pull requests affecting iOS code
- Manual workflow dispatch

## Test Coverage

### Coverage Goals
- **Overall**: ≥80%
- **Core Business Logic**: ≥90%
- **Security Components**: ≥95%
- **UI Components**: ≥70%

### Coverage Reports

Coverage reports are generated in multiple formats:
- **Text**: `TestReports/coverage.txt`
- **JSON**: `TestReports/coverage.json`
- **HTML**: `TestReports/html/index.html` (requires genhtml)

#### Reading Coverage Reports

```bash
# View overall coverage
cat TestReports/coverage.txt | head -20

# Check specific file coverage
xcrun xccov view --file StarkPayiOS/BiometricAuthManager.swift TestReports/coverage.xccovreport
```

## Performance Testing

### Metrics Measured

1. **Launch Time**: App startup performance
2. **Memory Usage**: Peak and sustained memory consumption
3. **CPU Usage**: Processing efficiency during operations
4. **Animation Performance**: Frame rates and smoothness
5. **Network Performance**: Request/response times
6. **Storage I/O**: Data persistence performance

### Performance Thresholds

- **App Launch**: <2 seconds cold start
- **Authentication**: <1 second response time
- **Payment Processing**: <3 seconds end-to-end
- **Memory Growth**: <10MB per operation
- **Animation Frame Rate**: ≥60fps (≥90fps on Pro models)

### Performance Test Execution

```bash
# Run performance tests with detailed metrics
./Scripts/run-tests.sh --performance-only

# View performance results
open TestReports/PerformanceTests.xcresult
```

## Security Testing

### Security Test Categories

1. **Authentication Security**
   - Biometric bypass attempts
   - Session management
   - Authentication state isolation

2. **Data Protection**
   - Memory security (sensitive data handling)
   - Storage security (Keychain vs UserDefaults)
   - Screen recording/screenshot protection

3. **Input Validation**
   - SQL injection attempts
   - XSS prevention
   - Buffer overflow protection
   - Malicious input handling

4. **App Lifecycle Security**
   - Background/foreground transitions
   - App switcher privacy
   - Session timeout handling

### Security Test Execution

```bash
# Run security tests
./Scripts/run-tests.sh --security-only

# Security tests should NEVER be disabled in production builds
```

## Continuous Integration

### GitHub Actions Workflow

The CI pipeline (`/.github/workflows/ios-tests.yml`) includes:

1. **Parallel Test Execution**:
   - Unit tests (fast feedback)
   - UI tests (multiple devices)
   - Performance tests (benchmarking)
   - Security tests (compliance)

2. **Device Matrix Testing**:
   - iPhone 15 Pro (iOS 17.0)
   - iPhone 14 (iOS 16.4)
   - iPad Pro 12.9" (iOS 17.0)

3. **Automated Reporting**:
   - Test result publishing
   - Coverage reporting
   - Performance trend analysis
   - Security compliance verification

### CI Triggers

- **Push to main/develop**: Full test suite
- **Pull requests**: Full test suite with device matrix
- **Manual dispatch**: Configurable test types
- **Nightly**: Extended test suite with additional devices

## Best Practices

### Writing Tests

1. **Unit Tests**:
   - Test one thing at a time
   - Use descriptive test names
   - Follow Given-When-Then pattern
   - Mock external dependencies
   - Test edge cases and error conditions

2. **UI Tests**:
   - Use accessibility identifiers
   - Test real user workflows
   - Verify both happy path and error scenarios
   - Test on multiple devices/orientations

3. **Performance Tests**:
   - Set realistic thresholds
   - Measure consistently
   - Test under various conditions
   - Monitor trends over time

4. **Security Tests**:
   - Test actual attack vectors
   - Verify protection mechanisms
   - Test boundary conditions
   - Validate compliance requirements

### Test Maintenance

1. **Regular Updates**:
   - Update test data regularly
   - Refresh mock objects
   - Maintain device compatibility
   - Update performance baselines

2. **Code Review**:
   - Include tests in code review
   - Verify test coverage
   - Check test quality
   - Validate test scenarios

3. **Monitoring**:
   - Track test execution times
   - Monitor flaky tests
   - Review coverage trends
   - Analyze failure patterns

## Troubleshooting

### Common Issues

#### Test Simulator Issues
```bash
# Reset simulators
xcrun simctl erase all
xcrun simctl boot "iPhone 15 Pro"
```

#### Build Issues
```bash
# Clean derived data
rm -rf DerivedData/
xcodebuild clean

# Reset package cache
rm -rf ~/Library/Caches/org.swift.swiftpm/
```

#### Coverage Generation Issues
```bash
# Ensure code coverage is enabled
xcodebuild test -enableCodeCoverage YES

# Check for coverage files
find DerivedData -name "*.xccovreport" -type f
```

### Getting Help

1. **Documentation**: Check inline code documentation
2. **Test Logs**: Review `TestReports/TestResults/*.log`
3. **CI Logs**: Check GitHub Actions workflow logs
4. **Local Debugging**: Use Xcode's test navigator and debugger

## Contributing

### Adding New Tests

1. **Unit Tests**:
   - Add to appropriate test class in `StarkPayiOSTests/`
   - Use existing mock framework
   - Follow naming conventions
   - Update test documentation

2. **UI Tests**:
   - Add to appropriate test class in `StarkPayiOSUITests/`
   - Use accessibility identifiers
   - Test on multiple devices
   - Consider performance impact

3. **Mock Data**:
   - Extend `MockDataFramework.swift`
   - Maintain data consistency
   - Add edge case scenarios
   - Document mock behavior

### Test Review Checklist

- [ ] Tests have clear, descriptive names
- [ ] Tests are properly categorized
- [ ] Mock dependencies are used appropriately
- [ ] Edge cases and error conditions are tested
- [ ] Performance impact is considered
- [ ] Security implications are addressed
- [ ] Documentation is updated
- [ ] CI pipeline passes

## Metrics and Reporting

### Test Metrics Dashboard

Key metrics tracked:
- **Test Execution Time**: Per test suite
- **Test Success Rate**: Historical trend
- **Code Coverage**: Per module and overall
- **Performance Benchmarks**: Trend analysis
- **Security Compliance**: Pass/fail status

### Reports Generated

1. **Test Results**: JUnit XML for CI integration
2. **Coverage Reports**: Multiple formats for analysis
3. **Performance Reports**: Benchmark comparisons
4. **Security Reports**: Compliance verification
5. **Summary Reports**: Executive dashboard format

---

## Test Execution Examples

### Quick Start

```bash
# Clone and setup
git clone <repository-url>
cd StarkPayiOS

# Run basic test suite
chmod +x Scripts/run-tests.sh
./Scripts/run-tests.sh --unit-only

# View results
open TestReports/test_summary.md
```

### Full Test Suite

```bash
# Complete testing with coverage
./Scripts/run-tests.sh

# Review all reports
open TestReports/
open TestReports/html/index.html  # Coverage report
```

### CI Integration

```bash
# Local CI simulation
act -j unit-tests  # Requires act (GitHub Actions local runner)

# Or use GitHub Actions
git push origin feature-branch  # Triggers CI
```

This comprehensive testing framework ensures that StarkPay iOS maintains high quality, security, and performance standards throughout the development lifecycle.
#!/bin/bash

# StarkPay iOS - Automated Test Execution Script
# Comprehensive test runner with coverage reports and CI integration

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCHEME="StarkPayiOS"
PROJECT_NAME="StarkPayiOS"
DERIVED_DATA_PATH="$PWD/DerivedData"
COVERAGE_REPORTS_PATH="$PWD/TestReports"
TEST_RESULTS_PATH="$COVERAGE_REPORTS_PATH/TestResults"

# Default values
RUN_UNIT_TESTS=true
RUN_UI_TESTS=true
RUN_PERFORMANCE_TESTS=true
RUN_SECURITY_TESTS=true
GENERATE_COVERAGE=true
DEVICE="iPhone 15 Pro"
OS_VERSION="17.0"
DESTINATION="platform=iOS Simulator,name=$DEVICE,OS=$OS_VERSION"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --unit-only)
      RUN_UI_TESTS=false
      RUN_PERFORMANCE_TESTS=false
      RUN_SECURITY_TESTS=false
      shift
      ;;
    --ui-only)
      RUN_UNIT_TESTS=false
      RUN_PERFORMANCE_TESTS=false
      RUN_SECURITY_TESTS=false
      shift
      ;;
    --performance-only)
      RUN_UNIT_TESTS=false
      RUN_UI_TESTS=false
      RUN_SECURITY_TESTS=false
      shift
      ;;
    --security-only)
      RUN_UNIT_TESTS=false
      RUN_UI_TESTS=false
      RUN_PERFORMANCE_TESTS=false
      shift
      ;;
    --no-coverage)
      GENERATE_COVERAGE=false
      shift
      ;;
    --device)
      DEVICE="$2"
      DESTINATION="platform=iOS Simulator,name=$DEVICE,OS=$OS_VERSION"
      shift 2
      ;;
    --os)
      OS_VERSION="$2"
      DESTINATION="platform=iOS Simulator,name=$DEVICE,OS=$OS_VERSION"
      shift 2
      ;;
    --help)
      echo "StarkPay iOS Test Runner"
      echo ""
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --unit-only           Run only unit tests"
      echo "  --ui-only            Run only UI tests"  
      echo "  --performance-only   Run only performance tests"
      echo "  --security-only      Run only security tests"
      echo "  --no-coverage        Skip code coverage generation"
      echo "  --device DEVICE      Specify simulator device (default: iPhone 15 Pro)"
      echo "  --os VERSION         Specify iOS version (default: 17.0)"
      echo "  --help               Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                           # Run all tests with coverage"
      echo "  $0 --unit-only               # Run only unit tests"
      echo "  $0 --device 'iPhone 14 Pro'  # Run tests on iPhone 14 Pro"
      echo "  $0 --no-coverage             # Run tests without coverage"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Function to print section headers
print_header() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
}

# Function to print status messages
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print warnings
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to print errors
print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if Xcode is installed
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode is not installed or not in PATH"
        exit 1
    fi
    print_status "Xcode found"
    
    # Check if project exists
    if [[ ! -f "$PROJECT_NAME.xcodeproj/project.pbxproj" ]]; then
        print_error "Xcode project not found: $PROJECT_NAME.xcodeproj"
        exit 1
    fi
    print_status "Xcode project found"
    
    # Check if simulator is available
    if ! xcrun simctl list devices available | grep -q "$DEVICE"; then
        print_warning "Device '$DEVICE' not found. Available devices:"
        xcrun simctl list devices available | grep "iPhone\|iPad" | head -5
        print_warning "Using default device"
        DEVICE="iPhone 15 Pro"
        DESTINATION="platform=iOS Simulator,name=$DEVICE,OS=$OS_VERSION"
    fi
    print_status "Simulator device: $DEVICE"
}

# Setup test environment
setup_environment() {
    print_header "Setting Up Test Environment"
    
    # Create directories
    mkdir -p "$COVERAGE_REPORTS_PATH"
    mkdir -p "$TEST_RESULTS_PATH"
    mkdir -p "$DERIVED_DATA_PATH"
    
    # Clean up old reports
    rm -f "$COVERAGE_REPORTS_PATH"/*.html
    rm -f "$COVERAGE_REPORTS_PATH"/*.xml
    rm -f "$TEST_RESULTS_PATH"/*.xml
    rm -f "$TEST_RESULTS_PATH"/*.junit
    
    print_status "Test directories created"
    
    # Boot simulator if needed
    print_status "Booting simulator..."
    xcrun simctl boot "$DEVICE" 2>/dev/null || true
    
    # Wait for simulator to be ready
    sleep 5
    print_status "Simulator ready"
}

# Build the app for testing
build_for_testing() {
    print_header "Building App for Testing"
    
    local build_args=(
        -project "$PROJECT_NAME.xcodeproj"
        -scheme "$SCHEME"
        -destination "$DESTINATION"
        -derivedDataPath "$DERIVED_DATA_PATH"
        -quiet
        build-for-testing
    )
    
    if [[ "$GENERATE_COVERAGE" == "true" ]]; then
        build_args+=(-enableCodeCoverage YES)
    fi
    
    if xcodebuild "${build_args[@]}"; then
        print_status "Build successful"
    else
        print_error "Build failed"
        exit 1
    fi
}

# Run unit tests
run_unit_tests() {
    if [[ "$RUN_UNIT_TESTS" != "true" ]]; then
        return 0
    fi
    
    print_header "Running Unit Tests"
    
    local test_args=(
        -project "$PROJECT_NAME.xcodeproj"
        -scheme "$SCHEME"
        -destination "$DESTINATION"
        -derivedDataPath "$DERIVED_DATA_PATH"
        -resultBundlePath "$TEST_RESULTS_PATH/UnitTests.xcresult"
        -only-testing "${SCHEME}Tests"
        test-without-building
    )
    
    if [[ "$GENERATE_COVERAGE" == "true" ]]; then
        test_args+=(-enableCodeCoverage YES)
    fi
    
    local start_time=$(date +%s)
    if xcodebuild "${test_args[@]}" | tee "$TEST_RESULTS_PATH/unit_tests.log"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_status "Unit tests completed in ${duration}s"
    else
        print_error "Unit tests failed"
        return 1
    fi
}

# Run UI tests
run_ui_tests() {
    if [[ "$RUN_UI_TESTS" != "true" ]]; then
        return 0
    fi
    
    print_header "Running UI Tests"
    
    local test_args=(
        -project "$PROJECT_NAME.xcodeproj"
        -scheme "$SCHEME"
        -destination "$DESTINATION"
        -derivedDataPath "$DERIVED_DATA_PATH"
        -resultBundlePath "$TEST_RESULTS_PATH/UITests.xcresult"
        -only-testing "${SCHEME}UITests/AuthenticationFlowTests"
        -only-testing "${SCHEME}UITests/PaymentFlowTests"
        test-without-building
    )
    
    local start_time=$(date +%s)
    if xcodebuild "${test_args[@]}" | tee "$TEST_RESULTS_PATH/ui_tests.log"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_status "UI tests completed in ${duration}s"
    else
        print_error "UI tests failed"
        return 1
    fi
}

# Run performance tests
run_performance_tests() {
    if [[ "$RUN_PERFORMANCE_TESTS" != "true" ]]; then
        return 0
    fi
    
    print_header "Running Performance Tests"
    
    local test_args=(
        -project "$PROJECT_NAME.xcodeproj"
        -scheme "$SCHEME"
        -destination "$DESTINATION"
        -derivedDataPath "$DERIVED_DATA_PATH"
        -resultBundlePath "$TEST_RESULTS_PATH/PerformanceTests.xcresult"
        -only-testing "${SCHEME}UITests/PerformanceTests"
        test-without-building
    )
    
    local start_time=$(date +%s)
    if xcodebuild "${test_args[@]}" | tee "$TEST_RESULTS_PATH/performance_tests.log"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_status "Performance tests completed in ${duration}s"
    else
        print_error "Performance tests failed"
        return 1
    fi
}

# Run security tests
run_security_tests() {
    if [[ "$RUN_SECURITY_TESTS" != "true" ]]; then
        return 0
    fi
    
    print_header "Running Security Tests"
    
    local test_args=(
        -project "$PROJECT_NAME.xcodeproj"
        -scheme "$SCHEME"
        -destination "$DESTINATION"
        -derivedDataPath "$DERIVED_DATA_PATH"
        -resultBundlePath "$TEST_RESULTS_PATH/SecurityTests.xcresult"
        -only-testing "${SCHEME}UITests/SecurityTests"
        test-without-building
    )
    
    local start_time=$(date +%s)
    if xcodebuild "${test_args[@]}" | tee "$TEST_RESULTS_PATH/security_tests.log"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_status "Security tests completed in ${duration}s"
    else
        print_error "Security tests failed"
        return 1
    fi
}

# Generate coverage report
generate_coverage_report() {
    if [[ "$GENERATE_COVERAGE" != "true" ]]; then
        return 0
    fi
    
    print_header "Generating Coverage Report"
    
    # Find the coverage data
    local coverage_file
    coverage_file=$(find "$DERIVED_DATA_PATH" -name "*.xccovreport" -type f | head -1)
    
    if [[ -z "$coverage_file" ]]; then
        print_warning "No coverage data found"
        return 0
    fi
    
    # Generate human-readable coverage report
    xcrun xccov view --report --json "$coverage_file" > "$COVERAGE_REPORTS_PATH/coverage.json"
    xcrun xccov view --report "$coverage_file" > "$COVERAGE_REPORTS_PATH/coverage.txt"
    
    # Generate HTML coverage report (requires additional tools)
    if command -v genhtml &> /dev/null; then
        # Convert to lcov format and generate HTML
        xcrun xccov view --file-list "$coverage_file" | \
        while read -r file; do
            xcrun xccov view --file "$file" "$coverage_file"
        done > "$COVERAGE_REPORTS_PATH/coverage.lcov"
        
        genhtml "$COVERAGE_REPORTS_PATH/coverage.lcov" \
            --output-directory "$COVERAGE_REPORTS_PATH/html" \
            --title "StarkPay iOS Coverage Report"
    fi
    
    # Extract coverage percentage
    local coverage_percentage
    coverage_percentage=$(xcrun xccov view --report "$coverage_file" | grep -E "^[[:space:]]*[0-9]+\.[0-9]+%" | tail -1 | awk '{print $1}')
    
    print_status "Coverage report generated: $coverage_percentage"
}

# Generate test reports
generate_test_reports() {
    print_header "Generating Test Reports"
    
    # Convert xcresult to JUnit XML for CI systems
    for xcresult_file in "$TEST_RESULTS_PATH"/*.xcresult; do
        if [[ -f "$xcresult_file" ]]; then
            local base_name
            base_name=$(basename "$xcresult_file" .xcresult)
            
            # Generate JUnit report
            xcrun xcresulttool export --type junit \
                --path "$xcresult_file" \
                --output "$TEST_RESULTS_PATH/${base_name}.junit"
            
            # Generate human-readable summary
            xcrun xcresulttool get --format json \
                --path "$xcresult_file" > "$TEST_RESULTS_PATH/${base_name}.json"
        fi
    done
    
    print_status "Test reports generated"
}

# Create summary report
create_summary_report() {
    print_header "Creating Test Summary"
    
    local summary_file="$COVERAGE_REPORTS_PATH/test_summary.md"
    
    cat > "$summary_file" << EOF
# StarkPay iOS Test Report

**Generated:** $(date)
**Device:** $DEVICE
**iOS Version:** $OS_VERSION

## Test Execution Summary

EOF
    
    # Add test results for each category
    if [[ "$RUN_UNIT_TESTS" == "true" ]]; then
        echo "### Unit Tests" >> "$summary_file"
        if [[ -f "$TEST_RESULTS_PATH/UnitTests.xcresult" ]]; then
            echo "✅ **PASSED** - Unit tests executed successfully" >> "$summary_file"
        else
            echo "❌ **FAILED** - Unit tests failed or did not run" >> "$summary_file"
        fi
        echo "" >> "$summary_file"
    fi
    
    if [[ "$RUN_UI_TESTS" == "true" ]]; then
        echo "### UI Tests" >> "$summary_file"
        if [[ -f "$TEST_RESULTS_PATH/UITests.xcresult" ]]; then
            echo "✅ **PASSED** - UI tests executed successfully" >> "$summary_file"
        else
            echo "❌ **FAILED** - UI tests failed or did not run" >> "$summary_file"
        fi
        echo "" >> "$summary_file"
    fi
    
    if [[ "$RUN_PERFORMANCE_TESTS" == "true" ]]; then
        echo "### Performance Tests" >> "$summary_file"
        if [[ -f "$TEST_RESULTS_PATH/PerformanceTests.xcresult" ]]; then
            echo "✅ **PASSED** - Performance tests executed successfully" >> "$summary_file"
        else
            echo "❌ **FAILED** - Performance tests failed or did not run" >> "$summary_file"
        fi
        echo "" >> "$summary_file"
    fi
    
    if [[ "$RUN_SECURITY_TESTS" == "true" ]]; then
        echo "### Security Tests" >> "$summary_file"
        if [[ -f "$TEST_RESULTS_PATH/SecurityTests.xcresult" ]]; then
            echo "✅ **PASSED** - Security tests executed successfully" >> "$summary_file"
        else
            echo "❌ **FAILED** - Security tests failed or did not run" >> "$summary_file"
        fi
        echo "" >> "$summary_file"
    fi
    
    # Add coverage information
    if [[ "$GENERATE_COVERAGE" == "true" && -f "$COVERAGE_REPORTS_PATH/coverage.txt" ]]; then
        echo "### Code Coverage" >> "$summary_file"
        local coverage_line
        coverage_line=$(grep -E "^[[:space:]]*[0-9]+\.[0-9]+%" "$COVERAGE_REPORTS_PATH/coverage.txt" | tail -1)
        if [[ -n "$coverage_line" ]]; then
            echo "**Overall Coverage:** $coverage_line" >> "$summary_file"
        fi
        echo "" >> "$summary_file"
    fi
    
    # Add file locations
    echo "## Report Files" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "- **Test Results:** \`$TEST_RESULTS_PATH\`" >> "$summary_file"
    echo "- **Coverage Reports:** \`$COVERAGE_REPORTS_PATH\`" >> "$summary_file"
    echo "- **Logs:** \`$TEST_RESULTS_PATH/*.log\`" >> "$summary_file"
    
    print_status "Summary report created: $summary_file"
}

# Cleanup function
cleanup() {
    print_header "Cleaning Up"
    
    # Shutdown simulator
    xcrun simctl shutdown "$DEVICE" 2>/dev/null || true
    
    print_status "Cleanup completed"
}

# Main execution
main() {
    local start_time=$(date +%s)
    
    print_header "StarkPay iOS Test Execution"
    echo "Device: $DEVICE"
    echo "iOS Version: $OS_VERSION"
    echo "Tests: Unit=$RUN_UNIT_TESTS, UI=$RUN_UI_TESTS, Performance=$RUN_PERFORMANCE_TESTS, Security=$RUN_SECURITY_TESTS"
    echo "Coverage: $GENERATE_COVERAGE"
    
    # Set up trap for cleanup
    trap cleanup EXIT
    
    # Execute test pipeline
    check_prerequisites
    setup_environment
    build_for_testing
    
    local test_failures=0
    
    if ! run_unit_tests; then
        ((test_failures++))
    fi
    
    if ! run_ui_tests; then
        ((test_failures++))
    fi
    
    if ! run_performance_tests; then
        ((test_failures++))
    fi
    
    if ! run_security_tests; then
        ((test_failures++))
    fi
    
    generate_coverage_report
    generate_test_reports
    create_summary_report
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    print_header "Test Execution Complete"
    echo "Duration: ${total_duration}s"
    echo "Failed test suites: $test_failures"
    
    if [[ $test_failures -eq 0 ]]; then
        print_status "All tests passed successfully!"
        exit 0
    else
        print_error "$test_failures test suite(s) failed"
        exit 1
    fi
}

# Run main function
main "$@"
#!/bin/bash

# StarkPay iOS - Coverage Report Generator
# Generates comprehensive coverage reports in multiple formats

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_NAME="StarkPayiOS"
SCHEME="StarkPayiOS"
DERIVED_DATA_PATH="$PWD/DerivedData"
REPORTS_PATH="$PWD/TestReports"
COVERAGE_PATH="$REPORTS_PATH/Coverage"

print_header() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
}

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Setup directories
setup_directories() {
    print_header "Setting Up Coverage Report Environment"
    
    mkdir -p "$COVERAGE_PATH"
    mkdir -p "$COVERAGE_PATH/html"
    mkdir -p "$COVERAGE_PATH/json"
    mkdir -p "$COVERAGE_PATH/text"
    
    print_status "Coverage directories created"
}

# Find coverage data
find_coverage_data() {
    print_header "Locating Coverage Data"
    
    COVERAGE_REPORT=$(find "$DERIVED_DATA_PATH" -name "*.xccovreport" -type f | head -1)
    
    if [[ -z "$COVERAGE_REPORT" ]]; then
        print_warning "No coverage report found. Running tests with coverage enabled..."
        
        xcodebuild test \
            -project "$PROJECT_NAME.xcodeproj" \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
            -derivedDataPath "$DERIVED_DATA_PATH" \
            -enableCodeCoverage YES \
            -quiet
        
        COVERAGE_REPORT=$(find "$DERIVED_DATA_PATH" -name "*.xccovreport" -type f | head -1)
    fi
    
    if [[ -n "$COVERAGE_REPORT" ]]; then
        print_status "Coverage data found: $COVERAGE_REPORT"
    else
        echo "❌ No coverage data available"
        exit 1
    fi
}

# Generate JSON report
generate_json_report() {
    print_header "Generating JSON Coverage Report"
    
    xcrun xccov view --report --json "$COVERAGE_REPORT" > "$COVERAGE_PATH/json/coverage.json"
    print_status "JSON report: $COVERAGE_PATH/json/coverage.json"
}

# Generate text report
generate_text_report() {
    print_header "Generating Text Coverage Report"
    
    xcrun xccov view --report "$COVERAGE_REPORT" > "$COVERAGE_PATH/text/coverage.txt"
    
    # Create detailed file-by-file report
    echo "# StarkPay iOS Coverage Report" > "$COVERAGE_PATH/text/detailed_coverage.md"
    echo "" >> "$COVERAGE_PATH/text/detailed_coverage.md"
    echo "**Generated:** $(date)" >> "$COVERAGE_PATH/text/detailed_coverage.md"
    echo "" >> "$COVERAGE_PATH/text/detailed_coverage.md"
    
    # Overall coverage
    overall_coverage=$(xcrun xccov view --report "$COVERAGE_REPORT" | grep -E "^[[:space:]]*[0-9]+\.[0-9]+%" | tail -1)
    echo "**Overall Coverage:** $overall_coverage" >> "$COVERAGE_PATH/text/detailed_coverage.md"
    echo "" >> "$COVERAGE_PATH/text/detailed_coverage.md"
    
    # Per-file coverage
    echo "## File Coverage Details" >> "$COVERAGE_PATH/text/detailed_coverage.md"
    echo "" >> "$COVERAGE_PATH/text/detailed_coverage.md"
    echo "| File | Coverage | Lines Covered | Total Lines |" >> "$COVERAGE_PATH/text/detailed_coverage.md"
    echo "|------|----------|---------------|-------------|" >> "$COVERAGE_PATH/text/detailed_coverage.md"
    
    xcrun xccov view --file-list "$COVERAGE_REPORT" | while read -r file; do
        if [[ $file == *".swift" ]] && [[ $file != *"Tests"* ]]; then
            file_coverage=$(xcrun xccov view --file "$file" "$COVERAGE_REPORT" | head -1)
            coverage_percent=$(echo "$file_coverage" | grep -oE '[0-9]+\.[0-9]+%')
            lines_covered=$(echo "$file_coverage" | grep -oE '[0-9]+ of [0-9]+' | head -1)
            
            filename=$(basename "$file")
            echo "| $filename | $coverage_percent | $lines_covered |" >> "$COVERAGE_PATH/text/detailed_coverage.md"
        fi
    done
    
    print_status "Text reports generated in $COVERAGE_PATH/text/"
}

# Generate HTML report (requires lcov/genhtml)
generate_html_report() {
    print_header "Generating HTML Coverage Report"
    
    if ! command -v genhtml &> /dev/null; then
        print_warning "genhtml not found. Install lcov for HTML reports: brew install lcov"
        return 0
    fi
    
    # Convert to lcov format
    echo "Converting to LCOV format..."
    
    # Create lcov tracefile
    echo "TN:" > "$COVERAGE_PATH/coverage.info"
    
    xcrun xccov view --file-list "$COVERAGE_REPORT" | while read -r file; do
        if [[ $file == *".swift" ]] && [[ $file != *"Tests"* ]]; then
            echo "SF:$file" >> "$COVERAGE_PATH/coverage.info"
            
            # Get line coverage data
            xcrun xccov view --file "$file" "$COVERAGE_REPORT" | grep -E '^[[:space:]]*[0-9]+:' | while read -r line; do
                line_num=$(echo "$line" | grep -oE '^[[:space:]]*[0-9]+' | tr -d ' ')
                hit_count=$(echo "$line" | grep -oE '[0-9]+$' || echo "1")
                echo "DA:$line_num,$hit_count" >> "$COVERAGE_PATH/coverage.info"
            done
            
            echo "end_of_record" >> "$COVERAGE_PATH/coverage.info"
        fi
    done
    
    # Generate HTML
    genhtml "$COVERAGE_PATH/coverage.info" \
        --output-directory "$COVERAGE_PATH/html" \
        --title "StarkPay iOS Coverage Report" \
        --legend \
        --show-details \
        --highlight \
        --frames \
        2>/dev/null || print_warning "HTML generation had issues, but may have succeeded"
    
    if [[ -f "$COVERAGE_PATH/html/index.html" ]]; then
        print_status "HTML report: $COVERAGE_PATH/html/index.html"
    else
        print_warning "HTML report generation failed"
    fi
}

# Generate badge data
generate_badge_data() {
    print_header "Generating Coverage Badge Data"
    
    if [[ -f "$COVERAGE_PATH/text/coverage.txt" ]]; then
        coverage_percent=$(cat "$COVERAGE_PATH/text/coverage.txt" | grep -E "^[[:space:]]*[0-9]+\.[0-9]+%" | tail -1 | awk '{print $1}' | sed 's/%//')
        
        if [[ -n "$coverage_percent" ]]; then
            # Determine color based on coverage
            if (( $(echo "$coverage_percent >= 80" | bc -l) )); then
                color="brightgreen"
            elif (( $(echo "$coverage_percent >= 60" | bc -l) )); then
                color="yellow"
            else
                color="red"
            fi
            
            # Create badge JSON
            cat > "$COVERAGE_PATH/badge.json" << EOF
{
  "schemaVersion": 1,
  "label": "coverage",
  "message": "${coverage_percent}%",
  "color": "$color"
}
EOF
            
            # Create badge URL
            echo "https://img.shields.io/badge/Coverage-${coverage_percent}%25-${color}" > "$COVERAGE_PATH/badge_url.txt"
            
            print_status "Coverage badge data: $coverage_percent% ($color)"
        fi
    fi
}

# Create summary report
create_summary_report() {
    print_header "Creating Coverage Summary"
    
    cat > "$COVERAGE_PATH/COVERAGE_SUMMARY.md" << EOF
# StarkPay iOS - Coverage Summary Report

**Generated:** $(date)
**Xcode Version:** $(xcodebuild -version | head -1)
**Platform:** $(uname -a)

## Overall Coverage

EOF
    
    if [[ -f "$COVERAGE_PATH/text/coverage.txt" ]]; then
        overall_coverage=$(cat "$COVERAGE_PATH/text/coverage.txt" | grep -E "^[[:space:]]*[0-9]+\.[0-9]+%" | tail -1)
        coverage_percent=$(echo "$overall_coverage" | awk '{print $1}' | sed 's/%//')
        
        echo "**Overall Coverage:** $overall_coverage" >> "$COVERAGE_PATH/COVERAGE_SUMMARY.md"
        echo "" >> "$COVERAGE_PATH/COVERAGE_SUMMARY.md"
        
        if (( $(echo "$coverage_percent >= 80" | bc -l) )); then
            echo "🎉 **Excellent Coverage** - Above 80% threshold" >> "$COVERAGE_PATH/COVERAGE_SUMMARY.md"
        elif (( $(echo "$coverage_percent >= 60" | bc -l) )); then
            echo "⚠️ **Good Coverage** - Above 60%, aim for 80%" >> "$COVERAGE_PATH/COVERAGE_SUMMARY.md"
        else
            echo "🚨 **Low Coverage** - Below 60%, needs improvement" >> "$COVERAGE_PATH/COVERAGE_SUMMARY.md"
        fi
        
        echo "" >> "$COVERAGE_PATH/COVERAGE_SUMMARY.md"
    fi
    
    cat >> "$COVERAGE_PATH/COVERAGE_SUMMARY.md" << EOF
## Coverage by Module

| Module | Coverage | Status |
|--------|----------|--------|
EOF
    
    # Add module coverage (simplified - would need more complex parsing for real modules)
    echo "| Core App | $(cat "$COVERAGE_PATH/text/coverage.txt" | grep -E "^[[:space:]]*[0-9]+\.[0-9]+%" | head -1 | awk '{print $1}') | ✅ |" >> "$COVERAGE_PATH/COVERAGE_SUMMARY.md"
    
    cat >> "$COVERAGE_PATH/COVERAGE_SUMMARY.md" << EOF

## Files with Low Coverage (<70%)

EOF
    
    # This would need more sophisticated parsing in a real implementation
    echo "*Analysis requires manual review of detailed coverage data*" >> "$COVERAGE_PATH/COVERAGE_SUMMARY.md"
    
    cat >> "$COVERAGE_PATH/COVERAGE_SUMMARY.md" << EOF

## Available Reports

- **Text Report:** \`text/coverage.txt\`
- **JSON Report:** \`json/coverage.json\`
- **Detailed Markdown:** \`text/detailed_coverage.md\`
EOF
    
    if [[ -f "$COVERAGE_PATH/html/index.html" ]]; then
        echo "- **HTML Report:** \`html/index.html\`" >> "$COVERAGE_PATH/COVERAGE_SUMMARY.md"
    fi
    
    cat >> "$COVERAGE_PATH/COVERAGE_SUMMARY.md" << EOF

## Recommendations

1. **Maintain 80%+ overall coverage**
2. **Focus on critical business logic (90%+ coverage)**
3. **Test edge cases and error conditions**
4. **Regular coverage monitoring in CI**

---
*Generated by StarkPay iOS Coverage Reporter*
EOF
    
    print_status "Summary report: $COVERAGE_PATH/COVERAGE_SUMMARY.md"
}

# Open reports
open_reports() {
    print_header "Opening Coverage Reports"
    
    if [[ "$1" == "--open" ]]; then
        if [[ -f "$COVERAGE_PATH/html/index.html" ]]; then
            open "$COVERAGE_PATH/html/index.html"
        else
            open "$COVERAGE_PATH/COVERAGE_SUMMARY.md"
        fi
    fi
    
    print_status "Reports available in: $COVERAGE_PATH"
    echo ""
    echo "Available reports:"
    echo "  📄 Summary: $COVERAGE_PATH/COVERAGE_SUMMARY.md"
    echo "  📊 Text: $COVERAGE_PATH/text/coverage.txt"
    echo "  🗂 JSON: $COVERAGE_PATH/json/coverage.json"
    
    if [[ -f "$COVERAGE_PATH/html/index.html" ]]; then
        echo "  🌐 HTML: $COVERAGE_PATH/html/index.html"
    fi
    
    if [[ -f "$COVERAGE_PATH/badge_url.txt" ]]; then
        echo "  🏷️ Badge: $(cat "$COVERAGE_PATH/badge_url.txt")"
    fi
}

# Main execution
main() {
    echo "StarkPay iOS Coverage Report Generator"
    echo "====================================="
    
    setup_directories
    find_coverage_data
    generate_json_report
    generate_text_report
    generate_html_report
    generate_badge_data
    create_summary_report
    open_reports "$@"
    
    print_header "Coverage Report Generation Complete"
}

# Check for help
if [[ "$1" == "--help" ]]; then
    echo "StarkPay iOS Coverage Report Generator"
    echo ""
    echo "Usage: $0 [--open]"
    echo ""
    echo "Options:"
    echo "  --open    Open the HTML report automatically"
    echo "  --help    Show this help message"
    echo ""
    echo "This script generates comprehensive coverage reports in multiple formats:"
    echo "  - Text reports for CI integration"
    echo "  - JSON reports for automated processing"
    echo "  - HTML reports for detailed analysis"
    echo "  - Badge data for README display"
    echo ""
    exit 0
fi

# Run main function
main "$@"
#!/bin/bash

# StarkPay iOS Development Environment Setup Script
# This script sets up the development environment for StarkPay iOS app

set -e

echo "🚀 Setting up StarkPay iOS Development Environment"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only."
    exit 1
fi

print_status "Checking system requirements..."

# Check Xcode installation
if ! xcode-select -p &> /dev/null; then
    print_error "Xcode is not installed. Please install Xcode from the App Store."
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n 1 | cut -d ' ' -f2)
print_success "Xcode $XCODE_VERSION detected"

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    print_success "Homebrew installed"
else
    print_success "Homebrew already installed"
    print_status "Updating Homebrew..."
    brew update
fi

# Install required tools
print_status "Installing development tools..."

# Install SwiftLint
if ! command -v swiftlint &> /dev/null; then
    print_status "Installing SwiftLint..."
    brew install swiftlint
    print_success "SwiftLint installed"
else
    print_success "SwiftLint already installed"
    print_status "Updating SwiftLint..."
    brew upgrade swiftlint || true
fi

# Install GitHub CLI (optional but useful)
if ! command -v gh &> /dev/null; then
    print_status "Installing GitHub CLI..."
    brew install gh
    print_success "GitHub CLI installed"
else
    print_success "GitHub CLI already installed"
fi

# Install xcbeautify for better build output
if ! command -v xcbeautify &> /dev/null; then
    print_status "Installing xcbeautify..."
    brew install xcbeautify
    print_success "xcbeautify installed"
else
    print_success "xcbeautify already installed"
fi

# Create SwiftLint configuration
print_status "Creating SwiftLint configuration..."
cat > .swiftlint.yml << 'EOF'
disabled_rules:
  - trailing_whitespace
  - todo

opt_in_rules:
  - empty_count
  - empty_string
  - explicit_init
  - first_where
  - force_unwrapping
  - implicitly_unwrapped_optional
  - overridden_super_call
  - redundant_nil_coalescing
  - sorted_first_last
  - syntactic_sugar
  - unneeded_parentheses_in_closure_argument
  - vertical_parameter_alignment_on_call

included:
  - StarkPayiOS

excluded:
  - Carthage
  - Pods
  - .build
  - scripts

line_length:
  warning: 120
  error: 200

function_body_length:
  warning: 100
  error: 200

type_body_length:
  warning: 300
  error: 500

file_length:
  warning: 500
  error: 1200

cyclomatic_complexity:
  warning: 10
  error: 20

nesting:
  type_level: 2
  statement_level: 5
EOF

print_success "SwiftLint configuration created"

# Set up Git hooks (optional)
if [[ -d ".git" ]]; then
    print_status "Setting up Git hooks..."
    
    mkdir -p .git/hooks
    
    # Pre-commit hook for SwiftLint
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# SwiftLint pre-commit hook

if which swiftlint >/dev/null; then
    swiftlint --strict
    if [ $? -ne 0 ]; then
        echo "SwiftLint failed. Please fix the issues above and try again."
        exit 1
    fi
else
    echo "SwiftLint not installed. Install it with 'brew install swiftlint'"
    exit 1
fi
EOF
    
    chmod +x .git/hooks/pre-commit
    print_success "Git pre-commit hook configured"
else
    print_warning "Not a Git repository - skipping Git hooks setup"
fi

# Create development scripts
print_status "Creating development scripts..."

mkdir -p scripts

# Build script
cat > scripts/build.sh << 'EOF'
#!/bin/bash
# Build StarkPay iOS app

set -e

echo "🔨 Building StarkPay iOS..."

cd StarkPayiOS

xcodebuild clean build \
  -project StarkPayiOS.xcodeproj \
  -scheme StarkPayiOS \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  | xcbeautify

echo "✅ Build completed successfully"
EOF

# Test script
cat > scripts/test.sh << 'EOF'
#!/bin/bash
# Run StarkPay iOS tests

set -e

echo "🧪 Running StarkPay iOS tests..."

cd StarkPayiOS

xcodebuild test \
  -project StarkPayiOS.xcodeproj \
  -scheme StarkPayiOS \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  | xcbeautify

echo "✅ Tests completed successfully"
EOF

# Lint script
cat > scripts/lint.sh << 'EOF'
#!/bin/bash
# Run SwiftLint on StarkPay iOS

set -e

echo "🔍 Running SwiftLint..."

swiftlint lint

echo "✅ SwiftLint check completed"
EOF

# Format script
cat > scripts/format.sh << 'EOF'
#!/bin/bash
# Auto-fix SwiftLint issues

set -e

echo "🎨 Auto-fixing SwiftLint issues..."

swiftlint --fix

echo "✅ SwiftLint auto-fix completed"
EOF

# Archive script
cat > scripts/archive.sh << 'EOF'
#!/bin/bash
# Archive StarkPay iOS for distribution

set -e

echo "📦 Archiving StarkPay iOS..."

cd StarkPayiOS

BUILD_NUMBER=$(date +%Y%m%d%H%M)
ARCHIVE_PATH="StarkPay-${BUILD_NUMBER}.xcarchive"

xcodebuild clean archive \
  -project StarkPayiOS.xcodeproj \
  -scheme StarkPayiOS \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  | xcbeautify

echo "✅ Archive created: $ARCHIVE_PATH"
EOF

# Make scripts executable
chmod +x scripts/*.sh

print_success "Development scripts created"

# Verify iOS Simulator
print_status "Verifying iOS Simulator availability..."
if xcrun simctl list devices | grep -q "iPhone 15"; then
    print_success "iPhone 15 simulator available"
else
    print_warning "iPhone 15 simulator not found. You may need to download it from Xcode."
fi

# Create .gitignore if it doesn't exist
if [[ ! -f ".gitignore" ]]; then
    print_status "Creating .gitignore..."
    cat > .gitignore << 'EOF'
# Xcode
#
# gitignore contributors: remember to update Global/Xcode.gitignore, Objective-C.gitignore & Swift.gitignore

## User settings
xcuserdata/

## compatibility with Xcode 8 and earlier (ignoring not required starting Xcode 9)
*.xcscmblueprint
*.xccheckout

## compatibility with Xcode 3 and earlier (ignoring not required starting Xcode 4)
build/
DerivedData/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

## Obj-C/Swift specific
*.hmap

## App packaging
*.ipa
*.dSYM.zip
*.dSYM

## Playgrounds
timeline.xctimeline
playground.xcworkspace

# Swift Package Manager
#
# Add this line if you want to avoid checking in source code from Swift Package Manager dependencies.
# Packages/
# Package.pins
# Package.resolved
# *.xcodeproj
#
# Xcode automatically generates this directory with a .xcworkspacedata file and xcuserdata
# hence it is not needed unless you have added a package configuration file to your project
# .swiftpm

.build/

# CocoaPods
#
# We recommend against adding the Pods directory to your .gitignore. However
# you should judge for yourself, the pros and cons are mentioned at:
# https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control
#
# Pods/
#
# Add this line if you want to avoid checking in source code from the Xcode workspace
# *.xcworkspace

# Carthage
#
# Add this line if you want to avoid checking in source code from Carthage dependencies.
# Carthage/Checkouts

Carthage/Build/

# Accio dependency management
Dependencies/
.accio/

# fastlane
#
# It is recommended to not store the screenshots in the git repo.
# Instead, use fastlane to re-generate the screenshots whenever they are needed.
# For more information about the recommended setup visit:
# https://docs.fastlane.tools/best-practices/source-control/

fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# Code Injection
#
# After new code Injection tools there's a generated folder /iOSInjectionProject
# https://github.com/johnno1962/injectionforxcode

iOSInjectionProject/

# macOS
.DS_Store

# SwiftLint
.swiftlint.yml.tmp
EOF
    print_success ".gitignore created"
fi

# Final summary
echo ""
echo "🎉 Development environment setup completed!"
echo "=========================================="
echo ""
echo "Available commands:"
echo "  ./scripts/build.sh     - Build the app"
echo "  ./scripts/test.sh      - Run tests"
echo "  ./scripts/lint.sh      - Run SwiftLint"
echo "  ./scripts/format.sh    - Auto-fix SwiftLint issues"
echo "  ./scripts/archive.sh   - Create archive for distribution"
echo ""
echo "Next steps:"
echo "1. Open StarkPayiOS.xcodeproj in Xcode"
echo "2. Select a simulator and build the project"
echo "3. Run './scripts/lint.sh' to check code quality"
echo "4. Set up your Apple Developer account for device testing"
echo ""
print_success "Happy coding! 🚀"
# StarkPay iOS - Deployment Guide

This document provides comprehensive instructions for deploying StarkPay iOS to various environments.

## 📱 TestFlight Deployment (Recommended for Demo)

### Prerequisites
- Apple Developer Account (Individual or Organization)
- Xcode 15.0 or later
- macOS Monterey or later
- StarkPay project configured with proper Bundle ID

### Step 1: Configure Project for Distribution

```bash
# 1. Open Xcode project
cd StarkPayiOS
open StarkPayiOS.xcodeproj

# 2. Update project settings in Xcode:
#    - Set Bundle Identifier: com.starkpay.ios
#    - Set Version: 1.0.0
#    - Set Build: 1
#    - Configure signing with your Apple Developer Team
```

### Step 2: Create Archive
1. In Xcode, select **Product > Archive**
2. Choose **iOS Device (Generic)** as destination
3. Wait for archive to complete
4. Organizer window will open automatically

### Step 3: Upload to App Store Connect
1. In Organizer, select your archive
2. Click **Distribute App**
3. Select **App Store Connect**
4. Choose **Upload** 
5. Follow prompts and wait for processing

### Step 4: Configure TestFlight
1. Login to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app > TestFlight
3. Add internal testers (up to 100)
4. Submit for review if adding external testers

### Automated TestFlight Deployment Script

```bash
#!/bin/bash
# deploy-testflight.sh

set -e

echo "🚀 Deploying StarkPay iOS to TestFlight..."

# Build for archive
xcodebuild archive \
  -project StarkPayiOS.xcodeproj \
  -scheme StarkPayiOS \
  -configuration Release \
  -archivePath build/StarkPayiOS.xcarchive \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID" \
  CODE_SIGN_IDENTITY="iPhone Distribution" \
  PROVISIONING_PROFILE="StarkPay Distribution Profile"

# Export for App Store
xcodebuild -exportArchive \
  -archivePath build/StarkPayiOS.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist

# Upload to App Store Connect
xcrun altool --upload-app \
  -f build/export/StarkPayiOS.ipa \
  -u "your-apple-id@example.com" \
  -p "@keychain:AC_PASSWORD"

echo "✅ Deployment complete! Check App Store Connect for processing status."
```

## 🏗️ GitHub Actions Automated Deployment

Create `.github/workflows/deploy-testflight.yml`:

```yaml
name: Deploy to TestFlight

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: macos-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'
        
    - name: Install Apple Certificate
      uses: apple-actions/import-codesign-certs@v2
      with:
        p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
        p12-password: ${{ secrets.CERTIFICATES_PASSWORD }}
        
    - name: Install Provisioning Profile
      uses: apple-actions/download-provisioning-profiles@v1
      with:
        bundle-id: com.starkpay.ios
        issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
        api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
        api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
        
    - name: Build and Archive
      run: |
        cd StarkPayiOS
        xcodebuild archive \
          -project StarkPayiOS.xcodeproj \
          -scheme StarkPayiOS \
          -configuration Release \
          -archivePath build/StarkPayiOS.xcarchive
          
    - name: Export IPA
      run: |
        cd StarkPayiOS
        xcodebuild -exportArchive \
          -archivePath build/StarkPayiOS.xcarchive \
          -exportPath build/export \
          -exportOptionsPlist ExportOptions.plist
          
    - name: Upload to TestFlight
      uses: apple-actions/upload-testflight-build@v1
      with:
        app-path: StarkPayiOS/build/export/StarkPayiOS.ipa
        issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
        api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
        api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
```

## 🧪 Development/Staging Deployment

### Local Development Setup
```bash
# Clone and setup
git clone https://github.com/YourUsername/StarkPay-Hackathon-Submission.git
cd StarkPay-Hackathon-Submission/StarkPayiOS

# Open in Xcode
open StarkPayiOS.xcodeproj

# Run on simulator
# Select iPhone 15 simulator and press Cmd+R
```

### Staging Environment
- Use development certificates and provisioning profiles
- Deploy to internal TestFlight group for QA testing
- Enable debug logging and analytics in staging builds

## 🔒 Production Security Considerations

### Code Signing
- Use Distribution certificates for production
- Implement certificate pinning for API calls
- Enable App Transport Security (ATS)

### API Configuration
```swift
// Production API endpoints
struct ProductionConfig {
    static let baseURL = "https://api.starkpay.com"
    static let starknetRPC = "https://starknet-mainnet.public.blastapi.io"
    static let analyticsEndpoint = "https://analytics.starkpay.com"
}
```

### Security Checklist
- [ ] No hardcoded secrets or API keys
- [ ] Biometric authentication properly configured
- [ ] Network requests use HTTPS with certificate pinning
- [ ] Sensitive data encrypted in Keychain
- [ ] Debug logs disabled in release builds
- [ ] Crash reporting configured (Crashlytics)

## 📊 Monitoring and Analytics

### Post-Deployment Monitoring
1. **App Store Connect Analytics**
   - Track downloads and user engagement
   - Monitor crash reports and feedback

2. **Custom Analytics** (StarkPay AnalyticsManager)
   - User flow tracking
   - Payment completion rates
   - Biometric authentication success rates

3. **Performance Monitoring**
   - Memory usage patterns
   - Network response times
   - UI responsiveness (FPS tracking)

## 🚨 Rollback Strategy

### Emergency Rollback
1. **TestFlight**: Stop external testing immediately
2. **App Store**: Contact Apple Developer Support for expedited review
3. **Hotfix Process**:
   ```bash
   # Create hotfix branch
   git checkout -b hotfix/critical-fix
   
   # Make minimal fix
   # Test thoroughly
   
   # Tag and deploy
   git tag v1.0.1
   git push origin v1.0.1
   ```

## 🔄 Release Workflow

### Version Management
```bash
# Bump version for new release
# Update version in Xcode project
# Update CHANGELOG.md

# Tag release
git tag -a v1.1.0 -m "Release v1.1.0 - New features"
git push origin v1.1.0
```

### Release Checklist
- [ ] All tests passing
- [ ] Security audit completed
- [ ] Performance benchmarks met
- [ ] Documentation updated
- [ ] Changelog updated
- [ ] Version number incremented
- [ ] Certificate and profile validity checked

## 📞 Support and Troubleshooting

### Common Issues
1. **Code Signing Errors**: Verify certificates and provisioning profiles
2. **Upload Failures**: Check network and Apple Developer Portal status
3. **Archive Issues**: Clean build folder and retry

### Getting Help
- Apple Developer Forums
- Xcode documentation
- StarkPay development team: dev@starkpay.com

---

## 🎯 Hackathon Specific Notes

For the StarkNet Re{Solve} Hackathon 2024:

1. **Demo Deployment**: Use TestFlight for judge access
2. **Quick Setup**: Simulator build for immediate testing
3. **Evidence**: Screenshots and videos of deployment process
4. **Fallback**: Xcode simulator demo if TestFlight unavailable

**Estimated Deployment Time**: 
- TestFlight: 2-4 hours (first time setup)
- Simulator Demo: 5 minutes
- Production: 1-2 days (including review)
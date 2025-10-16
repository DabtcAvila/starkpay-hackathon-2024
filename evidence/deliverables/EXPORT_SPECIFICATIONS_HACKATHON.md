# StarkPay iOS App - Export Specifications for Hackathon Submission

## Overview

This document provides precise technical specifications for exporting the StarkPay demo video to maximize compatibility, quality, and hackathon scoring potential. These specifications ensure optimal viewing across all judge platforms while maintaining professional broadcast quality.

---

## Primary Export Specifications (Recommended)

### Video Specifications
- **Format**: H.264/MP4 (maximum compatibility)
- **Container**: .mp4 (universally supported)
- **Resolution**: 1920x1080 (Full HD)
- **Frame Rate**: 30 fps (standard for screen recordings)
- **Aspect Ratio**: 16:9 (standard widescreen)
- **Bitrate**: 12,000 kbps (high quality, manageable file size)
- **Encoding**: Variable bitrate (VBR) for optimal quality/size ratio

### Audio Specifications  
- **Format**: AAC (best compression with quality retention)
- **Sample Rate**: 48 kHz (professional standard)
- **Bit Depth**: 16-bit (sufficient for narration)
- **Bitrate**: 320 kbps (maximum AAC quality)
- **Channels**: Stereo (2.0)
- **Loudness**: -16 LUFS (broadcast standard)

### File Specifications
- **Target File Size**: 150-300 MB (balance of quality and portability)
- **Maximum File Size**: 500 MB (ensure uploadability)
- **Duration**: 2:45 ±5 seconds
- **Naming Convention**: `StarkPay_iOS_Demo_Final_v1.mp4`

---

## Platform-Specific Export Guidelines

### YouTube/Vimeo Upload (Primary Distribution)
```
Codec: H.264
Resolution: 1920x1080
Frame Rate: 30fps
Bitrate: 12 Mbps (video) + 320 kbps (audio)
Color Space: Rec. 709
Audio: AAC, 48kHz/16-bit
```

### Direct Download/Email Submission
```
Codec: H.264
Resolution: 1920x1080  
Frame Rate: 30fps
Bitrate: 8-10 Mbps (smaller file size)
Audio: AAC, 48kHz/16-bit, 256 kbps
Target Size: Under 200 MB
```

### Social Media/Twitter Sharing
```
Codec: H.264
Resolution: 1920x1080
Frame Rate: 30fps
Bitrate: 6-8 Mbps
Duration: Under 2:20 (Twitter video limit)
Audio: AAC, 44.1kHz/16-bit
```

---

## Export Settings by Software

## iMovie Export Settings

### Standard Quality Export (Recommended)
1. **File → Share → File**
2. **Select Quality**: "High" 
3. **Advanced Settings**:
   - Resolution: 1080p
   - Quality: High
   - Compress: Better Quality

### Custom Export Settings
1. **File → Share → File**
2. **Advanced Settings**:
   - Format: MP4
   - Resolution: 1920x1080
   - Quality: Custom
   - Video Bitrate: 12,000 kbps
   - Audio: AAC, 320 kbps

### File Naming in iMovie
- Default name: "StarkPay Demo"
- Save location: Desktop/StarkPay_Video_Project/04_Exports/final/
- Final filename: `StarkPay_iOS_Demo_Final_v1.mp4`

## Final Cut Pro X Export Settings

### Master File Export (Recommended)
1. **File → Share → Master File**
2. **Settings**:
   - Format: Video and Audio
   - Video Codec: H.264
   - Resolution: 1920x1080
   - Frame Rate: 30p
   - Field Output: Progressive
   - Color Space: Rec. 709

3. **Video Settings**:
   - Data Rate: 12,000 kbps
   - Key Frames: Automatic
   - Frame Reordering: Yes

4. **Audio Settings**:
   - Format: AAC
   - Sample Rate: 48 kHz
   - Channels: Stereo
   - Data Rate: 320 kbps

### YouTube Preset (Alternative)
1. **File → Share → YouTube & Facebook**
2. **Resolution**: 1080p HD
3. **Quality**: Maximum
4. **Export to file** instead of uploading

## DaVinci Resolve Export Settings

### H.264 Master Export
1. **Deliver Page → Custom Export**
2. **Format**: MP4
3. **Codec**: H.264
4. **Resolution**: 1920x1080
5. **Frame Rate**: 30fps
6. **Quality Settings**:
   - Bitrate: 12,000 kbps
   - Profile: High
   - Level: 4.2
   - Keyframes: 30 frames

7. **Audio Settings**:
   - Codec: AAC
   - Sample Rate: 48 kHz
   - Bitrate: 320 kbps

### Professional Broadcast Settings
1. **Format**: Quicktime
2. **Codec**: H.264
3. **Quality**: Custom
4. **Bitrate**: 15,000 kbps (higher quality)
5. **Color Space**: Rec. 709
6. **Audio**: Linear PCM 48kHz/24-bit (maximum quality)

---

## Quality Validation Process

### Pre-Export Checklist
- [ ] **Timeline reviewed** for any gaps or errors
- [ ] **Audio levels consistent** throughout (-16 LUFS target)
- [ ] **Color correction** applied appropriately
- [ ] **Titles/graphics** properly positioned and timed
- [ ] **Duration verified** (2:45 target)

### Export Process Monitoring
- [ ] **Sufficient storage space** (3x final file size recommended)
- [ ] **Computer resources available** (close unnecessary applications)
- [ ] **Export progress** monitored for errors
- [ ] **Estimated completion time** noted
- [ ] **Export log** checked for warnings or errors

### Post-Export Verification
- [ ] **Complete playback** without skipping
- [ ] **Audio sync** verified throughout
- [ ] **Visual quality** maintained from original
- [ ] **File size** within acceptable limits
- [ ] **File format** plays on multiple devices
- [ ] **Upload compatibility** tested

---

## Technical Quality Benchmarks

### Video Quality Metrics
- **Peak Signal-to-Noise Ratio (PSNR)**: >40 dB
- **Structural Similarity Index (SSIM)**: >0.95
- **No visible compression artifacts** at normal viewing distance
- **Consistent frame rate** without drops
- **Smooth motion** during app interactions

### Audio Quality Metrics
- **Signal-to-Noise Ratio**: >60 dB
- **Total Harmonic Distortion**: <0.1%
- **Frequency Response**: 100Hz-15kHz ±3dB
- **Peak levels**: Never exceed -3dB
- **RMS levels**: -16 LUFS ±1dB

### File Integrity Metrics
- **Playback compatibility**: 95%+ devices
- **Upload reliability**: Error-free to major platforms
- **Download speed**: Reasonable for target audience
- **Cross-platform compatibility**: Windows, Mac, iOS, Android

---

## Alternative Export Versions

### High-Quality Master (Archive)
**Purpose**: Preservation and future re-editing
```
Format: Apple ProRes 422 (if available) or H.264 High
Resolution: Original source resolution (1080p or 4K)
Bitrate: 25-50 Mbps (very high quality)
Audio: 48kHz/24-bit (uncompressed)
File Size: 1-2 GB (not for distribution)
```

### Compressed Version (Email/Upload)
**Purpose**: Easy distribution and fast uploads
```
Format: H.264
Resolution: 1920x1080
Bitrate: 6-8 Mbps
Audio: AAC 256 kbps
File Size: 100-150 MB
Quality: Good (suitable for judging)
```

### Social Media Version
**Purpose**: Twitter, LinkedIn, Instagram sharing
```
Format: H.264
Resolution: 1920x1080 (or 1080x1920 for vertical)
Duration: Under 2:20 (Twitter limit)
Bitrate: 5-6 Mbps
File Size: Under 100 MB
```

---

## Upload and Distribution Strategy

### Primary Submission Platforms

#### YouTube (Recommended)
- **Advantages**: High quality retention, reliable playback, analytics
- **Settings**: Use "YouTube 1080p" preset or custom H.264
- **Privacy**: Unlisted (accessible via link only)
- **Title**: "StarkPay iOS App - Professional Demo | Starknet Hackathon 2024"
- **Description**: Include technical details and GitHub links

#### Vimeo (Professional Alternative)  
- **Advantages**: No ads, professional appearance, better compression
- **Settings**: Custom H.264, 1080p, 12 Mbps
- **Privacy**: Private with password protection
- **Quality**: Often superior to YouTube for technical content

#### Google Drive/Dropbox (Direct Download)
- **Advantages**: Original quality preservation, judge can download
- **File Format**: MP4 H.264
- **Sharing**: Public link with view permissions
- **Backup**: Keep multiple copies in different locations

### Submission Package Contents
1. **Main video file**: `StarkPay_iOS_Demo_Final_v1.mp4`
2. **High-quality master**: `StarkPay_iOS_Demo_Master.mp4`
3. **Technical specifications document**: `export_specifications.txt`
4. **YouTube/Vimeo links**: In submission documentation
5. **MD5 hash verification**: For file integrity

---

## Common Export Issues and Solutions

### Video Issues

#### "Pixelated or Blurry Output"
- **Cause**: Bitrate too low or incorrect resolution scaling
- **Solution**: Increase bitrate to 10+ Mbps, verify resolution matches source

#### "Choppy Playback"
- **Cause**: Frame rate mismatch or processing power issues
- **Solution**: Match export frame rate to source, close background apps

#### "Color Looks Different After Export"
- **Cause**: Color space conversion issues
- **Solution**: Use Rec. 709 color space, verify monitor calibration

### Audio Issues

#### "Audio Out of Sync"
- **Cause**: Variable frame rate source or processing delays
- **Solution**: Convert source to constant frame rate before editing

#### "Background Noise in Final Export"
- **Cause**: Insufficient noise reduction during editing
- **Solution**: Re-apply noise reduction, check export audio settings

#### "Audio Too Quiet or Loud"
- **Cause**: Incorrect level setting during export
- **Solution**: Normalize to -16 LUFS, use audio limiter

### File Issues

#### "File Size Too Large"
- **Cause**: Bitrate too high or incorrect codec settings
- **Solution**: Reduce bitrate to 8-10 Mbps, use VBR encoding

#### "File Won't Upload"
- **Cause**: Unsupported format or size limits
- **Solution**: Convert to standard H.264 MP4, compress if necessary

#### "Playback Issues on Different Devices"
- **Cause**: Codec compatibility problems
- **Solution**: Use H.264 High profile, AAC audio for maximum compatibility

---

## Final Delivery Checklist

### Quality Assurance
- [ ] **Video plays perfectly** on at least 3 different devices
- [ ] **Audio is clear and synchronized** throughout
- [ ] **File size appropriate** for intended distribution method
- [ ] **Technical specifications met** according to this document
- [ ] **Backup copies created** in multiple locations

### Submission Preparation  
- [ ] **File naming consistent** with hackathon requirements
- [ ] **Upload links tested** and accessible
- [ ] **Download links functional** from different networks
- [ ] **Technical documentation** accompanies video files
- [ ] **Submission deadline verified** and met

### Professional Standards
- [ ] **Represents StarkPay app accurately** and professionally
- [ ] **Technical complexity evident** to judges
- [ ] **Production quality competitive** with professional app demos
- [ ] **Differentiates from prototypes** clearly
- [ ] **Maximizes scoring potential** across all evaluation criteria

This comprehensive export specification ensures the StarkPay demo video meets professional broadcast standards while maintaining optimal compatibility for hackathon judging across all platforms and devices.
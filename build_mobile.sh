#!/bin/bash

# 🚀 Quick Build Script for Mobile Apps

echo "🔨 Building Mobile Apps..."
echo ""

# Check Flutter
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter not found! Please install Flutter first."
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"
echo ""

# Clean
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get
echo ""

# Build Android APK
echo "🤖 Building Android APK (Release)..."
echo "⏳ This will take 2-5 minutes..."
flutter build apk --release --split-per-abi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Android APK built successfully!"
    echo ""
    echo "📦 Output files:"
    echo "   - build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk (32-bit)"
    echo "   - build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (64-bit)"
    echo "   - build/app/outputs/flutter-apk/app-x86_64-release.apk (Emulator)"
    echo ""
    echo "📱 To install on Android device:"
    echo "   1. Enable 'Install from Unknown Sources'"
    echo "   2. Copy APK to phone"
    echo "   3. Tap to install"
    echo ""
    
    # Calculate file sizes
    if [ -f "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" ]; then
        SIZE=$(du -h "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" | cut -f1)
        echo "📊 APK size (arm64-v8a): $SIZE"
    fi
else
    echo "❌ Android build failed!"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ask for App Bundle
read -p "📦 Do you want to build App Bundle for Google Play? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "🤖 Building Android App Bundle..."
    flutter build appbundle --release
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ App Bundle built successfully!"
        echo "📦 Output: build/app/outputs/bundle/release/app-release.aab"
        echo ""
        echo "📤 Upload to:"
        echo "   https://play.google.com/console"
        
        if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
            SIZE=$(du -h "build/app/outputs/bundle/release/app-release.aab" | cut -f1)
            echo "📊 AAB size: $SIZE"
        fi
    else
        echo "❌ App Bundle build failed!"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ask for iOS
read -p "🍎 Do you want to build iOS app? (Requires macOS) (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🍎 Building iOS IPA..."
        flutter build ipa --release
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "✅ iOS IPA built successfully!"
            echo "📦 Output: build/ios/ipa/*.ipa"
            echo ""
            echo "📤 Upload using:"
            echo "   - Xcode Organizer"
            echo "   - Or Transporter app"
        else
            echo "❌ iOS build failed!"
        fi
    else
        echo "⚠️  iOS build requires macOS. Skipping..."
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Build complete!"
echo ""
echo "📖 For detailed instructions, see:"
echo "   MOBILE_DEPLOYMENT_GUIDE.md"
echo ""

#!/bin/bash

# Vercel Build Script for Flutter Web

echo "🚀 Starting Flutter Web Build..."

# Install Flutter if not already installed
if [ ! -d "_flutter" ]; then
  echo "📦 Downloading Flutter SDK..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
fi

# Add Flutter to PATH
export PATH="$PATH:`pwd`/_flutter/bin"

# Run Flutter doctor
echo "🔍 Running Flutter doctor..."
flutter doctor -v

# Enable web
echo "🌐 Enabling Flutter web..."
flutter config --enable-web

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for web
echo "🏗️ Building for web (release mode)..."
flutter build web --release --web-renderer canvaskit

echo "✅ Build completed successfully!"

@echo off
echo LuWay Build Script
echo =================

echo.
echo Cleaning previous builds...
flutter clean

echo.
echo Getting dependencies...
flutter pub get

echo.
echo Verifying code...
flutter analyze

echo.
echo Running tests...
flutter test

echo.
echo Building Android APK...
flutter build apk --release

echo.
echo Build completed!
echo APK location: build\app\outputs\flutter-apk\app-release.apk
echo.

pause

# 🔥 Firebase Authentication Setup Guide

## Current Status
- ✅ Firebase project exists: `ai-student-assistant-76e9e`
- ✅ Flutter app is configured with Firebase
- ✅ Google services files are in place
- ❌ Authentication is not enabled/configured in Firebase Console

## Step-by-Step Fix

### 1. Enable Authentication in Firebase Console

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: `ai-student-assistant-76e9e`
3. **Navigate to Authentication**:
   - Click "Authentication" in the left sidebar
   - If you see "Get started", click it

### 2. Enable Sign-In Methods

1. **Go to Sign-in method tab**
2. **Enable Email/Password**:
   - Click on "Email/Password"
   - Toggle "Enable" to ON
   - Click "Save"

3. **Enable Google Sign-In**:
   - Click on "Google"
   - Toggle "Enable" to ON
   - **Important**: Set the project support email (use your email)
   - Click "Save"

### 3. Configure Google Sign-In for Android

1. **In Firebase Console, go to Project Settings** (gear icon)
2. **Scroll down to "Your apps" section**
3. **Click on your Android app** (com.example.ai_student_assistant)
4. **Make sure SHA certificate fingerprint is added**:
   - You need to add your debug SHA-1 key
   - Run this command to get it:
     ```bash
     cd android
     ./gradlew signingReport
     ```
   - Copy the SHA1 from "Variant: debug" section
   - Add it in Firebase Console under your Android app

### 4. Update Android Package Name (if needed)

Make sure your package name matches everywhere:
- Firebase Console: `com.example.ai_student_assistant`
- Android manifest: `android/app/src/main/AndroidManifest.xml`
- Build.gradle: `android/app/build.gradle`

### 5. Firestore Database Setup

1. **Go to Firestore Database in Firebase Console**
2. **Create database**:
   - Choose "Start in test mode" for now
   - Select a location (choose closest to your users)
   - Click "Done"

### 6. Test the Setup

After completing the above steps:
1. Restart your Flutter app
2. Try signing up with email/password
3. Try signing in with Google

## Common Issues & Solutions

### Issue: "Google sign-in failed"
**Solution**: Make sure you've added the correct SHA-1 fingerprint to Firebase Console

### Issue: "Network error"
**Solution**: Check if Authentication is enabled in Firebase Console

### Issue: "Invalid credentials"
**Solution**: Re-download google-services.json after enabling authentication

### Issue: "User cancelled sign-in"
**Solution**: This is normal if user cancels Google sign-in dialog

## Quick Commands to Get SHA-1

```bash
# Navigate to android folder
cd "d:\New folder (4)\New folder\00. BIG 5\ai_student_assistant\android"

# Get signing report (includes SHA-1)
./gradlew signingReport
```

Look for output like:
```
Variant: debug
Store: C:\Users\YourName\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX...
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

Copy the SHA1 value and add it to Firebase Console.

## After Setup

Once you complete these steps, your authentication should work:
- ✅ Email/Password sign up and login
- ✅ Google Sign-In
- ✅ User data stored in Firestore
- ✅ Offline-first functionality

The app should then work perfectly with all authentication methods!
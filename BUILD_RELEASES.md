# WorkPulse Mobile Build Guide

This project can build:
- Android APK and AAB on Windows or GitHub Actions
- iOS IPA on GitHub Actions macOS runner

## 1. GitHub Actions workflow

Workflow file:
- [.github/workflows/mobile-release.yml](C:/Users/hieronimus.nabit/Data/my-project/Ai-flutter/hrhub/.github/workflows/mobile-release.yml)

Run it from:
- GitHub repo
- `Actions`
- `Mobile Release Build`
- `Run workflow`

Inputs:
- `platform`: `android`, `ios`, or `both`
- `build_name`: example `1.0.0`
- `build_number`: example `1`

## 2. Android signing secrets

Add these repository secrets in GitHub:
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

The workflow will create:
- `android/app/upload-keystore.jks`
- `android/key.properties`

### Encode keystore to base64 on Windows PowerShell

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\upload-keystore.jks")) | Set-Content keystore.base64
```

Copy the content of `keystore.base64` into `ANDROID_KEYSTORE_BASE64`.

## 3. iOS signing secrets

Add these repository secrets in GitHub:
- `IOS_P12_BASE64`
- `IOS_P12_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `IOS_EXPORT_OPTIONS_PLIST_BASE64`

### Files you need

- Apple distribution certificate exported as `.p12`
- Provisioning profile `.mobileprovision`
- Export options plist for IPA export

### Encode files to base64 on Windows PowerShell

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\ios_certificate.p12")) | Set-Content ios_p12.base64
```

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\WorkPulse.mobileprovision")) | Set-Content ios_profile.base64
```

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\ExportOptions.plist")) | Set-Content ios_export_options.base64
```

## 4. Example ExportOptions.plist

Use this as a starting point and adjust team id, bundle id, and method:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>ad-hoc</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>teamID</key>
  <string>YOUR_TEAM_ID</string>
  <key>provisioningProfiles</key>
  <dict>
    <key>com.beta.workpulse</key>
    <string>YOUR_PROFILE_NAME</string>
  </dict>
</dict>
</plist>
```

## 5. Artifacts produced

Android:
- `app-release.apk`
- `app-release.aab`

iOS:
- `.ipa`

All outputs are uploaded as GitHub Actions artifacts.

## 6. Important notes

- Current Android package id is `com.beta.workpulse`
- Current iOS bundle id also needs to match your Apple signing setup
- iOS build still requires valid Apple certificate and provisioning profile, even if built in GitHub Actions

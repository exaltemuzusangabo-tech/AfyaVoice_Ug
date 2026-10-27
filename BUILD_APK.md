# AfyaVoice — building the release APK

Target: `flutter build apk --release` (Android minSdk 21, Gradle 8.7, AGP 8.3.2, Flutter 3.22.3).

## Option A — Cloud build with GitHub Actions (no setup on your PC)
1. Create a free GitHub account and a new **private** repository.
2. Upload the *contents* of this folder to the repository root (including the hidden `.github` folder;
   if drag-and-drop skips it, use `git push` or create `.github/workflows/build-apk.yml` by hand).
3. (Optional) Repository **Settings > Secrets and variables > Actions > New repository secret**:
   - `MAPS_API_KEY`   – Google Maps Platform key (Maps SDK for Android enabled). Without it the map is blank.
   - `GEMINI_API_KEY` – Gemini key from Google AI Studio. Without it the app works offline
     (rule engine only; voice notes are NOT analysed).
   - Release signing (all four, optional): `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
     `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
4. Open the **Actions** tab > "Build AfyaVoice release APK" > **Run workflow**.
5. After ~8–15 min, open the finished run and download the artifact **AfyaVoice-release-apk**
   (a zip containing `app-release.apk`). Send/copy the APK to a phone and install it
   (allow "Install unknown apps" for the app you open it with).

## Option B — On any machine with Flutter 3.22.3 + Android SDK 34
```
flutter pub get
MAPS_API_KEY=your_maps_key flutter build apk --release \
  --dart-define=GEMINI_API_KEY=your_gemini_key
# output: build/app/outputs/flutter-apk/app-release.apk
```

## Build-time options (`--dart-define`)
| Name | Purpose | Default |
|---|---|---|
| `GEMINI_API_KEY` | Direct Gemini calls (text + voice) | empty = offline rule engine only |
| `GEMINI_MODEL`   | Gemini model id | `gemini-2.5-flash` |
| `AFYA_API_URL`   | Your own backend proxy (used if no direct key) | empty |

A key compiled into an APK can be extracted. For a demo this is acceptable; for real deployment use a backend proxy.

## Signing
Without a keystore the release APK is signed with the debug key: it installs and runs on phones,
but cannot be published on Google Play and cannot be updated over an APK signed with a different key.

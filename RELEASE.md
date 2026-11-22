# Releasing Mathtime With Pip

Export presets are already set up in `export_presets.cfg` (macOS, Web, iOS (iPad), Android).
In the Godot editor they're under **Project → Export…**.

| Platform | Status |
|---|---|
| macOS | ✅ Builds and runs (`build/macos/MathtimeWithPip.zip`). Ad-hoc signed, so it runs on this Mac; other Macs need Developer ID signing and notarization. |
| Web | ✅ Builds and runs (`build/web/`). Works in Safari, including on an iPad. **Published automatically** to https://natedsaint.github.io/mathtime-with-pip/ on every push to `main` (see `.github/workflows/publish-web.yml`). |
| iOS (iPad) | ⏳ Preset ready; needs the Apple steps below. |
| Android | ✅ Builds a test APK; the Play Store `.aab` builds once you add your upload key (see below). |

Command-line builds (from the project folder):
```
godot --headless --path . --export-release "macOS" build/macos/MathtimeWithPip.zip
godot --headless --path . --export-release "Web" build/web/index.html
godot --headless --path . --export-release "iOS (iPad)" build/ios/MathtimeWithPip.ipa
```

---

## iPad: App Store checklist

### 1. Apple accounts (one-time)
- [ ] Join the **Apple Developer Program** at developer.apple.com/programs ($99/year). You can enroll as an individual or as an organization (an organization needs a D-U-N-S number, which takes longer).
- [ ] Find your **Team ID** under developer.apple.com → Account → Membership details. It's a 10-character code.

### 2. Tools on this Mac (one-time)
- [ ] Install **Xcode** from the Mac App Store. It's large, roughly 10+ GB.
- [ ] Open Xcode once, accept the license, and let it install the iOS platform.
- [ ] Point the command-line tools at Xcode. This needs your password:
  ```
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  ```
- [ ] In Xcode → Settings → Accounts, sign in with your developer Apple ID.

### 3. Fill in the iOS preset
- [x] **Bundle identifier:** `io.github.natedsaint.mathtimewithpip` (set in all presets). It can never change after the first upload, so register exactly this in App Store Connect.
- [ ] **App Store Team ID:** the 10-character code from step 1.
- Already set: iPad only (`targeted_device_family`), iOS 15+, version 1.0 (build 1), the Pip app icon, a cream launch screen, and rotation in any orientation.

### 4. Try it on a real iPad
- [ ] On the iPad, turn on Settings → Privacy & Security → **Developer Mode**, then connect it to the Mac with a cable.
- [ ] Easiest path: in the iOS preset, tick **Export Project Only**. Export, open the generated `.xcodeproj` in Xcode, pick your iPad, and press ▶ Run.
- Things to check:
  - Touch on the keypad
  - Rotating between portrait and landscape
  - Split View
  - Sound with the silent switch on and off
  - Records surviving an app restart

### 5. App Store Connect
Everything to paste in is ready in **`store/listing.md`**: name, subtitle, description, keywords, privacy answers, age rating and Kids Category notes. The screenshots are in **`store/screenshots/`**, and the privacy policy page is in **`store/privacy-policy.html`** (fill in your name and email, then host it).

- [ ] At appstoreconnect.apple.com → Apps → **+ New App**: choose iOS, pick a name, use the same bundle ID, and make up a SKU (e.g. `mathtime-001`).
  - The name must be unique on the store. If "Mathtime With Pip" is taken, `store/listing.md` has backup names.
- [ ] **Category:** Education.
- [ ] **Age rating questionnaire:** answer "None" to everything, which gives a 4+ rating.
- [ ] **Kids Category (optional but a good fit):** choose an age band (5 & under, 6–8, or 9–11). Mathtime With Pip already meets the rules: no ads, no analytics, no outside links, and no purchases.
- [ ] **App Privacy:** "Data Not Collected". The game saves progress only on the device.
- [ ] **Privacy policy URL:** required, especially for Kids. A one-paragraph page saying the app collects no data is enough. It needs to live at some public URL.
- [ ] **Screenshots:** at least one set for **13-inch iPad** (2064×2752 or 2048×2732, portrait or landscape). The dev screenshot tool can make these at that size, for example:
  ```
  godot --path . --resolution 2048x2732 -- --shot=game --mode=0 --ops=2 --out=ipad1.png
  ```
- [ ] Description, keywords, and support URL.

### 6. Upload and submit
- [ ] Set the iOS preset's release **export method** to *App Store* (already the default) and export a release `.ipa`. If you used Export Project Only, use Xcode → Product → **Archive** instead.
- [ ] Upload with Xcode's Organizer or Apple's **Transporter** app.
- [ ] Test it through **TestFlight** on your iPad first, then attach the build to the version and **Submit for Review**. Review usually takes 1–3 days.
- For every update, bump `application/version` (the build number) and, for user-visible releases, `application/short_version`.

---

## Quick iPad test today (no Apple account needed)
The web build runs in Safari on an iPad on the same Wi-Fi:
1. From the project folder, run `python3 -m http.server 8060 --directory build/web`. On the iPad, open `http://<this Mac's IP>:8060`. The Mac's IP is in System Settings → Wi-Fi → Details.
2. Share → **Add to Home Screen** gives a full-screen launcher icon.

The web version uses Godot's built-in font, because browsers can't use the Mac's rounded font. Records are saved in that browser only.

## Android: Google Play checklist

### Already set up on this Mac
- Java 17 (Homebrew `openjdk@17`) and the Android SDK in `~/Library/Android/sdk`, with platforms 35 and 36, build-tools 35.0.1 and 36.1.0, and platform-tools. Licenses are accepted.
- Godot's Editor Settings point at both, and the debug signing key was created automatically.
- Godot's Android build template is installed in `android/build/`. Its Gradle output is git-ignored.
- Two presets:
  - **Android**: a quick APK for sideloading onto a tablet (`build/android/MathtimeWithPip.apk`).
  - **Android (Play Store)**: a Gradle build that makes an `.aab`, the format Google Play requires. The debug build of it works; the release build needs your upload key (step 2 below).

```
godot --headless --path . --export-debug "Android" build/android/MathtimeWithPip.apk
godot --headless --path . --export-release "Android (Play Store)" build/android/MathtimeWithPip.aab
```

### 1. Try it on an Android tablet
- [ ] On the tablet, turn on Developer options (tap Settings → About → Build number 7 times), then **USB debugging**.
- [ ] Connect it with a cable and run:
  ```
  ~/Library/Android/sdk/platform-tools/adb install -r build/android/MathtimeWithPip.apk
  ```
  You can also copy the APK to the tablet and open it there.

### 2. Make your upload key (one-time, keep it safe)
This key identifies you to Google Play. **Back it up and don't lose the password.** Without it you'd have to ask Google to reset your upload key.
```
/opt/homebrew/opt/openjdk@17/bin/keytool -genkeypair -v -keystore ~/keys/mathtime-upload.keystore \
  -alias mathtime -keyalg RSA -keysize 2048 -validity 10000
```
It will ask you to choose a password and fill in your name. Then in Godot → Project → Export → **Android (Play Store)** → Keystore → Release, enter the keystore path, the alias (`mathtime`) and the password. Godot keeps these in `.godot/export_credentials.cfg`, which is not committed. You can also use the environment variables `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER` and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`.

### 3. Package name
- [x] Package name: `io.github.natedsaint.mathtimewithpip`, the same as the iPad bundle ID. It can never change after the first upload.

### 4. Google Play Console
- [ ] Create a developer account at play.google.com/console ($25 one-time, plus identity verification).
- [ ] **New personal accounts must run a closed test first.** At least 12 testers need to have the app installed for 14 days before you can publish to everyone. Family and friends with Android devices count.
- [ ] Create the app, choosing *App* and *Free*. Let Google manage the app signing key (**Play App Signing**); your key from step 2 is only the *upload* key.
- [ ] **Target audience:** choosing ages under 13 puts the app under Google's **Families policy**. Mathtime With Pip already fits it: no ads, no data collection, no outside links.
- [ ] **Data safety form:** no data collected, no data shared.
- [ ] **Content rating:** fill in the IARC questionnaire. All answers are "No", which should give Everyone / PEGI 3.
- [ ] **Store listing:** reuse the text from `store/listing.md`. The short description is 80 characters max; the subtitle plus part of the promo text works. You also need:
  - a 512×512 icon (`icon.png` scaled down),
  - a **1024×500 feature graphic**,
  - at least 2 phone screenshots, plus tablet screenshots (the iPad shots in `store/screenshots/` work for tablets).
- [ ] Upload `MathtimeWithPip.aab` to the closed-testing track. After the 14 days, promote it to production.
- For every update, bump `version/code` by 1, and `version/name` for user-visible releases.

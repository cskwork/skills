# Capture commands by surface

Use only the section for the surface in the brief.

## iOS Simulator

```bash
xcrun simctl list devices booted                       # confirm the running device
xcrun simctl listapps booted | grep CFBundleIdentifier  # find the app's bundle id
xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 \
  --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4
xcrun simctl ui booted appearance light                # or dark, to match the brand
xcrun simctl io booted screenshot --type=png assets/home.png
xcrun simctl io booted recordVideo --codec=h264 --force assets/feature.mp4 &  # stop: kill -INT $!
xcrun simctl openurl booted "<scheme>://<path>"        # jump to a screen by deep link
xcrun simctl status_bar booted clear                   # restore when done
```

Navigate with `idb ui tap X Y` / `idb ui swipe` when `idb` is installed, otherwise with a computer-use tool, or ask the user to drive while you record. Brand sources: `Assets.xcassets/AppIcon.appiconset`, `*.colorset/Contents.json`, `Localizable.strings` or `.xcstrings`, `Info.plist` display name.

## Android emulator

```bash
adb devices
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command enter
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
adb exec-out screencap -p > assets/home.png
adb shell screenrecord /sdcard/feature.mp4             # Ctrl-C to stop, max 180 s
adb pull /sdcard/feature.mp4 assets/
adb shell input tap X Y; adb shell input swipe X1 Y1 X2 Y2 300
adb shell am broadcast -a com.android.systemui.demo -e command exit
```

Brand sources: `res/mipmap-*/ic_launcher*`, `res/values/colors.xml` or Compose theme, `res/values/strings.xml`.

## Web

Use Playwright (or the browser skill available) with `deviceScaleFactor: 2` at the frame's aspect, for example 1440×900 for desktop or 390×844 for mobile web. Take a full-resolution screenshot of each state. For interactions, capture a dense screenshot sequence of the motion or record the screen with `ffmpeg -f avfoundation`; Playwright's `recordVideo` is too low quality for hero shots. Brand sources: `public/` icons, `manifest.json`, CSS variables, Tailwind config.

## macOS desktop app

`screencapture -o -l <windowID> assets/home.png` for a shadowless window shot; get the window ID from a small Swift or Python `CGWindowListCopyWindowInfo` call. Record with `ffmpeg -f avfoundation` cropped to the window.

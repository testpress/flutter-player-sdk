## 2.2.34-beta.1

- Automatically select the optimal Android PlatformView composition mode based on device Widevine security level:
  - Widevine L3 devices automatically use Texture Layer Composition (`initSurfaceAndroidView`) and `TextureView` for smooth 60/120 FPS scrolling and reduced CPU usage.
  - Widevine L1 devices use Hybrid Composition (`initExpensiveAndroidView`) with `SurfaceView` for hardware-secure DRM playback.

## 2.2.33

- Added `random` watermark animation type support (`WatermarkAnimationType.random`) across Android and iOS.
- Upgraded `TPStreamsAndroidPlayer` to 1.2.9 on Android.
- Upgraded `TPStreamsSDK` to 1.2.41 on iOS.

## 2.2.32

**Android**

- Upgraded TPStreamsAndroidPlayer to 1.2.8.
- Bridged `allowFallbackToL3` parameter: enables automatic fallback to software decryption when hardware-secured DRM decryption fails, preventing complete playback failure on unsupported devices.
- Watermarks now render within the video content area instead of the full player view.
- Live streams now continue playback when the live feed ends before the VOD recording is ready.
- HTTP 401/403/404 errors from media CDN are correctly classified instead of being treated as network failures.

**iOS**

- Upgraded TPStreamsSDK to 1.2.40.
- Watermarks now anchor to the video content rect instead of the full player view.
- Live video playback now works while transcoding is in progress.

## 2.2.31

**iOS**

- Fixed an issue where audio continued playing after the Flutter widget was disposed due to retain cycles in Pigeon channel handlers (#57).
- Added weak-reference proxies and explicit channel/delegate cleanup to ensure proper deallocation during disposal and teardown.

## 2.2.30

**iOS**

- Added watermark support on iOS: `setWatermarks` and `clearWatermarks` now apply a player config instead of being ignored (#55).
- The player config is now always built and applied consistently across player initialization and watermark updates (#55).
- Upgraded TPStreamsSDK to 1.2.39 in the podspec and Package.swift.

## 2.2.29

- Added auto-resume support: playback now restores to the last watched position for signed-in viewers on both platforms.
  - `TPStreamPlayer` now accepts a `userId` parameter to identify the viewer.
- Upgraded iOS Player SDK to 1.2.38 and Android Player SDK to 1.2.7.

## 2.2.28

**iOS**

- Use a per-player AVContentKeySession for offline DRM, ensuring expired licenses are validated on every playback instead of being bypassed by cached content keys from a shared session (#153)
- Migrate RealmSwift from 10.54.2 to 20.0.4 (#154)
- Make offline asset deletion thread-safe by carrying only plain asset and content ids across threads, and running encryption-key cleanup on the content key delegate queue (#155)

**Android**

- Upgrade `androidx.media3` from 1.7.1 to 1.8.1, the last release line that supports minSdk 21 (1.9+ raises the minimum to 23) (#117)
- 1.8.1 includes playback fixes: VP9 Widevine playback on some devices, an extended detached-surface workaround for Lenovo/Motorola/realme devices, Bluetooth A/V sync after pause-resume, and several DASH/HLS fixes
- Adapt download preparation to the updated `DownloadHelper.Callback.onPrepared` callback signature in 1.8.0 (#117)

## 2.2.27

- Added `resolution` parameter to `TPStreamPlayer` to set the initial playback quality for online videos on Android and iOS.
- Updated iOS Player SDK to 1.2.35.

## 2.2.26

- Upgraded Android Player SDK to 1.2.4 for improved stability and performance.
- Added `setWatermarks` and `clearWatermarks` APIs to display text watermark overlays on video with configurable positioning, styling, opacity, and animation.

## 2.2.25

- Upgraded Android Player SDK to 1.2.3 for improved stability and performance.
- Fixed an issue where setting maximum video resolution would fail silently on Android.

## 2.2.24

- Migrated iOS dependency management from CocoaPods to Swift Package Manager (SPM) for faster and more reliable builds.
- Updated iOS Player SDK to 1.2.34 with fixes for CocoaPods resource loading, initialization handling, and invalid playback URL reporting.

## 2.2.23

- Added totalSize and downloadedSize to DownloadAsset to support download progress calculation.
- Added thumbnailUrl to DownloadAsset to support displaying asset thumbnails.

## 2.2.22

- Fix layout gaps and rotation issues by removing the internal SafeArea handling
- Add public API to control auto fullscreen on device rotation

## 2.2.21

- Update TPStreams Android Player to 1.1.16 for improved fullscreen playback stability.

## 2.2.20

- Fixed an issue on iOS where the onPlayerCreated callback was not triggered for offline playback when currentItem was initialized before KVO observer registration.

## 2.2.19

- Added support for pre-selected resolution in `startDownload` to skip the quality picker.
- Updated Android native SDK dependency to 1.1.14.

## 2.2.18

- Added global JWT-based authentication to simplify integration for Testpress users.
- Kept playback and download APIs backward compatible while safely handling optional authentication parameters.

## 2.2.17

- Added the missing Start Download API implementation on iOS.
- Fixed an audio leak issue occurring after player disposal on iOS.

## 2.2.16

### Features
- Revamped player UI for improved usability and visual consistency.

### Bug Fixes
- Bug fixes and code optimization.

## 2.2.16-beta.3

### Features
- Restored multi-provider support for TPStreams and Testpress backends in Android.
- Updated Android native SDK dependency to v1.1.12.

## 2.2.16-beta.2

### Fixes
- Bug fixes and code optimization

## 2.2.16-beta.1

### Improvements
- Revamped player UI for improved usability and visual consistency
### Breaking Changes
- Removed `Testpress` provider support from SDK initialization.

## 2.2.15

- Updated iOS SDK dependency to 1.2.29
- Added support for DRM-protected live stream playback on iOS

## 2.2.14

- Added `enterFullScreen()` and `exitFullScreen()` APIs for programmatic fullscreen control.
- Updated iOS SDK dependency version.

## 2.2.13

- Added `setMaxResolution` API to cap video playback resolution in Android.
- Fixed iOS crash occurring on multiple player dispose calls.
- Updated Android SDK dependency version.

## 2.2.12

- Added `onReplay` callback to listen for replay button clicks.
- Added support for configurable auto-play.
- Updated Android and iOS player SDK versions.

## 2.2.11

- Player preference config to control UI elements in Android and iOS.

## 2.2.10

- Added `onAccessTokenExpired` callback to support seamless token refreshing in Android.

## 2.2.9

- Added `onBeforeFullScreenEnter` and `onBeforeFullScreenExit` callbacks to allow apps to respond before fullscreen transitions occur
- Updated Android SDK dependency version

## 2.2.8

- Added support for launching player in fullscreen and (dependency)iOSPlayerSDK version update

## 2.2.7

- Added meta data support on the startDownload API in android.

## 2.2.6

- Added metadata support to download assets in android and iOS.

## 2.2.5

- Updated `compileSdkVersion` to **34** for improved compatibility with newer Android Gradle Plugin versions.

## 2.2.4

- Integrated Android Player SDK **v3.1.8** for enhanced playback performance and stability.

## 2.2.3

- Added support for listeners to monitor fullscreen state changes.

## 2.2.1

- Bug fixes and code optimization.

## 2.1.9

- Bug fixes and code optimization.

## 2.1.8

- Bug fixes and code optimization.

## 2.1.7

- Bug fixes and code optimization.

## 2.1.6

- Added Offline Download support with APIs to start, pause, resume, cancel and delete downloads.
- Bug fixes and code optimization.

## 2.1.5

- Bug fixes and code optimization.

## 2.1.4

- Bug fixes and code optimization.

## 2.1.3

- Bug fixes and code optimization.

## 2.1.1

- Bug fixes and code optimization.
- Added live streaming support in iOS.

## 2.1.0

- Bug fixes.
- Added privacy manifest file in iOS.

## 2.0.9

- Added live streaming support.
- Bug fixes.

## 2.0.7

- Bug fixes.

## 2.0.6

- Bug fixes.

## 2.0.5

**Features**

- Enhanced control over video playback with new APIs:
  - Play, pause, stop, and seek video playback programmatically.
  - Enables seamless integration of custom controls and gestures.

- Added support for listeners to monitor player state changes:
  - Register callbacks for real-time updates on playing, paused, buffering, etc.
  - Facilitates improved integration with the application's UI.

## 2.0.0

- Integrate our Native player SDKs for secure playback with support to play Non-DRM, DRM and AES encrypted videos.

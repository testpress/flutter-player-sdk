## 2.0.0

- Integrate our Native player SDKs for secure playback with support to play Non-DRM, DRM and AES encrypted videos.

## 2.0.5
**Features**

- Enhanced control over video playback with new APIs:
  - Play, pause, stop, and seek video playback programmatically.
  - Enables seamless integration of custom controls and gestures.

- Added support for listeners to monitor player state changes:
  - Register callbacks for real-time updates on playing, paused, buffering, etc.
  - Facilitates improved integration with the application's UI.

## 2.0.6

- Bug fixes.

## 2.0.7

- Bug fixes.

## 2.0.9

- Added live streaming support.
- Bug fixes.

## 2.1.0

- Bug fixes.
- Added privacy manifest file in iOS.

## 2.1.1

- Bug fixes and code optimization.
- Added live streaming support in iOS.

## 2.1.3
- Bug fixes and code optimization.

## 2.1.4
- Bug fixes and code optimization.

## 2.1.5
- Bug fixes and code optimization.

## 2.1.6
- Added Offline Download support with APIs to start, pause, resume, cancel and delete downloads.
- Bug fixes and code optimization.

## 2.1.7
- Bug fixes and code optimization.

## 2.1.8
- Bug fixes and code optimization.

## 2.1.9
- Bug fixes and code optimization.

## 2.2.1
- Bug fixes and code optimization.

## 2.2.3
- Added support for listeners to monitor fullscreen state changes.

## 2.2.4
- Integrated Android Player SDK **v3.1.8** for enhanced playback performance and stability.

## 2.2.5
- Updated `compileSdkVersion` to **34** for improved compatibility with newer Android Gradle Plugin versions.

## 2.2.6
- Added metadata support to download assets in android and iOS.

## 2.2.7
- Added meta data support on the startDownload API in android.

## 2.2.8
- Added support for launching player in fullscreen and (dependency)iOSPlayerSDK version update

## 2.2.9
- Added `onBeforeFullScreenEnter` and `onBeforeFullScreenExit` callbacks to allow apps to respond before fullscreen transitions occur
- Updated Android SDK dependency version

## 2.2.10
- Added `onAccessTokenExpired` callback to support seamless token refreshing in Android.

## 2.2.11
- Player preference config to control UI elements in Android and iOS.

## 2.2.12
- Added `onReplay` callback to listen for replay button clicks.
- Added support for configurable auto-play.
- Updated Android and iOS player SDK versions.

## 2.2.13
- Added `setMaxResolution` API to cap video playback resolution in Android.
- Fixed iOS crash occurring on multiple player dispose calls.
- Updated Android SDK dependency version.

## 2.2.14
- Added `enterFullScreen()` and `exitFullScreen()` APIs for programmatic fullscreen control.
- Updated iOS SDK dependency version.

## 2.2.15
- Updated iOS SDK dependency to 1.2.29
- Added support for DRM-protected live stream playback on iOS

## 2.2.16-beta.1

### Improvements
- Revamped player UI for improved usability and visual consistency
### Breaking Changes
- Removed `Testpress` provider support from SDK initialization.

## 2.2.16-beta.2

### Fixes
- Bug fixes and code optimization

## 2.2.16-beta.3

### Features
- Restored multi-provider support for TPStreams and Testpress backends in Android.
- Updated Android native SDK dependency to v1.1.12.

## 2.2.16

### Features
- Revamped player UI for improved usability and visual consistency.

### Bug Fixes
- Bug fixes and code optimization.

## 2.2.17
- Added the missing Start Download API implementation on iOS.
- Fixed an audio leak issue occurring after player disposal on iOS.

## 2.2.18
- Added global JWT-based authentication to simplify integration for Testpress users.
- Kept playback and download APIs backward compatible while safely handling optional authentication parameters.

## 2.2.19
- Added support for pre-selected resolution in `startDownload` to skip the quality picker.
- Updated Android native SDK dependency to 1.1.14.

## 2.2.20
- Fixed an issue on iOS where the onPlayerCreated callback was not triggered for offline playback when currentItem was initialized before KVO observer registration.

## 2.2.21
- Update TPStreams Android Player to 1.1.16 for improved fullscreen playback stability.

## 2.2.22
- Fix layout gaps and rotation issues by removing the internal SafeArea handling
- Add public API to control auto fullscreen on device rotation

## 2.2.23
- Added totalSize and downloadedSize to DownloadAsset to support download progress calculation.
- Added thumbnailUrl to DownloadAsset to support displaying asset thumbnails.

## 2.2.24

- Migrated iOS dependency management from CocoaPods to Swift Package Manager (SPM) for faster and more reliable builds.
- Updated iOS Player SDK to 1.2.34 with fixes for CocoaPods resource loading, initialization handling, and invalid playback URL reporting.

## 2.2.25

- Upgraded Android Player SDK to 1.2.3 for improved stability and performance.
- Fixed an issue where setting maximum video resolution would fail silently on Android.

## 2.2.26

- Upgraded Android Player SDK to 1.2.4 for improved stability and performance.
- Added `setWatermarks` and `clearWatermarks` APIs to display text watermark overlays on video with configurable positioning, styling, opacity, and animation.

## 2.2.27

- Added `resolution` parameter to `TPStreamPlayer` to set the initial playback quality for online videos on Android and iOS.
- Updated iOS Player SDK to 1.2.35.


// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "tpstreams_player_sdk",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "tpstreams-player-sdk", targets: ["tpstreams_player_sdk"])
    ],
    dependencies: [
        .package(path: "../FlutterFramework"),
        .package(url: "https://github.com/testpress/iOSPlayerSDK.git", from: "1.2.40")
    ],
    targets: [
        .target(
            name: "tpstreams_player_sdk",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "TPStreamsSDK", package: "iOSPlayerSDK")
            ]
        )
    ]
)

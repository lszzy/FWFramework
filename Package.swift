// swift-tools-version:5.9

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "FWFramework",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "FWFramework",
            targets: ["FWFramework"]
        ),
        .library(
            name: "FWUIKit",
            targets: ["FWUIKit"]
        ),
        .library(
            name: "FWSwiftUI",
            targets: ["FWSwiftUI"]
        ),
        .library(
            name: "FWPluginCalendar",
            targets: ["FWPluginCalendar"]
        ),
        .library(
            name: "FWPluginContacts",
            targets: ["FWPluginContacts"]
        ),
        .library(
            name: "FWPluginTracking",
            targets: ["FWPluginTracking"]
        ),
        .library(
            name: "FWPluginBiometry",
            targets: ["FWPluginBiometry"]
        ),
        .library(
            name: "FWPluginBluetooth",
            targets: ["FWPluginBluetooth"]
        ),
        .library(
            name: "FWPluginMotion",
            targets: ["FWPluginMotion"]
        ),
        .library(
            name: "FWPluginSpeech",
            targets: ["FWPluginSpeech"]
        ),
        .library(
            name: "FWPluginMacros",
            targets: ["FWPluginMacros"]
        ),
        .library(
            name: "FWPluginSDWebImage",
            targets: ["FWPluginSDWebImage"]
        ),
        .library(
            name: "FWPluginLottie",
            targets: ["FWPluginLottie"]
        ),
        .library(
            name: "FWPluginAlamofire",
            targets: ["FWPluginAlamofire"]
        ),
        .library(
            name: "FWPluginObjectMapper",
            targets: ["FWPluginObjectMapper"]
        ),
        .library(
            name: "FWPluginMMKV",
            targets: ["FWPluginMMKV"]
        ),
        .library(
            name: "MMKV",
            targets: ["MMKV"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.9.0"),
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
        .package(url: "https://github.com/tristanhimmelman/ObjectMapper.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .target(
            name: "FWFramework",
            path: "Sources/FWFramework",
            resources: [.copy("../PrivacyInfo.xcprivacy")],
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWUIKit",
            dependencies: ["FWFramework"],
            path: "Sources/FWUIKit",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWSwiftUI",
            dependencies: ["FWFramework"],
            path: "Sources/FWSwiftUI",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginCalendar",
            dependencies: ["FWFramework"],
            path: "Sources/FWPlugin/Authorize/Calendar",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginContacts",
            dependencies: ["FWFramework"],
            path: "Sources/FWPlugin/Authorize/Contacts",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginTracking",
            dependencies: ["FWFramework"],
            path: "Sources/FWPlugin/Authorize/Tracking",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginBiometry",
            dependencies: ["FWFramework"],
            path: "Sources/FWPlugin/Authorize/Biometry",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginBluetooth",
            dependencies: ["FWFramework"],
            path: "Sources/FWPlugin/Authorize/Bluetooth",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginMotion",
            dependencies: ["FWFramework"],
            path: "Sources/FWPlugin/Authorize/Motion",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginSpeech",
            dependencies: ["FWFramework"],
            path: "Sources/FWPlugin/Authorize/Speech",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .macro(
            name: "FWMacroMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/FWPlugin/Macros/FWMacroMacros"
        ),
        .target(
            name: "FWPluginMacros",
            dependencies: [
                "FWFramework",
                "FWMacroMacros"
            ],
            path: "Sources/FWPlugin/Macros/FWPluginMacros",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
                .define("FWPluginMacros")
            ]
        ),
        .target(
            name: "FWPluginSDWebImage",
            dependencies: [
                "FWFramework",
                .product(name: "SDWebImage", package: "SDWebImage")
            ],
            path: "Sources/FWPlugin/SDWebImage",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginLottie",
            dependencies: [
                "FWFramework",
                .product(name: "Lottie", package: "lottie-ios")
            ],
            path: "Sources/FWPlugin/Lottie",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginAlamofire",
            dependencies: [
                "FWFramework",
                .product(name: "Alamofire", package: "Alamofire")
            ],
            path: "Sources/FWPlugin/Alamofire",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginObjectMapper",
            dependencies: [
                "FWFramework",
                .product(name: "ObjectMapper", package: "ObjectMapper")
            ],
            path: "Sources/FWPlugin/ObjectMapper",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginMMKV",
            dependencies: [
                "FWFramework",
                "MMKV"
            ],
            path: "Sources/FWPlugin/MMKV",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .binaryTarget(
            name: "MMKV",
            url: "https://github.com/lszzy/FWFramework/releases/download/7.0.0/MMKV.xcframework.zip",
            checksum: "9db49d734916e9aee3926ffbf162a976f03aafc294eac74b6979e3dbdf66411b"
        )
    ]
)

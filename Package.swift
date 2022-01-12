// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FWFramework",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "FWFramework",
            targets: ["FWFramework"]),
        .library(
            name: "FWFrameworkCompatible",
            targets: ["FWFramework", "FWFrameworkCompatible"]),
        .library(
            name: "FWFrameworkAppleMusic",
            targets: ["FWFramework", "FWFrameworkAppleMusic"]),
        .library(
            name: "FWFrameworkCalendar",
            targets: ["FWFramework", "FWFrameworkCalendar"]),
        .library(
            name: "FWFrameworkContacts",
            targets: ["FWFramework", "FWFrameworkContacts"]),
        .library(
            name: "FWFrameworkMicrophone",
            targets: ["FWFramework", "FWFrameworkMicrophone"]),
        .library(
            name: "FWFrameworkTracking",
            targets: ["FWFramework", "FWFrameworkTracking"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "FWFramework",
            path: "FWFramework/Classes",
            sources: [
                "FWFramework/Kernel",
                "FWFramework/Service",
                "FWFramework/Toolkit"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("FWFramework/Kernel"),
                .headerSearchPath("FWFramework/Service"),
                .headerSearchPath("FWFramework/Toolkit"),
                .headerSearchPath("include")
            ]),
        .target(
            name: "FWFrameworkCompatible",
            dependencies: ["FWFramework"],
            path: "FWFramework/Classes/Module/Compatible",
            cSettings: [
                .define("FWFrameworkSPM", to: "1")
            ],
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWFrameworkSPM")
            ]),
        .target(
            name: "FWFrameworkAppleMusic",
            dependencies: ["FWFramework"],
            path: "FWFramework/Classes/Module/AppleMusic",
            cSettings: [
                .define("FWFrameworkSPM", to: "1")
            ],
            swiftSettings: [
                .define("FWFrameworkSPM")
            ]),
        .target(
            name: "FWFrameworkCalendar",
            dependencies: ["FWFramework"],
            path: "FWFramework/Classes/Module/Calendar",
            cSettings: [
                .define("FWFrameworkSPM", to: "1")
            ],
            swiftSettings: [
                .define("FWFrameworkSPM")
            ]),
        .target(
            name: "FWFrameworkContacts",
            dependencies: ["FWFramework"],
            path: "FWFramework/Classes/Module/Contacts",
            cSettings: [
                .define("FWFrameworkSPM", to: "1")
            ],
            swiftSettings: [
                .define("FWFrameworkSPM")
            ]),
        .target(
            name: "FWFrameworkMicrophone",
            dependencies: ["FWFramework"],
            path: "FWFramework/Classes/Module/Microphone",
            cSettings: [
                .define("FWFrameworkSPM", to: "1")
            ],
            swiftSettings: [
                .define("FWFrameworkSPM")
            ]),
        .target(
            name: "FWFrameworkTracking",
            dependencies: ["FWFramework"],
            path: "FWFramework/Classes/Module/Tracking",
            cSettings: [
                .define("FWFrameworkSPM", to: "1")
            ],
            swiftSettings: [
                .define("FWFrameworkSPM")
            ]),
    ]
)

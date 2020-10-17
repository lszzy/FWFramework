// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FWFramework",
    products: [
        .library(
            name: "FWFramework",
            targets: ["FWFramework/Framework"]
        ),
    ],
    targets: [
        .target(
            name: "FWFramework/Framework",
            path: "FWFramework/Framework/Kernel",
            exclude: [
                "FWLog.swift",
                "FWMacro.swift",
                "FWPromise.swift",
                "FWTest.swift"
            ]
        ),
    ]
)

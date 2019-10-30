// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TOCropViewController",
    platforms: [
        .iOS(.v8)
    ],
    products: [
        .library(
            name: "TOCropViewController",
            targets: ["TOCropViewController"]
        )
    ],
    targets: [
        .target(
            name: "TOCropViewController",
            path: "Objective-C/TOCropViewController",
            sources: [
                ".",
                "Categories",
                "Constants",
                "Models",
                "Resources",
                "Supporting",
                "Views",
            ],
            publicHeadersPath: "Include"
        )
    ]
)

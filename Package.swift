// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var platforms: [SupportedPlatform] {
    #if compiler(<5.3)
        return [.iOS(.v8)]
    #else
        // Xcode 12 (which ships with Swift 5.3) drops support for iOS 8
        return[.iOS(.v9)]
    #endif
}

let package = Package(
    name: "TOCropViewController",
    defaultLocalization: "en",
    platforms: platforms,
    products: [
        .library(
            name: "TOCropViewController",
            targets: ["TOCropViewController"]
        ),
        .library(
            name: "CropViewController",
            targets: ["CropViewController"]
        )
    ],
    targets: [
        .target(
            name: "TOCropViewController",
            path: "Objective-C/TOCropViewController/",
			exclude:["Supporting/Info.plist"],
            resources: [.process("Resources")],
            publicHeadersPath: "include"
        ),
        .target(
            name: "CropViewController",
            dependencies: ["TOCropViewController"],
            path: "Swift/CropViewController/",
			exclude:["Info.plist"],
            sources: ["CropViewController.swift"]
        )
    ]
)

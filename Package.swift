// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BrotherPrint",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "BrotherPrint",
            targets: ["BrotherPrintPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", branch: "main")
    ],
    targets: [
        .target(
            name: "BrotherPrintPlugin",
            dependencies: [
                "BRLMPrinterKit",
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/BrotherPrintPlugin"),
        .binaryTarget(
            name: "BRLMPrinterKit",
            path: "ios/Frameworks/BRLMPrinterKit.xcframework"),
        .testTarget(
            name: "BrotherPrintPluginTests",
            dependencies: ["BrotherPrintPlugin"],
            path: "ios/Tests/BrotherPrintPluginTests")
    ]
)

// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

var swiftSettings: [SwiftSetting] = [
    .define("SQLITE_ENABLE_FTS5"),
]
var cSettings: [CSetting] = []
var dependencies: [PackageDescription.Package.Dependency] = []

// Don't rely on those environment variables. They are ONLY testing conveniences:
// $ SQLITE_ENABLE_PREUPDATE_HOOK=1 make test_SPM
if ProcessInfo.processInfo.environment["SQLITE_ENABLE_PREUPDATE_HOOK"] == "1" {
    swiftSettings.append(.define("SQLITE_ENABLE_PREUPDATE_HOOK"))
    cSettings.append(.define("GRDB_SQLITE_ENABLE_PREUPDATE_HOOK"))
}

// The SPI_BUILDER environment variable enables documentation building
// on <https://swiftpackageindex.com/groue/GRDB.swift>. See
// <https://github.com/SwiftPackageIndex/SwiftPackageIndex-Server/issues/2122>
// for more information.
//
// SPI_BUILDER also enables the `make docs-localhost` command.
if ProcessInfo.processInfo.environment["SPI_BUILDER"] == "1" {
    dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"))
}

let package = Package(
    name: "grdb-sqlite-bundled",
    defaultLocalization: "en", // for tests
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v7),
    ],
    products: [
        .library(name: "GRDBSQLite", targets: ["GRDBSQLite"]),
        .library(name: "GRDB", targets: ["GRDB"]),
        .library(name: "GRDB-dynamic", type: .dynamic, targets: ["GRDB"]),
    ],
    dependencies: dependencies,
    targets: [
        // Bundled SQLite amalgamation — eliminates host system SQLite dependency.
        // Compiled from source with the features GRDB needs.
        .target(
            name: "GRDBSQLite",
            dependencies: [],
            cSettings: [
                .define("NDEBUG"),
                .define("SQLITE_THREADSAFE", to: "1"),
                .define("SQLITE_ENABLE_FTS5"),
                .define("SQLITE_ENABLE_SNAPSHOT"),
                .define("SQLITE_ENABLE_COLUMN_METADATA"),
                .define("SQLITE_ENABLE_DBSTAT_VTAB"),
                .define("SQLITE_ENABLE_FTS3"),
                .define("SQLITE_ENABLE_FTS3_PARENTHESIS"),
                .define("SQLITE_ENABLE_FTS3_TOKENIZER"),
                .define("SQLITE_ENABLE_RTREE"),
                .define("SQLITE_ENABLE_UNLOCK_NOTIFY"),
                .define("SQLITE_MAX_VARIABLE_NUMBER", to: "250000"),
                .define("HAVE_USLEEP", to: "1"),
            ]),
        .target(
            name: "GRDB",
            dependencies: ["GRDBSQLite"],
            path: "GRDB",
            resources: [.copy("PrivacyInfo.xcprivacy")],
            cSettings: cSettings,
            swiftSettings: swiftSettings),
        .testTarget(
            name: "GRDBTests",
            dependencies: ["GRDB"],
            path: "Tests",
            exclude: [
                "CocoaPods",
                "Crash",
                "CustomSQLite",
                "GRDBManualInstall",
                "GRDBTests/getThreadsCount.c",
                "Info.plist",
                "Performance",
                "SPM",
                "Swift6Migration",
                "generatePerformanceReport.rb",
                "parsePerformanceTests.rb",
            ],
            resources: [
                .copy("GRDBTests/Betty.jpeg"),
                .copy("GRDBTests/InflectionsTests.json"),
                .copy("GRDBTests/Issue1383.sqlite"),
            ],
            cSettings: cSettings,
            swiftSettings: swiftSettings + [
                // Tests still use the Swift 5 language mode.
                .swiftLanguageMode(.v5),
                .enableUpcomingFeature("InferSendableFromCaptures"),
                .enableUpcomingFeature("GlobalActorIsolatedTypesUsability"),
            ])
    ],
    swiftLanguageModes: [.v6]
)

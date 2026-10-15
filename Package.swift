// swift-tools-version: 6.0
// Copyright 2026 Ergentics, LLC
// SPDX-License-Identifier: Apache-2.0
import PackageDescription
let package = Package(
    name: "ChangeFoundation",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "ChangeFoundation", targets: ["ChangeFoundation"]),
        .library(name: "PracticeLedger", targets: ["PracticeLedger"]),
    ],
    targets: [
        .target(name: "ChangeFoundation"),
        .target(name: "PracticeLedger", dependencies: ["ChangeFoundation"]),
        .testTarget(name: "ChangeFoundationTests", dependencies: ["ChangeFoundation"], resources: [.copy("vectors.json")]),
        .testTarget(name: "PracticeLedgerTests", dependencies: ["PracticeLedger"], resources: [.copy("vectors.json")]),
    ]
)

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
        .library(name: "OracleAdmission", targets: ["OracleAdmission"]),
    ],
    targets: [
        .target(name: "ChangeFoundation"),
        .target(name: "PracticeLedger", dependencies: ["ChangeFoundation"]),
        .target(name: "OracleAdmission", dependencies: ["PracticeLedger"]),
        .executableTarget(
            name: "FoundationBench",
            dependencies: ["ChangeFoundation", "PracticeLedger", "OracleAdmission"]),
        .testTarget(name: "ChangeFoundationTests", dependencies: ["ChangeFoundation"], resources: [.copy("vectors.json")]),
        .testTarget(name: "PracticeLedgerTests", dependencies: ["PracticeLedger"], resources: [.copy("vectors.json")]),
        .testTarget(name: "OracleAdmissionTests", dependencies: ["OracleAdmission"], resources: [.copy("vectors.json")]),
    ]
)

/*
 This source file is part of the Swift.org open source project
 
 Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception
 
 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
 */

import XCTest
import TestSupport
import Basic
import PackageModel
import Workspace

class InitTests: XCTestCase {

    // MARK: Basic package creation for each package type.
    
    func testInitPackageEmpty() throws {
        mktmpdir { tmpPath in
            var fs = localFileSystem
            let path = tmpPath.appending(component: "Foo")
            try fs.createDirectory(path)
            
            // Create the package
            let initPackage = try InitPackage(destinationPath: path, packageType: InitPackage.PackageType.empty)
            var progressMessages = [String]()
            initPackage.progressReporter = { message in
                progressMessages.append(message)
            }
            try initPackage.writePackageStructure()

            // Not picky about the specific progress messages, just checking that we got some.
            XCTAssert(progressMessages.count > 0)

            // Verify basic file system content that we expect in the package
            XCTAssert(fs.exists(path.appending(component: "Package.swift")))
            XCTAssertEqual(try fs.getDirectoryContents(path.appending(component: "Sources")), [])
            XCTAssertEqual(try fs.getDirectoryContents(path.appending(component: "Tests")), [])
        }
    }
    
    func testInitPackageExecutable() throws {
        mktmpdir { tmpPath in
            var fs = localFileSystem
            let path = tmpPath.appending(component: "Foo")
            try fs.createDirectory(path)

            // Create the package
            let initPackage = try InitPackage(destinationPath: path, packageType: InitPackage.PackageType.executable)
            var progressMessages = [String]()
            initPackage.progressReporter = { message in
                progressMessages.append(message)
            }
            try initPackage.writePackageStructure()

            // Not picky about the specific progress messages, just checking that we got some.
            XCTAssert(progressMessages.count > 0)

            
            // Verify basic file system content that we expect in the package
            let manifest = path.appending(component: "Package.swift")
            let contents = try localFileSystem.readFileContents(manifest).asString!
            let version = "\(ToolsVersion.currentToolsVersion.major).\(ToolsVersion.currentToolsVersion.minor)"
            XCTAssertTrue(contents.hasPrefix("// swift-tools-version:\(version)\n"))
            
            XCTAssertTrue(fs.exists(manifest))
            XCTAssertEqual(try fs.getDirectoryContents(path.appending(component: "Sources")), ["main.swift"])
            XCTAssertEqual(try fs.getDirectoryContents(path.appending(component: "Tests")), [])
            
            // Try building it
            XCTAssertBuilds(path)
            XCTAssertFileExists(path.appending(components: ".build", "debug", "Foo"))
            XCTAssertFileExists(path.appending(components: ".build", "debug", "Foo.swiftmodule"))
        }
    }

    func testInitPackageLibrary() throws {
        mktmpdir { tmpPath in
            var fs = localFileSystem
            let path = tmpPath.appending(component: "Foo")
            try fs.createDirectory(path)

            // Create the package
            let initPackage = try InitPackage(destinationPath: path, packageType: InitPackage.PackageType.library)
            var progressMessages = [String]()
            initPackage.progressReporter = { message in
                progressMessages.append(message)
            }
            try initPackage.writePackageStructure()

            // Not picky about the specific progress messages, just checking that we got some.
            XCTAssert(progressMessages.count > 0)

            // Verify basic file system content that we expect in the package
            XCTAssert(fs.exists(path.appending(component: "Package.swift")))
            XCTAssertEqual(try fs.getDirectoryContents(path.appending(component: "Sources")), ["Foo.swift"])
            XCTAssertEqual(
                try fs.getDirectoryContents(path.appending(component: "Tests")).sorted(),
                ["FooTests", "LinuxMain.swift"])

            // Try building it
            XCTAssertBuilds(path)
            XCTAssertFileExists(path.appending(components: ".build", "debug", "Foo.swiftmodule"))
        }
    }
    
    func testInitPackageSystemModule() throws {
        mktmpdir { tmpPath in
            var fs = localFileSystem
            let path = tmpPath.appending(component: "Foo")
            try fs.createDirectory(path)
            
            // Create the package
            let initPackage = try InitPackage(destinationPath: path, packageType: InitPackage.PackageType.systemModule)
            var progressMessages = [String]()
            initPackage.progressReporter = { message in
                progressMessages.append(message)
            }
            try initPackage.writePackageStructure()
            
            // Not picky about the specific progress messages, just checking that we got some.
            XCTAssert(progressMessages.count > 0)

            // Verify basic file system content that we expect in the package
            XCTAssert(fs.exists(path.appending(component: "Package.swift")))
            XCTAssert(fs.exists(path.appending(component: "module.modulemap")))
        }
    }
    
    // MARK: Special case testing
    
    func testInitPackageNonc99Directory() throws {
        let tempDir = try TemporaryDirectory(removeTreeOnDeinit: true)
        XCTAssertTrue(localFileSystem.isDirectory(tempDir.path))
        
        // Create a directory with non c99name.
        let packageRoot = tempDir.path.appending(component: "some-package")
        try localFileSystem.createDirectory(packageRoot)
        XCTAssertTrue(localFileSystem.isDirectory(packageRoot))
        
        // Create the package
        let initPackage = try InitPackage(destinationPath: packageRoot, packageType: InitPackage.PackageType.library)
        initPackage.progressReporter = { message in
        }
        try initPackage.writePackageStructure()

        // Try building it.
        XCTAssertBuilds(packageRoot)
        XCTAssertFileExists(packageRoot.appending(components: ".build", "debug", "some_package.swiftmodule"))
    }
    
    static var allTests = [
        ("testInitPackageEmpty", testInitPackageEmpty),
        ("testInitPackageExecutable", testInitPackageExecutable),
        ("testInitPackageLibrary", testInitPackageLibrary),
        ("testInitPackageSystemModule", testInitPackageSystemModule),
        ("testInitPackageNonc99Directory", testInitPackageNonc99Directory),
    ]

}

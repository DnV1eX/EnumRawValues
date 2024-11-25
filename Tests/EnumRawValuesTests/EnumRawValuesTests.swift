//
//  EnumRawValuesTests.swift
//  EnumRawValues
//
//  Created by Alexey Demin on 2024-11-20.
//  Copyright © 2024 DnV1eX. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(EnumRawValuesMacros)
import EnumRawValuesMacros

let testMacros: [String: Macro.Type] = [
    "EnumRawValues": EnumRawValuesMacro.self,
]
#endif

final class EnumRawValuesTests: XCTestCase {
    func testMacroWithIntegerRawValues() throws {
        #if canImport(EnumRawValuesMacros)
        assertMacroExpansion(
            """
            let earthIndex = 3
            @EnumRawValues(1, 2, 4, 5, 6, earthIndex, 1 << 3, Int(7.0))
            enum Planet: Int {
                case mercury, venus, mars, jupiter, saturn, earth, neptune, uranus
            }
            """,
            expandedSource: """
            let earthIndex = 3
            enum Planet: Int {
                case mercury, venus, mars, jupiter, saturn, earth, neptune, uranus
            }

            extension Planet: RawRepresentable {
                public init?(rawValue: Int) {
                    switch rawValue {
                    case 1:
                        self = .mercury
                    case 2:
                        self = .venus
                    case 4:
                        self = .mars
                    case 5:
                        self = .jupiter
                    case 6:
                        self = .saturn
                    case earthIndex:
                        self = .earth
                    case 1 << 3:
                        self = .neptune
                    case Int(7.0):
                        self = .uranus
                    default:
                        return nil
                    }
                }
                public var rawValue: Int {
                    switch self {
                    case .mercury:
                        1
                    case .venus:
                        2
                    case .mars:
                        4
                    case .jupiter:
                        5
                    case .saturn:
                        6
                    case .earth:
                        earthIndex
                    case .neptune:
                        1 << 3
                    case .uranus:
                        Int(7.0)
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithStringRawValues() throws {
        #if canImport(EnumRawValuesMacros)
        assertMacroExpansion(
            #"""
            let h2aRocketName = "H-IIA"
            @EnumRawValues(
                "Falcon 9", "Falcon Heavy",
                "electron",
                "Vulcan" + " " + "Centaur",
                "Ariane \(6)",
                ["Soyuz", "2"].joined(separator: "-"),
                h2aRocketName,
                String(localized: "Long March 5"),
                { "New Glenn" }()
            )
            enum Rocket: String {
                case falcon9, falconHeavy
                case electron
                case vulcanCentaur
                case ariane6
                case soyuz2
                case hIIA
                case longMarch5
                case newGlenn
            }
            """#,
            expandedSource: #"""
            let h2aRocketName = "H-IIA"
            enum Rocket: String {
                case falcon9, falconHeavy
                case electron
                case vulcanCentaur
                case ariane6
                case soyuz2
                case hIIA
                case longMarch5
                case newGlenn
            }

            extension Rocket: RawRepresentable {
                public init?(rawValue: String) {
                    switch rawValue {
                    case "Falcon 9":
                        self = .falcon9
                    case "Falcon Heavy":
                        self = .falconHeavy
                    case "electron":
                        self = .electron
                    case "Vulcan" + " " + "Centaur":
                        self = .vulcanCentaur
                    case "Ariane \(6)":
                        self = .ariane6
                    case ["Soyuz", "2"].joined(separator: "-"):
                        self = .soyuz2
                    case h2aRocketName:
                        self = .hIIA
                    case String(localized: "Long March 5"):
                        self = .longMarch5
                    case { "New Glenn"
                    }():
                        self = .newGlenn
                    default:
                        return nil
                    }
                }
                public var rawValue: String {
                    switch self {
                    case .falcon9:
                        "Falcon 9"
                    case .falconHeavy:
                        "Falcon Heavy"
                    case .electron:
                        "electron"
                    case .vulcanCentaur:
                        "Vulcan" + " " + "Centaur"
                    case .ariane6:
                        "Ariane \(6)"
                    case .soyuz2:
                        ["Soyuz", "2"].joined(separator: "-")
                    case .hIIA:
                        h2aRocketName
                    case .longMarch5:
                        String(localized: "Long March 5")
                    case .newGlenn:
                        {
                            "New Glenn"
                        }()
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testMacroWithCustomRawValues() throws {
        #if canImport(EnumRawValuesMacros)
        assertMacroExpansion(
            """
            extension TISInputSource {
                @EnumRawValues<CFString>(
                    kTISTypeKeyboardLayout,
                    kTISTypeKeyboardInputMethodWithoutModes,
                    kTISTypeKeyboardInputMethodModeEnabled,
                    kTISTypeKeyboardInputMode,
                    kTISTypeCharacterPalette,
                    kTISTypeKeyboardViewer,
                    kTISTypeInk
                )
                enum InputSourceType {
                    case keyboardLayout
                    case keyboardInputMethodWithoutModes
                    case keyboardInputMethodModeEnabled
                    case keyboardInputMode
                    case characterPalette
                    case keyboardViewer
                    case ink
                }
            }
            """,
            expandedSource: """
            extension TISInputSource {
                enum InputSourceType {
                    case keyboardLayout
                    case keyboardInputMethodWithoutModes
                    case keyboardInputMethodModeEnabled
                    case keyboardInputMode
                    case characterPalette
                    case keyboardViewer
                    case ink
                }
            }

            extension TISInputSource.InputSourceType: RawRepresentable {
                public init?(rawValue: CFString) {
                    switch rawValue {
                    case kTISTypeKeyboardLayout:
                        self = .keyboardLayout
                    case kTISTypeKeyboardInputMethodWithoutModes:
                        self = .keyboardInputMethodWithoutModes
                    case kTISTypeKeyboardInputMethodModeEnabled:
                        self = .keyboardInputMethodModeEnabled
                    case kTISTypeKeyboardInputMode:
                        self = .keyboardInputMode
                    case kTISTypeCharacterPalette:
                        self = .characterPalette
                    case kTISTypeKeyboardViewer:
                        self = .keyboardViewer
                    case kTISTypeInk:
                        self = .ink
                    default:
                        return nil
                    }
                }
                public var rawValue: CFString {
                    switch self {
                    case .keyboardLayout:
                        kTISTypeKeyboardLayout
                    case .keyboardInputMethodWithoutModes:
                        kTISTypeKeyboardInputMethodWithoutModes
                    case .keyboardInputMethodModeEnabled:
                        kTISTypeKeyboardInputMethodModeEnabled
                    case .keyboardInputMode:
                        kTISTypeKeyboardInputMode
                    case .characterPalette:
                        kTISTypeCharacterPalette
                    case .keyboardViewer:
                        kTISTypeKeyboardViewer
                    case .ink:
                        kTISTypeInk
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}

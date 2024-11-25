//
//  main.swift
//  EnumRawValues
//
//  Created by Alexey Demin on 2024-11-20.
//  Copyright © 2024 DnV1eX. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//

import Foundation
import EnumRawValues
import InputMethodKit

let earthIndex = 3
//enum Planet: Int, CaseIterable {
//    case mercury = 1, venus, mars = 4, jupiter, saturn, earth = earthIndex, neptune = 1 << 3, uranus = Int(7.0)
//}
@EnumRawValues(1, 2, 4, 5, 6, earthIndex, 1 << 3, Int(7.0))
enum Planet: Int, CaseIterable {
    case mercury, venus, mars, jupiter, saturn, earth, neptune, uranus
}
assert(Planet.allCases == Planet.allCases.map(\.rawValue).map(Planet.init))
assert([Planet.mercury, .venus, .earth, .mars, .jupiter, .saturn, .uranus, .neptune].map(\.rawValue) == Array(1...8))


let h2aRocketName = "H-IIA"
//@EnumRawValues
//enum Rocket: String, CaseIterable {
//    case falcon9 = "Falcon 9", falconHeavy = "Falcon Heavy" // Multiple elements
//    case electron // Implicitly assigned raw values
//    case vulcanCentaur = "Vulcan" + " " + "Centaur" // Expressions
//    case ariane6 = "Ariane \(6)" // String interpolation
//    case soyuz2 = ["Soyuz", "2"].joined(separator: "-") // Functions
//    case hIIA = h2aRocketName // Constants and variables
//    case longMarch5 = String(localized: "Long March 5") // Localization
//    case newGlenn = { "New Glenn" }() // Closures (currently causing build crash)
//}
@EnumRawValues(
    "Falcon 9", "Falcon Heavy",
    "electron",
    "Vulcan" + " " + "Centaur",
    "Ariane \(6)",
    ["Soyuz", "2"].joined(separator: "-"),
    h2aRocketName//,
//    String(localized: "Long March 5"),
//    { "New Glenn" }()
)
enum Rocket: String, CaseIterable {
    case falcon9, falconHeavy
    case electron
    case vulcanCentaur
    case ariane6
    case soyuz2
    case hIIA
//    case longMarch5
//    case newGlenn
}
assert(Rocket.allCases == Rocket.allCases.map(\.rawValue).map(Rocket.init))
assert(Rocket.hIIA.rawValue == h2aRocketName)


//extension TISInputSource {
//    enum InputSourceType: CFString {
//        case keyboardLayout = kTISTypeKeyboardLayout
//        case keyboardInputMethodWithoutModes = kTISTypeKeyboardInputMethodWithoutModes
//        case keyboardInputMethodModeEnabled = kTISTypeKeyboardInputMethodModeEnabled
//        case keyboardInputMode = kTISTypeKeyboardInputMode
//        case characterPalette = kTISTypeCharacterPalette
//        case keyboardViewer = kTISTypeKeyboardViewer
//        case ink = kTISTypeInk
//    }
//}
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
assert(TISInputSource.InputSourceType.keyboardLayout.rawValue == kTISTypeKeyboardLayout)
assert(TISInputSource.InputSourceType(rawValue: kTISTypeKeyboardLayout) == .keyboardLayout)

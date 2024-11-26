# EnumRawValues
The **EnumRawValues** is a Swift attached extension macro to add raw values for enums.

Built-in support for [raw values](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/enumerations/#Raw-Values) in Swift enums is limited by a string, integer, or floating-point literals. New macros functionality made it possible to achieve a similar level of expressiveness and compile-time safety while removing restrictions on the type and assignment of raw values.

## Macro Features
- Support for any equatable raw value types.
- Support for assigning raw values with constants and expressions.
- Ensures type safety.
- Performs integrity checks.
- Automatically transfers existing raw values to macro arguments (including implicitly assigned raw values! 😎).

## Installation
To add the package to your Xcode project, open `File -> Add Package Dependencies...` and search for the URL:
```
https://github.com/DnV1eX/EnumRawValues.git
```
Then, simply **import EnumRawValues** and add the **@EnumRawValues** attribute before the target enum.
> [!WARNING]
> Xcode may ask to `Trust & Enable` the macro on first use or after an update.

## Usage Examples
1. Assigning raw values using constants, expressions, functions, and more:
```Swift
import EnumRawValues

let earthIndex = 3

@EnumRawValues(1 << 3, Int(7.0), Int("6"), (1...5).count, 2 * 2, earthIndex, 2, 1)
enum Planet: Int {
    case neptune, uranus, saturn, jupiter, mars, earth, venus, mercury
}
```
2. Raw value arguments can be automatically generated from the standard enum format:
```Swift
let h2aRocketName = "H-IIA"

enum Rocket: String {
    case falcon9 = "Falcon 9", falconHeavy = "Falcon Heavy" // Multiple elements
    case electron // Implicitly assigned raw values
    case vulcanCentaur = "Vulcan" + " " + "Centaur" // Expressions
    case ariane6 = "Ariane \(6)" // String interpolation
    case soyuz2 = ["Soyuz", "2"].joined(separator: "-") // Functions
    case hIIA = h2aRocketName // Constants and variables
    case longMarch5 = String(localized: "Long March 5") // Localization
    case newGlenn = { "New Glenn" }() // Closures (currently causing build crash)
}
```
Add the **@EnumRawValues** attribute before the *Rocket* enum, and then click the `Fix` button to convert raw values into macro arguments:

<img width="499" alt="Fix enum pop-up" align="right" src="https://github.com/user-attachments/assets/d514cada-7773-4bfe-8e5f-f8e1556d80e5">
<br>
<br>
<br>

```Swift
import EnumRawValues

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
```
3. Extending a low-level class with convenient enumeration using a custom raw value type and predefined constants:
```Swift
import EnumRawValues
import InputMethodKit

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
```

## Notes on Usage
- Explicit type annotation is requied and can be specified either in the macro attribute generic clause (preferable) or as the enum type. In the latter case make sure the first item in the enum’s type inheritance list is a Type conforming to `ExpressibleByStringLiteral`, `ExpressibleByIntegerLiteral` or `ExpressibleByFloatLiteral` protocol, and macro arguments are of this type.
- Like the built-in implementaton, **EnumRawValues** is currently not compatible with [Associated Values](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/enumerations#Associated-Values). The support can be added in future with default initializers and nil for optional associated values, feel free to submit the feature request with your use case.
- Raw value uniqueness is checked in compile time by the switch flow control that displays warnings (grey ones in generated code). Keep in mind that they can be bypassed, for example, by specifying different constants with the same values.

## Implementation
Under the hood the **EnumRawValues** macro adds the enum extension with [RawRepresentable](https://developer.apple.com/documentation/swift/rawrepresentable) protocol conformance using the macro attribute arguments as enum case raw values in the order of declaration. There are also multiple format checks and syntax fix suggestions. The macro code is covered with unit tests.

## License
Copyright © 2024 DnV1eX. All rights reserved. Licensed under the Apache License, Version 2.0.

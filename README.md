# EnumRawValues
@EnumRawValues is a Swift attached extension macro to add raw values for enums. Built-in support for [raw values](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/enumerations/#Raw-Values) in Swift enums is limited by a string, integer, or floating-point literals. New macros functionality made it possible to achieve a similar level of expressiveness and compile-time safety while removing restrictions on raw value type and format.

## Macro Features
- Support for any equatable raw value types.
- Support for assigning raw values with constants and expressions.
- Ensures type safety.
- Performs integrity checks.
- Automatically transfers existing raw values to macro arguments (including implicitly assigned raw values!).

## Usage Examples
### Assigning raw values using constants, expressions, functions, and more:
```Swift
import EnumRawValues
let earthIndex = 3
@EnumRawValues(1 << 3, Int(7.0), Int("6"), (1...5).count, 2 * 2, earthIndex, 2, 1)
enum Planet: Int {
    case neptune, uranus, saturn, jupiter, mars, earth, venus, mercury
}
```
### Extending a low-level class with convenient enumeration using a custom raw value type and predefined constants:
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
- Explicit type annotation is requied and can be specified either in the macro attribute generic clause (preferable) or as the enum type. In the latter case make sure the first item in the enum’s type inheritance list is a Type conforming to `ExpressibleByStringLiteral`, `ExpressibleByIntegerLiteral` or `ExpressibleByFloatLiteral` protocol, and macro arguments are conforming to this type.
- Like the built-in implementaton, `EnumRawValues` is currently not compatible with [Associated Values](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/enumerations#Associated-Values). The support can be added in future with default initializers and nil for optional associated values, feel free to submit the feature request with your use case.
- Raw value uniqueness is checked in compile time by the switch flow control that displays warnings (grey ones in generated code). Keep in mind that they can be bypassed, for example, by specifying different constants with the same values.

## Implementation
Under the hood the `EnumRawValues` macro adds the enum extension with [RawRepresentable](https://developer.apple.com/documentation/swift/rawrepresentable) protocol conformance using the macro attribute arguments as enum case raw values in the order of declaration. There are also multiple format checks and syntax fix suggestions. The macro code is covered with unit tests.

## License
Copyright © 2024 DnV1eX. All rights reserved. Licensed under the Apache License, Version 2.0.

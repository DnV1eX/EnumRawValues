//
//  EnumRawValues.swift
//  EnumRawValues
//
//  Created by Alexey Demin on 2024-11-20.
//  Copyright © 2024 DnV1eX. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//

/// An extension macro that adds full-fledged raw values with `RawRepresentable` protocol conformance to enumerations.
///
/// It is now possible to use constants, expressions and any equatable types as enumeration raw values.
///
/// For example,
///
///     @EnumRawValues<RawValue>(rawValue1, rawValue2)
///     enum MyEnumeration {
///         case element1, element2
///     }
///
/// is equivalent to if the enumeration could be defined as
///
///     enum MyEnumeration: RawValue {
///         case element1 = rawValue1, element2 = rawValue2
///     }
///
/// - Note: Specify `RawValue` type in the attribute generic clause if it doesn't conform to `ExpressibleByStringLiteral`, `ExpressibleByIntegerLiteral` or `ExpressibleByFloatLiteral` protocol.
@attached(extension, conformances: RawRepresentable, names: named(init(rawValue:)), named(rawValue))
public macro EnumRawValues<RawValue: Equatable>(_ rawValues: RawValue...) = #externalMacro(module: "EnumRawValuesMacros", type: "EnumRawValuesMacro")

/// An extension macro that adds full-fledged raw values with `RawRepresentable` protocol conformance to enumerations.
///
/// It is now possible to use constants, expressions and any equatable types as enumeration raw values.
///
/// For example,
///
///     @EnumRawValues
///     enum MyEnumeration: RawValue {
///         case element1 = rawValue1, element2 = rawValue2
///     }
///
/// will be automatically converted using the **Fix** button to
///
///     @EnumRawValues<RawValue>(rawValue1, rawValue2)
///     enum MyEnumeration {
///         case element1, element2
///     }
///
/// - Note: Specify `RawValue` type in the attribute generic clause if it doesn't conform to `ExpressibleByStringLiteral`, `ExpressibleByIntegerLiteral` or `ExpressibleByFloatLiteral` protocol.
@attached(extension, conformances: RawRepresentable, names: named(init(rawValue:)), named(rawValue))
public macro EnumRawValues() = #externalMacro(module: "EnumRawValuesMacros", type: "EnumRawValuesMacro")

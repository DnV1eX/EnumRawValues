//
//  EnumRawValuesMacro.swift
//  EnumRawValues
//
//  Created by Alexey Demin on 2024-11-20.
//  Copyright © 2024 DnV1eX. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

/// Implementation of the `EnumRawValues` attached extension macro, which adds full-fledged raw values with `RawRepresentable` protocol conformance to enumerations.
public struct EnumRawValuesMacro: ExtensionMacro {
    
    public static func expansion(of node: AttributeSyntax,
                                 attachedTo declaration: some DeclGroupSyntax,
                                 providingExtensionsOf type: some TypeSyntaxProtocol,
                                 conformingTo protocols: [TypeSyntax],
                                 in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {
        
        // Check that the macro is attached to an enumeration.
        guard let enumeration = declaration.as(EnumDeclSyntax.self) else {
            let diagnostic = Diagnostic(node: declaration.introducer,
                                        message: Message.wrongDeclarationType,
                                        fixIt: .replace(message: Message.wrongDeclarationType,
                                                        oldNode: declaration.introducer,
                                                        newNode: TokenSyntax(.keyword(.enum), presence: .present)))
            context.diagnose(diagnostic)
            return []
        }
        
        let attributeName = node.attributeName.as(IdentifierTypeSyntax.self)! // `EnumRawValues` always exists.
        
        // Check that the `RawValue` type is specified using either an attribute generic clause or the enumeration type.
        guard let argumentType = attributeName.genericArgumentClause?.arguments.first?.argument ?? enumeration.inheritanceClause?.inheritedTypes.first?.type else {
            
            var newAttribute = attributeName
            newAttribute.genericArgumentClause = .init(arguments: [.init(argument: TypeSyntax("\(placeholder: "Type: Equatable")"))])
            
            var newEnumeration = enumeration
            newEnumeration.name.trailingTrivia = .init()
            newEnumeration.inheritanceClause = .init(inheritedTypesBuilder: {
                .init(type: TypeSyntax("\(placeholder: "RawValueType: Equatable & ExpressibleByLiteral")"))
            })
            newEnumeration.inheritanceClause?.inheritedTypes.leadingTrivia = .space
            newEnumeration.inheritanceClause?.inheritedTypes.trailingTrivia = .space

            let diagnostic = Diagnostic(node: attributeName,
                                        message: Message.missingRawValueType,
                                        fixIts: [.replace(message: Message.insertGenericTypePlaceholder,
                                                          oldNode: attributeName,
                                                          newNode: newAttribute),
                                                 .replace(message: Message.insertEnumTypePlaceholder,
                                                          oldNode: enumeration,
                                                          newNode: newEnumeration)])
            context.diagnose(diagnostic)
            return []
        }
        
        /// Array of macro attribute argument expressions.
        let argumentExpressions = node.arguments?.as(LabeledExprListSyntax.self)?.map(\.expression) ?? []
        let argumentCount = argumentExpressions.count
        
        /// Flattened array of enumeration case elements.
        let caseElements = enumeration.memberBlock.members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }.flatMap(\.elements)
        let elementCount = caseElements.count
        
        /// Generates an `ExprSyntax` node with a raw value or editor placeholder.
        /// Supports implicitly assigned raw values of both String (case name) and Int (element index) types.
        /// - Parameters:
        ///   - element: Element of an enum case for which the argument is generated.
        ///   - index: Index, incremented from 0 or from the last known integer raw value.
        /// - Returns: New `ExprSyntax` node to use in attribute arguments.
        func argumentExpression(for element: EnumCaseElementSyntax, at index: inout Int) -> ExprSyntax {
            if let rawValue = element.rawValue?.value.trimmed {
                if argumentType.isIntegerLiteralType, let rawValue = Int(rawValue.description) {
                    index = rawValue
                }
                return ExprSyntax(rawValue)
            } else if argumentType.isStringLiteralType {
                return ExprSyntax("\"\(element.name.trimmed)\"")
            } else if argumentType.isIntegerLiteralType {
                return ExprSyntax("\(raw: index)")
            } else {
                return ExprSyntax("\(placeholder: "\(element.name.trimmed): \(argumentType.trimmed)")")
            }
        }
        
        /// Generates an `AttributeSyntax` node with arguments from the enum's raw values or editor placeholders if no explicit raw value is provided.
        /// Multiple line format is used if there are several enum cases.
        /// - Parameter overwriteExistingArguments: Replace existing arguments with new raw values.
        /// - Returns: Copy of the existing `AttributeSyntax` node with the newly generated arguments.
        func attributeWithRawValueArguments(overwrite overwriteExistingArguments: Bool = false) -> AttributeSyntax {
            let cases = enumeration.memberBlock.members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }.map(\.elements)
            let hasMultipleCases = (cases.count > 1)
            var attribute = node
            var index = 0
            attribute.arguments = .init(cases.reduce(into: []) { newArguments, elements in
                for element in elements {
                    let newArgumentCount = newArguments.count
                    var expression: LabeledExprSyntax
                    if !overwriteExistingArguments || element.rawValue == nil, argumentCount > newArgumentCount {
                        expression = .init(expression: argumentExpressions[newArgumentCount].trimmed)
                    } else {
                        expression = .init(expression: argumentExpression(for: element, at: &index))
                    }
                    if element != elements.first {
                        expression.leadingTrivia = .space
                    } else if hasMultipleCases {
                        expression.leadingTrivia = .newline
                    }
                    if element != cases.last?.last {
                        expression.trailingComma = .commaToken()
                    } else if hasMultipleCases {
                        expression.trailingTrivia = .newline
                    }
                    index += 1
                    newArguments.append(expression)
                }
            })
            let hasArguments = attribute.arguments?.as(LabeledExprListSyntax.self)?.isEmpty == false
            attribute.leftParen = hasArguments ? .leftParenToken() : nil
            attribute.rightParen = hasArguments ? .rightParenToken() : nil
            return attribute
        }
        
        /// Generates a `MemberBlockItemListSyntax` node with enumeration cases without raw values.
        /// - Returns: Copy of the existing `MemberBlockItemListSyntax` node with the newly generated elements.
        func membersWithoutRawValues() -> MemberBlockItemListSyntax {
            .init(declaration.memberBlock.members.map { member in
                var member = member
                if var decl = member.decl.as(EnumCaseDeclSyntax.self) {
                    decl.elements = .init(decl.elements.map { element in
                        var element = element
                        element.name.trailingTrivia = .init()
                        element.rawValue = nil
                        return element
                    })
                    member.decl = .init(decl)
                }
                return member
            })
        }
        
        // Verify that the number of macro arguments matches the number of enumeration cases.
        guard argumentCount == elementCount else {
            let diagnosticNode: Syntax?
            let fixIt: FixIt
            if argumentCount == 0 {
                diagnosticNode = Syntax(node.rightParen)
                fixIt = .init(message: Message.importRawValues,
                              changes: [.replace(oldNode: Syntax(node),
                                                 newNode: Syntax(attributeWithRawValueArguments(overwrite: true))),
                                        .replace(oldNode: Syntax(declaration.memberBlock.members),
                                                 newNode: Syntax(membersWithoutRawValues()))])
            } else if argumentCount < elementCount {
                diagnosticNode = Syntax(node.rightParen)
                fixIt = .replace(message: Message.completeArguments,
                                 oldNode: node,
                                 newNode: attributeWithRawValueArguments())
            } else {
                diagnosticNode = elementCount > 0 ? Syntax(node.arguments?.as(LabeledExprListSyntax.self).map(Array.init)?[elementCount - 1].trailingComma) : Syntax(node.leftParen)
                fixIt = .replace(message: Message.removeRedundantArguments,
                                 oldNode: node,
                                 newNode: attributeWithRawValueArguments())
            }
            let diagnostic = Diagnostic(node: diagnosticNode ?? Syntax(attributeName),
                                        message: Message.unequalArgumentNumber(argumentCount, elementCount),
                                        fixIt: fixIt)
            context.diagnose(diagnostic)
            return []
        }
        
        let rawValues = caseElements.map(\.rawValue?.value)
        
        // Warn that native raw values are being ignored.
        if !rawValues.compactMap(\.self).isEmpty {
            let diagnostic = Diagnostic(node: attributeName,
                                        message: Message.overlappingRawValues,
                                        fixIts: [.init(message: Message.importRawValues,
                                                       changes: [.replace(oldNode: Syntax(node),
                                                                          newNode: Syntax(attributeWithRawValueArguments(overwrite: true))),
                                                                 .replace(oldNode: Syntax(declaration.memberBlock.members),
                                                                          newNode: Syntax(membersWithoutRawValues()))]),
                                                 .replace(message: Message.removeRawValues,
                                                          oldNode: declaration.memberBlock.members,
                                                          newNode: membersWithoutRawValues())])
            context.diagnose(diagnostic)
        }
        
        // Create init with `rawValue` declaration.
        let initializer = try InitializerDeclSyntax("public init?(rawValue: \(argumentType.trimmed))") {
            try SwitchExprSyntax("switch rawValue") {
                for (argument, element) in zip(argumentExpressions, caseElements) {
                    SwitchCaseSyntax("case \(argument.trimmed): self = .\(element.name.trimmed)")
                }
                SwitchCaseSyntax("default: return nil")
            }
        }
        
        // Create `rawValue` getter declaration.
        let rawValue = try VariableDeclSyntax("public var rawValue: \(argumentType.trimmed)") {
            try SwitchExprSyntax("switch self") {
                for (element, argument) in zip(caseElements, argumentExpressions) {
                    SwitchCaseSyntax("case .\(element.name.trimmed): \(argument.trimmed)")
                }
            }
        }
        
        // Create `RawRepresentable` conformance extension.
        let enumExtension = try ExtensionDeclSyntax("extension \(type.trimmed): RawRepresentable") {
            initializer
            rawValue
        }
        return [enumExtension]
    }
}

extension EnumRawValuesMacro {
    enum Message: DiagnosticMessage, FixItMessage, Error {
        case wrongDeclarationType
        case missingRawValueType
        case insertGenericTypePlaceholder
        case insertEnumTypePlaceholder
        case unequalArgumentNumber(Int, Int)
        case importRawValues
        case completeArguments
        case removeRedundantArguments
        case overlappingRawValues
        case removeRawValues

        var message: String {
            switch self {
            case .wrongDeclarationType: "@EnumRawValues can only be applied to 'enum'"
            case .missingRawValueType: "@EnumRawValues requires explicit 'rawValue' type annotation"
            case .insertGenericTypePlaceholder: "Specify a generic clause for the macro"
            case .insertEnumTypePlaceholder: "Specify a type for the enum"
            case let .unequalArgumentNumber(argumentCount, elementCount): "Number of raw value arguments (\(argumentCount)) must be equal to number of enum cases (\(elementCount))"
            case .importRawValues: "Populate macro arguments with enum raw values"
            case .completeArguments: "Complete the macro with missing trailing arguments from enum raw values" +
                "\nWARNING: Manually insert raw values at correct positions if new cases were not appended to the end of the enum"
            case .removeRedundantArguments: "Remove redundant trailing arguments from the macro" +
                "\nWARNING: Manually remove raw values at correct positions if cases were not removed from the end of the enum"
            case .overlappingRawValues: "Enum raw values are overridden by the macro arguments"
            case .removeRawValues: "Remove raw values from the enum case declarations"
            }
        }
        
        var diagnosticID: SwiftDiagnostics.MessageID {
            .init(domain: "EnumRawValuesMacros", id: Mirror(reflecting: self).children.first?.label ?? "\(self)")
        }
        
        var severity: SwiftDiagnostics.DiagnosticSeverity {
            switch self {
            case .wrongDeclarationType, .missingRawValueType, .unequalArgumentNumber: .error
            case .overlappingRawValues: .warning
            case .insertGenericTypePlaceholder, .insertEnumTypePlaceholder, .importRawValues, .completeArguments, .removeRedundantArguments, .removeRawValues: .remark
            }
        }
        
        var fixItID: SwiftDiagnostics.MessageID {
            diagnosticID
        }
    }
}

@main
struct EnumRawValuesPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EnumRawValuesMacro.self,
    ]
}

extension SyntaxStringInterpolation {
    public mutating func appendInterpolation(placeholder: String) {
        appendLiteral("<" + "#" + placeholder + "#" + ">")
    }
}

extension TypeSyntax {
    var isStringLiteralType: Bool {
        ["String", "Substring"].contains(trimmed.description)
    }
    var isIntegerLiteralType: Bool {
        trimmed.description.range(of: "^U?Int(?:8|16|32|64|128)?$|^Double$|^Float(?:32|64|80)?$|^CGFloat$", options: .regularExpression) != nil
    }
}

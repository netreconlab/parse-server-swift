//
//  FooParameters.swift
//  
//
//  Created by Corey E. Baker on 6/21/22.
//

import ParseSwift
import Vapor

/**
 Parameters for the Foo Parse Hook Function.
 */
struct FooParameters: ParseHookParametable {}

extension FooParameters: Validatable {
    static func validations(_ validations: inout Validations) {
        return
    }
}

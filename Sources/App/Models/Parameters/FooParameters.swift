//
//  FooParameters.swift
//  
//
//  Created by Corey Baker on 6/21/22.
//

import ParseSwift
import Vapor

struct FooParameters: ParseHookParametable {}

extension Parameters: Validatable {
    static func validations(_ validations: inout Validations) {
        return
    }
}

//
//  File.swift
//  
//
//  Created by Corey Baker on 6/23/22.
//

import Foundation
import ParseSwift

/**
 Parse Hook Functions can be created by conforming to
 `ParseHookFunctionable`.
 */
struct HookFunction: ParseHookFunctionable {
    var functionName: String?
    var url: URL?
}

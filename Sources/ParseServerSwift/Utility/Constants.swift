//
//  Constants.swift
//  
//
//  Created by Corey E. Baker on 6/21/22.
//

import Foundation

/**
 Additional headers sent from the Parse Server.
 */
public enum Headers {
    /**
     Sent from a Parse Server to prove authenticity. The **webhookKey**
     is an optional configuration when initializing your nodejs Parse Server.
     */
    public static let webhook = "X-Parse-Webhook-Key"
}

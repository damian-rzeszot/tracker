//
//  Event.swift
//  LublinWeather
//
//  Created by Damian Rzeszot on 26/04/2018.
//  Copyright © 2018 Damian Rzeszot. All rights reserved.
//

import Foundation


protocol Event {
    var type: String { get }
    var parameters: [String: Any] { get }
}


extension Event {

    var type: String {
        return String(describing: self)
    }

    var parameters: [String: Any] {
        return [:]
    }

}

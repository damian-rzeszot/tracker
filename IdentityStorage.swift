//
//  IdentityStorage.swift
//  LublinWeather
//
//  Created by Damian Rzeszot on 26/04/2018.
//  Copyright © 2018 Damian Rzeszot. All rights reserved.
//

import Foundation


protocol IdentityStorage: class {
    func set(_ value: String)
    func get() -> String?
    func reset()
}



final class UserDefaultsIdentityStorage: IdentityStorage {

    private let key = "tracker-identity"

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    convenience init() {
        self.init(defaults: .standard)
    }

    func set(_ value: String) {
        defaults.set(value, forKey: key)
        defaults.synchronize()
    }

    func get() -> String? {
        defaults.synchronize()
        return defaults.string(forKey: key)
    }

    func reset() {
        defaults.set(nil, forKey: key)
        defaults.synchronize()
    }

}



final class InMemoryIdentityStorage: IdentityStorage {


    static let shared: IdentityStorage = InMemoryIdentityStorage()


    private var value: String?


    func set(_ value: String) {
        self.value = value
    }

    func get() -> String? {
        return value
    }

    func reset() {
        value = nil
    }

}

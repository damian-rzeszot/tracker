//
//  Tracker.swift
//  LublinWeather
//
//  Created by Damian Rzeszot on 22/04/2018.
//  Copyright © 2018 Damian Rzeszot. All rights reserved.
//

import Foundation


final class Tracker<E: Event> {


    // MARK: -

    private let path: [String]
    private let collector: Collector


    // MARK: -

    init(path: [String] = [], collector: Collector = Collector()) {
        self.path = path
        self.collector = collector
    }


    // MARK: -

    var identifier: String {
        return path.joined(separator: ".")
    }


    // MARK: -

    func track(_ event: E) {
        DispatchQueue.main.async {
            self.collector.collect(identifier: self.identifier, event: event)
        }
    }


    // MARK: -

    func chain<F: Event>(_ prefix: String? = nil) -> Tracker<F> {
        let id = ":" + String(UUID().uuidString.split(separator: "-").last ?? "000000000000").lowercased()

        if let prefix = prefix {
            return child("\(prefix)-\(id)")
        } else {
            return child(id)
        }
    }

    func child<F: Event>(_ identifier: String) -> Tracker<F> {
        return Tracker<F>(path: self.path + [identifier], collector: collector)
    }

}

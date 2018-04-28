//
//  Collector.swift
//  LublinWeather
//
//  Created by Damian Rzeszot on 26/04/2018.
//  Copyright © 2018 Damian Rzeszot. All rights reserved.
//

import Foundation


final class Collector {


    // MARK: - Config

    private let limit: Int = 20
    private let foolproof: Int = 100


    // MARK: -

    private let storage: IdentityStorage
    private let endpoint: URL
    private let session: URLSession

    init(endpoint: URL, storage: IdentityStorage, session: URLSession) {
        self.endpoint = endpoint
        self.storage = storage
        self.session = session

        unarchive()
    }


    // MARK: -

    private var queue: [Entry] = []

    struct Entry {
        let identifier: String
        let type: String
        let date: Date
        let parameters: [String: Any]
    }

    func collect(identifier: String, event: Event) {
        let entry = Entry(identifier: identifier, type: event.type, date: Date(), parameters: event.parameters)
        print("enty \(entry)")
        queue.append(entry)

        if queue.count > foolproof {
            queue.removeFirst(queue.count - foolproof - 1)
            queue.append(Entry(identifier: "stats", type: "fool-proof", date: Date(), parameters: [:]))
        }

        print("collector | got \(queue.count) events")

        if queue.count > limit {
            flush()
        }

        archive()
    }

    func flush() {
        guard !queue.isEmpty else { return }

        let objects = queue
        queue = []

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.httpBody = encode(entries: objects)
        request.setValue(identity, forHTTPHeaderField: "tracking-identity")

        let task = session.dataTask(with: request) { _, _, error in
            if error != nil {
                print("collector | flush error")

                DispatchQueue.main.async {
                    self.queue.append(contentsOf: objects)
                }
            } else {
                print("collector | flush ok")
            }
        }

        task.resume()
    }

    func archive() {
        guard let url = filepath() else { return }

        if let data = encode(entries: queue), (try? data.write(to: url)) != nil {
//            print("collector | archive ok")
        } else {
//            print("collector | archive error")
        }
    }

    func unarchive() {
        guard let url = filepath() else { return }

        if let data = try? Data(contentsOf: url), let result = decode(data: data) {
            queue = result
//            print("collector | unarchive ok")
        } else {
//            print("collector | archive error")
        }
    }

    func clean() {
        guard let url = filepath() else { return }

        do {
            let manager = FileManager.default
            try manager.removeItem(at: url)
//            print("collector | clean ok")
        } catch {
//            print("collector | clean error \(error)")
        }
    }


    // MARK: -

    func encode(entries: [Entry]) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        return try? encoder.encode(entries)
    }

    func decode(data: Data) -> [Entry]? {
        return try? JSONDecoder().decode([Entry].self, from: data)
    }


    // MARK: -

    lazy var identity: String = {
        if let id = storage.get() {
            return id
        }

        let id = generate()
        storage.set(id)
        return id

    }()


    // MARK: - Helpers

    private func generate() -> String {
        return UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "-")
    }

    private func filepath() -> URL? {
        let manager = FileManager.default
        let docs = try? manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return docs?.appendingPathComponent("events.log")
    }

}



extension Collector.Entry: Codable {

    private enum Keys: String, CodingKey {
        case identifier = "i"
        case type = "t"
        case date = "d"
        case parameters = "p"
    }

    private struct Custom: CodingKey {
        var stringValue: String
        var intValue: Int?

        init(stringValue: String) {
            self.stringValue = stringValue
        }
        init?(intValue: Int) {
            return nil
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)

        identifier = try container.decode(String.self, forKey: .identifier)
        type = try container.decode(String.self, forKey: .type)
        date = try container.decode(Date.self, forKey: .date)

        let subcontainer = try container.nestedContainer(keyedBy: Custom.self, forKey: .parameters)

        var result: [String: Any] = [:]

        for key in subcontainer.allKeys {
            if let string = try? subcontainer.decode(String.self, forKey: key) {
                result[key.stringValue] = string
            } else if let int = try? subcontainer.decode(Int.self, forKey: key) {
                result[key.stringValue] = int
            } else {
                print("not decodable \(key)")
            }
        }

        parameters = result
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)

        try container.encode(identifier, forKey: .identifier)
        try container.encode(type, forKey: .type)
        try container.encode(date, forKey: .date)

        guard !parameters.isEmpty else { return }


        var subcontainer = container.superEncoder(forKey: .parameters).container(keyedBy: Custom.self)

        for (key, value) in self.parameters {
            if let string = value as? String {
                try subcontainer.encode(string, forKey: Custom(stringValue: key))
            } else if let int = value as? Int {
                try subcontainer.encode(int, forKey: Custom(stringValue: key))
            } else {
                print("not encodable \(key) -> \(value)")
            }
        }
    }

}
